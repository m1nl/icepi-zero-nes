#ifndef ROM_ROTATOR_H
#define ROM_ROTATOR_H

void rom_rotator_init(void);
void rom_rotator_isr(void);
void rom_rotator_next_rom_isr(void);
void rom_rotator_previous_rom_isr(void);
void rom_rotator_reset_rom_isr(void);

#endif
