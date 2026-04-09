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

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <system.h>

#include <generated/csr.h>
#include <irq.h>

#include "ff.h"
#include "spisdcard.h"

#include "nes_loader.h"
#include "rom_rotator.h"

#define ROM_NAME_MAX 128
#define ROM_DIR "/roms"
#define ROM_EXT ".nes"
#define SAVE_DIR "/saves"
#define SAVE_EXT ".srm"

static char **rom_list = NULL;
static int rom_count = 0;
static int rom_current = -1;
static int rom_next = -1;
static FATFS fs;

static int str_icmp(const char *a, const char *b) {
    while (*a && *b) {
        int d = tolower((unsigned char)*a) - tolower((unsigned char)*b);
        if (d)
            return d;
        a++;
        b++;
    }
    return tolower((unsigned char)*a) - tolower((unsigned char)*b);
}

static int scan_roms(void) {
    DIR dir;
    FILINFO fno;
    FRESULT res;

    rom_count = -1;

    int mounted = 0;

    res = f_mount(&fs, "", 1);
    if (res != FR_OK) {
        printf("rom_rotator: mount failed (%d)\n", res);
        goto exit;
    }

    mounted = 1;

    if (f_stat(SAVE_DIR, &fno) != FR_OK) {
        res = f_mkdir(SAVE_DIR);
        if (res != FR_OK) {
            printf("rom_rotator: mkdir failed (%d)\n", res);
            goto exit;
        }
    }

    res = f_opendir(&dir, ROM_DIR);
    if (res != FR_OK) {
        printf("rom_rotator: opendir failed (%d)\n", res);
        goto exit;
    }

    rom_count = 0;
    int capacity = 16;
    free(rom_list);
    rom_list = malloc(capacity * sizeof(char *));
    if (!rom_list) {
        printf("rom_rotator: alloc failed\n");
        f_closedir(&dir);
        goto exit;
    }

    for (;;) {
        res = f_readdir(&dir, &fno);
        if (res != FR_OK || fno.fname[0] == '\0')
            break;
        if (fno.fattrib & AM_DIR)
            continue;

        size_t len = strlen(fno.fname);
        if (len < 4)
            continue;
        if (str_icmp(fno.fname + len - 4, ROM_EXT) != 0)
            continue;

        if (rom_count >= capacity) {
            capacity *= 2;
            char **tmp = realloc(rom_list, capacity * sizeof(char *));
            if (!tmp) {
                printf("rom_rotator: realloc failed\n");
                break;
            }
            rom_list = tmp;
        }

        rom_list[rom_count] = malloc(len + 1);
        if (!rom_list[rom_count])
            break;
        memcpy(rom_list[rom_count], fno.fname, len + 1);
        rom_count++;
    }
    f_closedir(&dir);

    /* insertion sort — alphabetical order */
    for (int i = 1; i < rom_count; i++) {
        char *tmp = rom_list[i];
        int j = i - 1;
        while (j >= 0 && str_icmp(rom_list[j], tmp) > 0) {
            rom_list[j + 1] = rom_list[j];
            j--;
        }
        rom_list[j + 1] = tmp;
    }

    printf("rom_rotator: found %d ROM(s)\n", rom_count);

exit:
    if (mounted) {
        f_unmount("");
    }

    return rom_count;
}

static void save_current(void) {
    if (rom_current < 0 || rom_count <= 0)
        return;

    uint64_t mapper_flags = nes_control_mapper_flags_read();

    uint8_t has_saves = (uint8_t)((mapper_flags >> 25) & 0x1);

    if (!has_saves)
        return;

    if (prg_nvram_size(mapper_flags) == 0)
        return;

    const char *name = rom_list[rom_current];
    size_t nlen = strlen(name);
    size_t stem_len = (nlen >= 4) ? nlen - 4 : nlen;

    char spath[ROM_NAME_MAX];
    size_t save_dir_len = strlen(SAVE_DIR);
    memset(spath, 0, ROM_NAME_MAX);
    memcpy(spath, SAVE_DIR, save_dir_len);
    spath[save_dir_len] = '/';
    memcpy(spath + save_dir_len + 1, name, stem_len);
    memcpy(spath + save_dir_len + 1 + stem_len, SAVE_EXT, strlen(SAVE_EXT));

    printf("rom_rotator: saving save [%d/%d] as %s\n", rom_current + 1, rom_count, spath);

    nes_save(spath);
}

static void load_current(void) {
    FRESULT res;

    if (rom_count <= 0) {
        printf("rom_rotator: no ROMs found\n");
        return;
    }

    const char *name = rom_list[rom_current];
    size_t nlen = strlen(name);
    size_t stem_len = (nlen >= 4) ? nlen - 4 : nlen;

    char path[ROM_NAME_MAX];
    size_t rom_dir_len = strlen(ROM_DIR);
    memset(path, 0, ROM_NAME_MAX);
    memcpy(path, ROM_DIR, rom_dir_len);
    path[rom_dir_len] = '/';
    memcpy(path + rom_dir_len + 1, name, nlen);

    char spath[ROM_NAME_MAX];
    size_t save_dir_len = strlen(SAVE_DIR);
    memset(spath, 0, ROM_NAME_MAX);
    memcpy(spath, SAVE_DIR, save_dir_len);
    spath[save_dir_len] = '/';
    memcpy(spath + save_dir_len + 1, name, stem_len);
    memcpy(spath + save_dir_len + 1 + stem_len, SAVE_EXT, strlen(SAVE_EXT));

    res = f_mount(&fs, "", 1);
    if (res != FR_OK) {
        printf("rom_rotator: mount failed (%d)\n", res);
        return;
    }

    res = f_stat(spath, NULL);

    f_unmount("");

    if (res == FR_OK) {
        printf("rom_rotator: loading [%d/%d] %s and save %s\n", rom_current + 1, rom_count, path, spath);
        nes_load_with_save(path, spath);
    } else {
        printf("rom_rotator: loading [%d/%d] %s\n", rom_current + 1, rom_count, path);
        nes_load_without_save(path);
    }
}

#define EV_NEXT_ROM (1 << 0)
#define EV_PREVIOUS_ROM (1 << 1)
#define EV_RESET_ROM (1 << 2)

static void rom_rotator_isr(void) {
    uint32_t pending = nes_control_ev_pending_read();
    nes_control_ev_pending_write(pending);

    if (rom_count <= 0) {
        return;
    }

    if (rom_current == -1) {
        rom_next = 0;
        return;
    }

    if (pending & EV_NEXT_ROM) {
        rom_next = (rom_current + 1) % rom_count;
    } else if (pending & EV_PREVIOUS_ROM) {
        rom_next = (rom_current - 1 + rom_count) % rom_count;
    } else if (pending & EV_RESET_ROM) {
        rom_next = -1;
    }
}

void rom_rotator_discard(void) {
    rom_current = -1;
    rom_next = -1;
}

void rom_rotator_init(void) {
    if (scan_roms() <= 0)
        return;

    irq_attach(NES_CONTROL_INTERRUPT, rom_rotator_isr);
    irq_setmask(irq_getmask() | (1 << NES_CONTROL_INTERRUPT));

    rom_current = -1;
    rom_next = 0;

    nes_control_ev_enable_write(EV_NEXT_ROM | EV_PREVIOUS_ROM | EV_RESET_ROM);
}

void rom_rotator_service(void) {
    if (rom_count <= 0)
        return;

    if (rom_next != rom_current) {
        fputc('\n', stdout);

        if (rom_current != -1)
            save_current();

        if (rom_next == -1)
            rom_next = rom_current;

        rom_current = rom_next;
        load_current();
    }
}
