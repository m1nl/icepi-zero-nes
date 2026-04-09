// ---------------------------------------------------------------------------
// Copyright 2026 Mateusz Nalewajski
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: GPL-3.0-or-later
// ---------------------------------------------------------------------------

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <generated/csr.h>
#include <generated/mem.h>
#include <irq.h>
#include <system.h>

#include "ff.h"
#include "spisdcard.h"

#include "nes_loader.h"

#define INES_MAGIC_0 0x4E /* 'N' */
#define INES_MAGIC_1 0x45 /* 'E' */
#define INES_MAGIC_2 0x53 /* 'S' */
#define INES_MAGIC_3 0x1A

#define PRG_ROM_BASE (MAIN_RAM_BASE + 0x0000000U)
#define INT_RAM_BASE (MAIN_RAM_BASE + 0x0E00000U)
#define PRG_RAM_BASE (MAIN_RAM_BASE + 0x0F00000U)
#define CHR_ROM_BASE (MAIN_RAM_BASE + 0x0800400U)

#define PRG_PAGE_SIZE 16384
#define CHR_PAGE_SIZE 8192

#define INT_RAM_SIZE 2048
#define PRG_RAM_SIZE 32768

static FATFS fs;
static uint8_t buf[512];

static volatile uint8_t mutex;

typedef struct {
    uint8_t magic[4];
    uint8_t prg_pages; /* 16 KB units */
    uint8_t chr_pages; /* 8  KB units */
    uint8_t flags6;
    uint8_t flags7;
    uint8_t flags8;  /* NES 2.0: mapper MSB / PRG-RAM */
    uint8_t flags9;  /* NES 2.0: PRG/CHR size MSB */
    uint8_t flags10; /* NES 2.0: PRG-RAM / NVRAM sizes */
    uint8_t flags11; /* NES 2.0: CHR-RAM size */
    uint8_t flags12; /* NES 2.0: timing */
    uint8_t flags13; /* NES 2.0: vs/extended */
    uint8_t flags14; /* NES 2.0: misc ROMs */
    uint8_t flags15; /* NES 2.0: default expansion */
} ines_header_t;

static int is_nes20(const ines_header_t *h) { return ((h->flags7 & 0x0C) == 0x08); }

static int is_dirty(const ines_header_t *h) {
    if (is_nes20(h))
        return 0;
    return ((h->flags9 >> 1) || h->flags10 || h->flags11 || h->flags12 || h->flags13 || h->flags14 || h->flags15);
}

static uint64_t compute_mapper_flags(const ines_header_t *h) {
    uint8_t chrrom = h->chr_pages;
    uint8_t prgrom = h->prg_pages;
    int nes20 = is_nes20(h);
    int dirty = is_dirty(h);

    uint8_t mapper_lo = (h->flags6 >> 4);
    uint8_t mapper_hi = dirty ? 0 : (h->flags7 >> 4);
    uint8_t mapper = (mapper_hi << 4) | mapper_lo;
    uint8_t ines2mapper = nes20 ? h->flags8 : 0x00;

    uint8_t chrram_shift = h->flags11 & 0x0F;
    int has_chr_ram = nes20 ? (chrram_shift != 0) : (chrrom == 0);

    int has_saves = (h->flags6 >> 1) & 1;
    int piano = nes20 && ((h->flags15 & 0x3F) == 0x19);

    uint8_t prgram = nes20 ? (h->flags10 & 0x0F) : 0;
    uint8_t prg_nvram = nes20 ? ((h->flags10 >> 4) & 0x0F) : (has_saves ? 9 : 0); // assume 32KiB NVRAM for iNES 1.0
    uint8_t timing = nes20 ? (h->flags12 & 0x03) : 0;

    /* prg_size 3-bit encoding (same as game_loader.v) */
    uint8_t prg_size = prgrom <= 1    ? 0
                       : prgrom <= 2  ? 1
                       : prgrom <= 4  ? 2
                       : prgrom <= 8  ? 3
                       : prgrom <= 16 ? 4
                       : prgrom <= 32 ? 5
                       : prgrom <= 64 ? 6
                                      : 7;

    /* chr_size 3-bit encoding */
    uint8_t chr_size = chrrom <= 1    ? 0
                       : chrrom <= 2  ? 1
                       : chrrom <= 4  ? 2
                       : chrrom <= 8  ? 3
                       : chrrom <= 16 ? 4
                       : chrrom <= 32 ? 5
                       : chrrom <= 64 ? 6
                                      : 7;

    uint64_t flags = 0;
    flags |= (uint64_t)mapper;                       /* [7:0]   */
    flags |= (uint64_t)prg_size << 8;                /* [10:8]  */
    flags |= (uint64_t)chr_size << 11;               /* [13:11] */
    flags |= (uint64_t)(h->flags6 & 1) << 14;        /* [14]    mirroring */
    flags |= (uint64_t)has_chr_ram << 15;            /* [15]    */
    flags |= (uint64_t)((h->flags6 >> 3) & 1) << 16; /* [16]    4-screen */
    flags |= (uint64_t)ines2mapper << 17;            /* [24:17] NES2 submapper (byte) */
    flags |= (uint64_t)has_saves << 25;              /* [25]    */
    flags |= (uint64_t)prgram << 26;                 /* [29:26] PRG-RAM shift */
    flags |= (uint64_t)piano << 30;                  /* [30]    */
    flags |= (uint64_t)prg_nvram << 31;              /* [34:31] Save-RAM shift */
    flags |= (uint64_t)nes20 << 35;                  /* [35]    */
    flags |= (uint64_t)timing << 36;                 /* [37:36] */
    /* [63:38] = 0 */
    return flags;
}

