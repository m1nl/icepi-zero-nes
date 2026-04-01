#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <system.h>

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

#include <generated/csr.h>
#include <irq.h>
#include <libfatfs/ff.h>
#include <liblitesdcard/spisdcard.h>

#include "nes_loader.h"
#include "rom_rotator.h"

#define ROM_NAME_MAX 64
#define ROM_DIR "/roms"
#define ROM_EXT ".nes"

static char **rom_list = NULL;
static int rom_count = 0;
static int rom_current = -1;
static FATFS rot_fs;
static int fs_mounted = 0;

static int scan_roms(void) {
    DIR dir;
    FILINFO fno;
    FRESULT res;

    res = f_mount(&rot_fs, "", 1);
    if (res != FR_OK) {
        printf("rom_rotator: mount failed (%d)\n", res);
        return -1;
    }
    fs_mounted = 1;

    res = f_opendir(&dir, ROM_DIR);
    if (res != FR_OK) {
        printf("rom_rotator: opendir failed (%d)\n", res);
        f_unmount("");
        fs_mounted = 0;
        return -1;
    }

    rom_count = 0;
    int capacity = 16;
    free(rom_list);
    rom_list = malloc(capacity * sizeof(char *));
    if (!rom_list) {
        printf("rom_rotator: alloc failed\n");
        f_closedir(&dir);
        f_unmount("");
        fs_mounted = 0;
        return -1;
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

    if (!fs_mounted) {
        f_unmount("");
        fs_mounted = 0;
    }

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
    return rom_count;
}

static void load_current(void) {
    if (rom_count == 0) {
        printf("rom_rotator: no ROMs found\n");
        return;
    }

    size_t plen = strlen(ROM_DIR) + 1 + strlen(rom_list[rom_current]) + 1;
    char *path = malloc(plen);
    if (!path) {
        printf("rom_rotator: alloc failed\n");
        return;
    }
    size_t rom_dir_len = strlen(ROM_DIR);
    memset(path, 0, plen);
    memcpy(path, ROM_DIR, rom_dir_len);
    path[rom_dir_len] = '/';
    memcpy(path + rom_dir_len + 1, rom_list[rom_current], strlen(rom_list[rom_current]));
    printf("rom_rotator: loading [%d/%d] %s\n", rom_current + 1, rom_count, path);
    nes_loader_cmd(path);
    free(path);
}

#define EV_NEXT_ROM     (1 << 0)
#define EV_PREVIOUS_ROM (1 << 1)
#define EV_RESET_ROM    (1 << 2)

void rom_rotator_next_rom_isr(void) {
    nes_control_ev_pending_write(EV_NEXT_ROM);

    if (rom_count == 0)
        return;

    rom_current = (rom_current + 1) % rom_count;
    load_current();
}

void rom_rotator_previous_rom_isr(void) {
    nes_control_ev_pending_write(EV_PREVIOUS_ROM);

    if (rom_count == 0)
        return;

    rom_current = (rom_current - 1 + rom_count) % rom_count;
    load_current();
}

void rom_rotator_reset_rom_isr(void) {
    nes_control_ev_pending_write(EV_RESET_ROM);

    nes_control_nes_reset_write(1);
    busy_wait_us(100);
    load_current();
}

void rom_rotator_isr(void) {
    uint32_t pending = nes_control_ev_pending_read();
    nes_control_ev_pending_write(pending);

    if (rom_count == 0)
        return;

    if (pending & EV_NEXT_ROM) {
        rom_current = (rom_current + 1) % rom_count;
        load_current();
    } else if (pending & EV_PREVIOUS_ROM) {
        rom_current = (rom_current - 1 + rom_count) % rom_count;
        load_current();
    } else if (pending & EV_RESET_ROM) {
        nes_control_nes_reset_write(1);
        busy_wait_us(100);
        load_current();
    }
}

void rom_rotator_init(void) {
    if (scan_roms() <= 0)
        return;

    rom_current = 0;
    load_current();

    nes_control_ev_enable_write(EV_NEXT_ROM | EV_PREVIOUS_ROM | EV_RESET_ROM);
}
