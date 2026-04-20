// This file is Copyright (c) 2020 Florent Kermarrec <florent@enjoy-digital.fr>
// License: BSD

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <generated/csr.h>
#include <generated/mem.h>
#include <irq.h>
#include <libbase/console.h>
#include <libbase/uart.h>

#include "heap.h"
#include "spisdcard.h"

#include "nes_loader.h"
#include "rom_rotator.h"
#include "power.h"

/*-----------------------------------------------------------------------*/
/* Uart                                                                  */
/*-----------------------------------------------------------------------*/

static char *readstr(void) {
    char c[2];
    static char s[128];
    static int ptr = 0;

    if (readchar_nonblock()) {
        c[0] = getchar();
        c[1] = 0;
        switch (c[0]) {
            case 0x7f:
            case 0x08:
                if (ptr > 0) {
                    ptr--;
                    fputs("\x08 \x08", stdout);
                }
                break;
            case 0x07:
                break;
            case '\r':
            case '\n':
                s[ptr] = 0x00;
                fputs("\n", stdout);
                ptr = 0;
                return s;
            default:
                if (ptr >= (sizeof(s) - 1))
                    break;
                fputs(c, stdout);
                s[ptr] = c[0];
                ptr++;
                break;
        }
    }

    return NULL;
}

static char *get_token(char **str) {
    char *c, *d;

    c = (char *)strchr(*str, ' ');
    if (c == NULL) {
        d = *str;
        *str = *str + strlen(*str);
        return d;
    }
    *c = 0;
    d = *str;
    *str = c + 1;
    return d;
}

static void prompt(void) { printf("\e[92;1micepi-nes\e[0m> "); }

/*-----------------------------------------------------------------------*/
/* Help                                                                  */
/*-----------------------------------------------------------------------*/

static void help(void) {
    puts("\nIcepi Zero NES built "__DATE__
         " "__TIME__
         "\n");
    puts("Available commands:");
    puts("help                   - Show this command");
    puts("reboot                 - Reboot CPU");
    puts("sdcard_reset           - Reset SD card");
    puts("ls [path]              - List SD card directory");
    puts("nes_load <path> [save] - Load NES ROM from SD card, optionally load save");
    puts("nes_save <path>        - Save NES battery-backed PRG RAM to SD card");
    puts("nes_pause              - Pause NES core");
    puts("nes_resume             - Resume NES core");
    puts("debug_mem              - Show last CPU/PPU SDRAM addresses");
    puts("hexdump <addr> [len]   - Hex dump memory (len default 256)");
    puts("power                  - Report INA219 power from UPS board");
}

/*-----------------------------------------------------------------------*/
/* Commands                                                              */
/*-----------------------------------------------------------------------*/

static void reboot_cmd(void) { ctrl_reset_write(1); }

static void nes_load_cmd(char *str) {
    if (*str == '\0') {
        printf("usage: nes_load <path> [save_path]\n");
        return;
    }

    rom_rotator_discard();

    char *path = get_token(&str);
    if (*str != '\0')
        nes_load_with_save(path, str);
    else
        nes_load_without_save(path);
}

static void nes_save_cmd(char *path) {
    if (*path == '\0') {
        printf("usage: nes_save <path>\n");
        return;
    }
    nes_save(path);
}

static void nes_pause_cmd(void) { nes_control_nes_pause_write(1); }

static void nes_resume_cmd(void) { nes_control_nes_pause_write(0); }

static void sdcard_reset_cmd(void) { spisdcard_init(); }

static void sdcard_ls_cmd(char *path) { sdcard_ls(path); }

static void hexdump_cmd(char *str) {
    if (*str == '\0') {
        printf("usage: hexdump <addr> [len]\n");
        return;
    }
    char *tok = get_token(&str);
    uint32_t addr = (uint32_t)strtoul(tok, NULL, 0);
    uint32_t len = 256;
    if (*str != '\0')
        len = (uint32_t)strtoul(get_token(&str), NULL, 0);

    const uint8_t *p = (const uint8_t *)addr;
    for (uint32_t i = 0; i < len; i += 16) {
        printf("%08lx  ", (unsigned long)(addr + i));
        for (uint32_t j = 0; j < 16; j++) {
            if (i + j < len)
                printf("%02x ", p[i + j]);
            else
                printf("   ");
            if (j == 7)
                printf(" ");
        }
        printf(" |");
        for (uint32_t j = 0; j < 16 && i + j < len; j++) {
            uint8_t c = p[i + j];
            printf("%c", (c >= 0x20 && c < 0x7f) ? c : '.');
        }
        printf("|\n");
    }
}

static void debug_mem_cmd(void) {
    uint32_t cpu_addr = nes_control_cpu_last_addr_read();
    uint32_t ppu_addr = nes_control_ppu_last_addr_read();

    uint8_t cpu_data = (uint8_t)nes_control_cpu_last_data_read();
    uint8_t ppu_data = (uint8_t)nes_control_ppu_last_data_read();

    printf("CPU last SDRAM addr: 0x%08lx (MAIN_RAM+0x%07lx) data: 0x%02x\n", (unsigned long)(MAIN_RAM_BASE + cpu_addr),
           (unsigned long)cpu_addr, cpu_data);
    printf("PPU last SDRAM addr: 0x%08lx (MAIN_RAM+0x%07lx) data: 0x%02x\n", (unsigned long)(MAIN_RAM_BASE + ppu_addr),
           (unsigned long)ppu_addr, ppu_data);
}

/*-----------------------------------------------------------------------*/
/* Console service / Main                                                */
/*-----------------------------------------------------------------------*/

static void console_service(void) {
    char *str;
    char *token;

    str = readstr();
    if (str == NULL)
        return;
    token = get_token(&str);
    if (strcmp(token, "help") == 0)
        help();
    else if (strcmp(token, "reboot") == 0)
        reboot_cmd();
    else if (strcmp(token, "sdcard_reset") == 0)
        sdcard_reset_cmd();
    else if (strcmp(token, "ls") == 0)
        sdcard_ls_cmd(str);
    else if (strcmp(token, "nes_load") == 0)
        nes_load_cmd(str);
    else if (strcmp(token, "nes_save") == 0)
        nes_save_cmd(str);
    else if (strcmp(token, "nes_pause") == 0)
        nes_pause_cmd();
    else if (strcmp(token, "nes_resume") == 0)
        nes_resume_cmd();
    else if (strcmp(token, "debug_mem") == 0)
        debug_mem_cmd();
    else if (strcmp(token, "hexdump") == 0)
        hexdump_cmd(str);
    else if (strcmp(token, "power") == 0)
        power_report();
    else if (*token != '\0')
        printf("unknown command\n");
    prompt();
}

int main(void) {
    irq_setmask(0);
    irq_setie(1);

    uart_init();
    heap_init();

    help();
    rom_rotator_init();

    prompt();

    while (1) {
        console_service();

        if (rom_rotator_service())
            prompt();
    }

    return 0;
}