static int lock(void) {
    int saved_ie = irq_getie();

    irq_setie(0);

    if (mutex) {
        irq_setie(saved_ie);
        return 0;
    }

    mutex = 1;
    irq_setie(saved_ie);

    return 1;
}

static void unlock(void) { mutex = 0; }

static void clear_ram(uint8_t *p, uint32_t remaining) {
    while (remaining > 0) {
        uintptr_t addr = (uintptr_t)p;
        if ((addr & 0xc00) != 0) {
            addr += 0x1000;
            addr &= ~0xc00;
        }
        p = (uint8_t *)addr;
        memset(p, 0x00, 0x400);
        p += 0x1000;
        remaining -= 0x400;
    }
}

uint32_t prg_nvram_size(uint64_t mapper_flags) {
    uint8_t shift = (uint8_t)((mapper_flags >> 31) & 0xF);
    if (shift == 0)
        return 0;
    return (uint32_t)64 << shift;
}

static int nes_load(const char *path, const char *save_path) {
    FIL nes;
    FRESULT res;
    UINT br;
    ines_header_t hdr;

    int ret = -1;
    int mounted = 0;

    if (!lock()) {
        printf("nes_load: unable to acquire lock\n");
        return -1;
    }

    res = f_mount(&fs, "", 1);
    if (res != FR_OK) {
        printf("nes_load: sdcard mount failed (err %d)\n", res);
        goto exit;
    }

    mounted = 1;

    res = f_open(&nes, path, FA_READ);
    if (res != FR_OK) {
        printf("nes_load: cannot open '%s' (err %d)\n", path, res);
        goto exit;
    }

    res = f_read(&nes, &hdr, sizeof(hdr), &br);
    if (res != FR_OK || br != sizeof(hdr)) {
        printf("nes_load: header read failed\n");
        f_close(&nes);
        goto exit;
    }

    if (hdr.magic[0] != INES_MAGIC_0 || hdr.magic[1] != INES_MAGIC_1 || hdr.magic[2] != INES_MAGIC_2 ||
        hdr.magic[3] != INES_MAGIC_3) {
        printf("nes_load: not an iNES file\n");
        f_close(&nes);
        goto exit;
    }

    if (hdr.flags6 & 0x04) {
        printf("nes_load: trainer present, not supported\n");
        f_close(&nes);
        goto exit;
    }

    nes_control_nes_reset_write(1);
    busy_wait_us(1000);

    uint32_t prg_bytes;
    if (is_nes20(&hdr) && ((hdr.flags9 & 0x0F) == 0x0F)) {
        /* NES 2.0 exponent-multiplier encoding */
        uint8_t exp = hdr.prg_pages >> 2;
        uint8_t mul = hdr.prg_pages & 0x03;
        prg_bytes = (uint32_t)(1 << exp) * (mul * 2 + 1);
    } else {
        prg_bytes = (uint32_t)hdr.prg_pages * PRG_PAGE_SIZE;
    }

    printf("nes_load: PRG %lu bytes -> 0x%08lx\n", (unsigned long)prg_bytes, (unsigned long)PRG_ROM_BASE);

    uint8_t *dst = (uint8_t *)PRG_ROM_BASE;
    uint32_t remaining = prg_bytes;

    while (remaining > 0) {
        UINT chunk = remaining < sizeof(buf) ? remaining : sizeof(buf);
        res = f_read(&nes, buf, chunk, &br);
        if (res != FR_OK || br == 0) {
            printf("nes_load: read error after %lu bytes\n", (unsigned long)(prg_bytes - remaining));
            f_close(&nes);
            goto exit;
        }
        uintptr_t addr = (uintptr_t)dst;
        if ((addr & 0xc00) != 0) {
            addr += 0x1000;
            addr &= ~0xc00;
        }
        dst = (uint8_t *)addr;
        memcpy(dst, buf, br);
        dst += br;
        remaining -= br;
    }

    uint32_t chr_bytes = (uint32_t)hdr.chr_pages * CHR_PAGE_SIZE;

    if (chr_bytes > 0) {
        printf("nes_load: CHR %lu bytes -> 0x%08lx\n", (unsigned long)chr_bytes, (unsigned long)CHR_ROM_BASE);

        dst = (uint8_t *)CHR_ROM_BASE;
        remaining = chr_bytes;

        while (remaining > 0) {
            UINT chunk = remaining < sizeof(buf) ? remaining : sizeof(buf);
            res = f_read(&nes, buf, chunk, &br);
            if (res != FR_OK || br == 0) {
                printf("nes_load: CHR read error after %lu bytes\n", (unsigned long)(chr_bytes - remaining));
                f_close(&nes);
                goto exit;
            }
            uintptr_t addr = (uintptr_t)dst;
            if ((addr & 0xc00) != 0x400) {
                addr += 0x1000;
                addr &= ~0xc00;
                addr |= 0x400;
            }
            dst = (uint8_t *)addr;
            memcpy(dst, buf, br);
            dst += br;
            remaining -= br;
        }

    } else {
        clear_ram((uint8_t *)CHR_ROM_BASE, CHR_PAGE_SIZE);
        printf("nes_load: cleared %u bytes at 0x%08lx (CHR ROM / RAM)\n", CHR_PAGE_SIZE, (unsigned long)CHR_ROM_BASE);
    }

    f_close(&nes);

    const uint64_t flags = compute_mapper_flags(&hdr);

    uint8_t mapper = (uint8_t)(flags & 0xFF);
    uint8_t has_saves = (uint8_t)(flags >> 25) & 0x1;
    uint32_t save_bytes = prg_nvram_size(flags);

    clear_ram((uint8_t *)INT_RAM_BASE, INT_RAM_SIZE);
    printf("nes_load: cleared %u bytes at 0x%08lx (internal RAM)\n", INT_RAM_SIZE, (unsigned long)INT_RAM_BASE);

    clear_ram((uint8_t *)PRG_RAM_BASE, PRG_RAM_SIZE);
    printf("nes_load: cleared %u bytes at 0x%08lx (PRG RAM)\n", PRG_RAM_SIZE, (unsigned long)PRG_RAM_BASE);

    if (save_path != NULL && has_saves && save_bytes > 0) {
        res = f_open(&nes, save_path, FA_READ);

        if (res == FR_OK) {
            printf("nes_load: loading save '%s' (%lu bytes)\n", save_path, (unsigned long)save_bytes);
            uint8_t *sdst = (uint8_t *)PRG_RAM_BASE;
            uint32_t srem = save_bytes;
            while (srem > 0) {
                UINT schunk = srem < sizeof(buf) ? srem : sizeof(buf);
                UINT sbr;
                res = f_read(&nes, buf, schunk, &sbr);
                if (res != FR_OK || sbr == 0)
                    break;
                uintptr_t saddr = (uintptr_t)sdst;
                if ((saddr & 0xc00) != 0) {
                    saddr += 0x1000;
                    saddr &= ~0xc00;
                }
                sdst = (uint8_t *)saddr;
                memcpy(sdst, buf, sbr);
                sdst += sbr;
                srem -= sbr;
            }
            f_close(&nes);
        } else {
            printf("nes_load: unable to open save file %s, ignoring\n", save_path);
        }
    }

    nes_control_mapper_flags_write(flags);

    flush_cpu_dcache();
    flush_l2_cache();

    printf("nes_load: done, mapper_flags=0x%016llx\n", (unsigned long long)flags);
    printf("  mapper=%u has_saves=%u save_bytes=%lu prg_pages=%u chr_pages=%u\n", mapper, has_saves, save_bytes,
           hdr.prg_pages, hdr.chr_pages);
    ret = 0;

exit:
    if (mounted) {
        f_unmount("");
    }

    busy_wait_us(10000);

    if (ret == 0) {
        nes_control_nes_reset_write(0);
    }

    unlock();

    return ret;
}

