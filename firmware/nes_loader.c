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

#include "nes_loader.h"
#include <generated/csr.h>
#include <generated/mem.h>
#include <libfatfs/ff.h>
#include <liblitesdcard/sdcard.h>
#include <system.h>

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

    uint8_t prgram = nes20 ? (h->flags10 & 0x0F) : 0;
    uint8_t prg_nvram = nes20 ? ((h->flags10 >> 4) & 0x0F) : 0;
    int has_saves = (h->flags6 >> 1) & 1;
    int piano = nes20 && ((h->flags15 & 0x3F) == 0x19);
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

static void clear_ram(uint8_t* p, uint32_t remaining) {
    while (remaining > 0) {
        memset(p, 0x00, 0x400);
        p += 0x400;
        remaining -= 0x400;
    }
}

static int nes_load(const char *path, const char *save_path, uint64_t *mapper_flags_out) {
    FIL nes;
    FRESULT res;
    UINT br;
    ines_header_t hdr;

    res = f_open(&nes, path, FA_READ);
    if (res != FR_OK) {
        printf("nes_load: cannot open '%s' (err %d)\n", path, res);
        return -1;
    }

    res = f_read(&nes, &hdr, sizeof(hdr), &br);
    if (res != FR_OK || br != sizeof(hdr)) {
        printf("nes_load: header read failed\n");
        f_close(&nes);
        return -1;
    }

    if (hdr.magic[0] != INES_MAGIC_0 || hdr.magic[1] != INES_MAGIC_1 || hdr.magic[2] != INES_MAGIC_2 ||
        hdr.magic[3] != INES_MAGIC_3) {
        printf("nes_load: not an iNES file\n");
        f_close(&nes);
        return -1;
    }

    if (hdr.flags6 & 0x04) {
        printf("nes_load: trainer present, not supported\n");
        f_close(&nes);
        return -1;
    }

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
    uint8_t buf[512];

    while (remaining > 0) {
        UINT chunk = remaining < sizeof(buf) ? remaining : sizeof(buf);
        res = f_read(&nes, buf, chunk, &br);
        if (res != FR_OK || br == 0) {
            printf("nes_load: read error after %lu bytes\n", (unsigned long)(prg_bytes - remaining));
            f_close(&nes);
            return -1;
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
                return -1;
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

    uint64_t flags = compute_mapper_flags(&hdr);
    if (mapper_flags_out)
        *mapper_flags_out = flags;

    uint8_t mapper = (uint8_t)(flags & 0xFF);
    uint8_t has_saves = (uint8_t)(flags >> 25) & 0x1;

    clear_ram((uint8_t *)INT_RAM_BASE, INT_RAM_SIZE);
    printf("nes_load: cleared %u bytes at 0x%08lx (internal RAM)\n", INT_RAM_SIZE, (unsigned long)INT_RAM_BASE);

    clear_ram((uint8_t *)PRG_RAM_BASE, PRG_RAM_SIZE);
    printf("nes_load: cleared %u bytes at 0x%08lx (PRG RAM)\n", PRG_RAM_SIZE, (unsigned long)PRG_RAM_BASE);

    flush_cpu_dcache();
    flush_l2_cache();

    printf("nes_load: done, mapper_flags=0x%016llx\n", (unsigned long long)flags);
    printf("  mapper=%u has_saves=%u prg_pages=%u chr_pages=%u\n", mapper, has_saves, hdr.prg_pages, hdr.chr_pages);

    return 0;
}

void nes_loader_cmd(const char *path) {
    FRESULT res;
    uint64_t mapper_flags = 0;

    nes_control_nes_reset_write(1);

    res = f_mount(&fs, "", 1);
    if (res != FR_OK) {
        printf("sdcard mount failed (err %d)\n", res);
        nes_control_nes_reset_write(0);
        return;
    }

    if (nes_load(path, NULL, &mapper_flags) == 0) {
        nes_control_mapper_flags_write(mapper_flags);
        printf("mapper_flags written: 0x%016llx\n", (unsigned long long)mapper_flags);
        uint64_t rb = nes_control_mapper_flags_read();
        printf("mapper_flags readback: 0x%016llx\n", (unsigned long long)rb);
        printf("  prg_size=[10:8]=0x%lx chr_size=[13:11]=0x%lx\n", (unsigned long)((mapper_flags >> 8) & 0x7),
               (unsigned long)((mapper_flags >> 11) & 0x7));
    }

    f_unmount("");

    busy_wait_us(10000);
    nes_control_nes_reset_write(0);
}

void sdcard_ls_cmd(const char *path) {
    FRESULT res;
    DIR dir;
    FILINFO fno;

    res = f_mount(&fs, "", 1);
    if (res != FR_OK) {
        printf("sdcard mount failed (err %d)\n", res);
        return;
    }

    const char *dirpath = (*path == '\0') ? "/" : path;
    res = f_opendir(&dir, dirpath);
    if (res != FR_OK) {
        printf("ls: cannot open '%s' (err %d)\n", dirpath, res);
        f_unmount("");
        return;
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
    f_unmount("");
}