int nes_load_without_save(const char *path) { return nes_load(path, NULL); }

int nes_load_with_save(const char *path, const char *save_path) { return nes_load(path, save_path); }

int nes_save(const char *save_path) {
    FRESULT res;
    FIL sav;

    int mounted = 0;
    int ret = -1;

    if (!lock()) {
        printf("nes_save: unable to acquire lock\n");
        return -1;
    }

    res = f_mount(&fs, "", 1);
    if (res != FR_OK) {
        printf("nes_save: sdcard mount failed (err %d)\n", res);
        goto exit;
    }

    mounted = 1;

    uint64_t mapper_flags = nes_control_mapper_flags_read();

    uint8_t has_saves = (uint8_t)((mapper_flags >> 25) & 0x1);
    if (!has_saves) {
        printf("nes_save: current ROM does not have save flags enabled\n");
        goto exit;
    }

    uint32_t save_bytes = prg_nvram_size(mapper_flags);
    if (save_bytes == 0) {
        printf("nes_save: current ROM has NVRAM size set to 0\n");
        goto exit;
    }

    printf("nes_save: about to save %lu bytes to '%s'\n", (unsigned long)save_bytes, save_path);

    res = f_open(&sav, save_path, FA_WRITE | FA_CREATE_ALWAYS);
    if (res != FR_OK) {
        printf("nes_save: cannot open '%s' (err %d)\n", save_path, res);
        goto exit;
    }

    nes_control_nes_pause_write(1);
    busy_wait_us(1000);

    printf("nes_save: saving %lu bytes to '%s'\n", (unsigned long)save_bytes, save_path);

    const uint8_t *src = (const uint8_t *)PRG_RAM_BASE;
    uint32_t remaining = save_bytes;

    while (remaining > 0) {
        uintptr_t saddr = (uintptr_t)src;
        if ((saddr & 0xc00) != 0) {
            saddr += 0x1000;
            saddr &= ~0xc00;
        }
        src = (const uint8_t *)saddr;
        UINT chunk = remaining < sizeof(buf) ? remaining : sizeof(buf);
        memcpy(buf, src, chunk);
        UINT bw;
        res = f_write(&sav, buf, chunk, &bw);
        if (res != FR_OK || bw != chunk) {
            printf("nes_save: write error\n");
            f_close(&sav);
            goto exit;
        }
        src += chunk;
        remaining -= chunk;
    }

    f_close(&sav);
    printf("nes_save: done\n");
    ret = 0;

exit:
    if (mounted) {
        f_unmount("");
    }

    nes_control_nes_pause_write(0);
    unlock();

    return ret;
}

int sdcard_ls(const char *path) {
    FRESULT res;
    DIR dir;
    FILINFO fno;

    int mounted = 0;
    int ret = -1;

    res = f_mount(&fs, "", 1);
    if (res != FR_OK) {
        printf("sdcard_ls: sdcard mount failed (err %d)\n", res);
        goto exit;
    }

    mounted = 1;

    const char *dirpath = (*path == '\0') ? "/" : path;
    res = f_opendir(&dir, dirpath);
    if (res != FR_OK) {
        printf("sdcard_ls: cannot open '%s' (err %d)\n", dirpath, res);
        goto exit;
    }

    printf("Contents of %s:\n", dirpath);
    for (;;) {
        res = f_readdir(&dir, &fno);
        if (res != FR_OK || fno.fname[0] == '\0')
            break;
        if (fno.fattrib & AM_DIR)
            printf("  [DIR]  %s\n", fno.fname);
        else
            printf("  %8lu  %s\n", (unsigned long)fno.fsize, fno.fname);
    }

    f_closedir(&dir);
    ret = 0;

exit:
    if (mounted) {
        f_unmount("");
    }

    return ret;
}
