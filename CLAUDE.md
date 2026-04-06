# LiteDRAM Native Port

Defined in `litex_src/litedram/litedram/common.py` via `LiteDRAMNativePort`.

## Signals

### cmd (master -> slave)
- `valid` (1)
- `ready` (1)
- `we` (1) — 1=write, 0=read
- `addr` (address_width)
- `last` (1)

### wdata (master -> slave)
- `valid` (1)
- `ready` (1)
- `data` (data_width)
- `we` (data_width//8) — byte enable

### rdata (slave -> master)
- `valid` (1)
- `ready` (1)
- `data` (data_width)

## Usage in LiteX target

```python
self.my_port = self.sdram.crossbar.get_port(data_width=8)
```

## Verilog wrapper pattern

Use `Instance()` in a `LiteXModule`/`Module` subclass, map signals with `o_`/`i_` prefixes, and register the `.v` file with `platform.add_source(...)`.

# Memory Map

| Region    | Base         | Size      |
|-----------|--------------|-----------|
| ROM       | 0x00000000   | 128 KB    |
| SRAM      | 0x10000000   | 8 KB      |
| MAIN_RAM  | 0x40000000   | 32 MB     |
| CSR       | 0xf0000000   | 64 KB     |

`MAIN_RAM_BASE = 0x40000000` (from `build/icepi_zero/software/include/generated/mem.h`)

# NES ROM Layout in MAIN_RAM

Addresses are offsets from `MAIN_RAM_BASE` (mirrors `game_loader.v`):

| Offset     | Description |
|------------|-------------|
| 0x40000000 | PRG ROM |
| 0x40E00000 | Internal RAM |
| 0x40F00000 | PRG RAM |
| 0x40800400 | CHR ROM and PPU VRAM |
| 0x41000000 | Firmware code |

# iNES / NES 2.0 Header Parsing

- 16-byte header; magic = `NES\x1A`
- `flags6[2]` = trainer present (not supported)
- NES 2.0 detected when `flags7[3:2] == 2'b10`
- NES 2.0 PRG exponent-multiplier: active when `flags9[3:0] == 4'hF`
- Dirty iNES 1.0: bytes 9-15 non-zero (ignore mapper high nibble)
- `mapper_flags` 64-bit field layout (matches `game_loader.v`):
  - `[7:0]`   mapper number
  - `[10:8]`  prg_size (3-bit encoded)
  - `[13:11]` chr_size (3-bit encoded)
  - `[14]`    mirroring
  - `[15]`    has_chr_ram
  - `[16]`    4-screen mode
  - `[24:17]` NES 2.0 submapper
  - `[25]`    has_saves
  - `[29:26]` PRG-RAM shift size
  - `[30]`    piano
  - `[34:31]` Save-RAM shift size
  - `[35]`    is NES 2.0
  - `[37:36]` timing
  - `[63:38]` 0

# CSR Registers — NESControl

Defined in `gateware/nes_top.py` as `NESControl(LiteXModule)`, exposed at SoC level as `self.nes_control` in `boards/targets/icepi_zero.py`.

| CSR name                   | Width | Reset        | Address offset | Description                     |
|----------------------------|-------|--------------|----------------|---------------------------------|
| `nes_control_mapper_flags` | 64    | 0            | 0x1000         | mapper_flags passed to NES core |
| `nes_control_nes_reset`    | 1     | 1            | 0x1008         | 1=hold NES in reset, 0=run      |
| `nes_control_cpu_last_addr`| 25    | 0            | 0x1014         | Last SDRAM address issued by NES CPU (read-only) |
| `nes_control_ppu_last_addr`| 25    | 0            | 0x1018         | Last SDRAM address issued by NES PPU (read-only) |

Generated accessor functions in `csr.h`:
- `nes_control_mapper_flags_write(uint64_t)` — writes both 32-bit halves
- `nes_control_nes_reset_write(uint32_t)`
- `nes_control_cpu_last_addr_read()` — returns last CPU SDRAM address (offset from MAIN_RAM_BASE)
- `nes_control_ppu_last_addr_read()` — returns last PPU SDRAM address (offset from MAIN_RAM_BASE)

To expose a `LiteXModule` submodule's CSRs at SoC level, assign it directly on the SoC:
```python
self.nes_control = self.nes_top.control
```

# SD Card / FatFS Usage

The icepi_zero board has both SPI and native SDIO pins wired to the same physical SD slot. **Always use native SDIO** (`add_sdcard` / `fatfs_set_ops_sdcard`) — it is faster (4-bit) and has full DMA-based BIOS boot support. SPI mode is only a fallback for boards without SDIO wiring.

- Native SD card: call `fatfs_set_ops_sdcard()` then `f_mount`
- SPI SD card: call `fatfs_set_ops_spisdcard()` then `f_mount`
- Headers: `<libfatfs/ff.h>`, `<liblitesdcard/sdcard.h>`
- Libraries present in build: `libfatfs.a`, `liblitesdcard.a`
- `soc.add_sdcard()` is called unconditionally in `boards/targets/icepi_zero.py`

# Demo App Build

- Source: `firmware/`
- Build command: `make -C firmware BUILD_DIR=../build/icepi_zero`
- Add new `.c` files to `OBJECTS` in `firmware/Makefile`
- CSR accessors available via `#include <generated/csr.h>`
- Memory map via `#include <generated/mem.h>`
- Public API between files goes in a `.h` header; include it in both the `.c` and the caller to avoid `-Wmissing-prototypes`

# Firmware Memory Layout

The firmware is linked at `0x41000000` (`firmware/linker.ld`):

| Address      | Content                                        |
|--------------|------------------------------------------------|
| 0x40000000   | NES PRG ROM (written at runtime)               |
| 0x40380000   | NES Work RAM (cleared at runtime)              |
| 0x40800400   | NES CHR ROM (written at runtime)               |
| 0x41000000   | Firmware `.text`/`.rodata` (main_ram VMA)      |
| 0x41028000   | Heap base (`_app_base + 100K`)                 |
| 0x10000000   | Firmware `.data`/`.bss`/stack (SRAM VMA)       |

- `.text`/`.rodata` linked at `0x41000000` in `main_ram`
- `.data` has VMA in `sram`, LMA in `main_ram` (copied at startup)
- `.bss` in `sram`
- Stack pointer: `ORIGIN(sram) + LENGTH(sram)` (`_fstack`)
- Heap: `_fheap = _app_base + 100K`, `_eheap = ORIGIN(main_ram) + LENGTH(main_ram)`

`firmware/linker.ld` sets `_app_base = 0x41000000`.

# LiteX BIOS SD Card Boot

The BIOS looks for `boot.json` on the SD card root, then falls back to `boot.bin`. `boot.json` maps filenames to load addresses; the **last entry** determines the CPU jump address.

`firmware/boot.json`:
```json
{
    "firmware.bin": "0x41000000"
}
```

Copy both `firmware.bin` and `boot.json` to the root of a FAT-formatted SD card. The BIOS will load `firmware.bin` at `0x41000000` and jump to it.

# NES Loader (`firmware/nes_loader.c`)

Loads a `.nes` file from SD card into MAIN_RAM and starts the NES core.

Key addresses (`firmware/nes_loader.c`):
- `PRG_ROM_BASE = MAIN_RAM_BASE + 0x0000000`
- `CHR_ROM_BASE = MAIN_RAM_BASE + 0x0800400`
- `CLEARRAM_GEN_OFF = 0x380000` (work RAM, cleared for 0xFFFFF bytes)

**SDRAM bank alignment:** The SDRAM address space is divided into 0x400-byte (1 KB) slots within each 0x1000-byte (4 KB) page. Bits `[11:10]` of the address select the bank within a page:
- PRG (CPU) data must land at `addr[11:10] == 2'b00` (offset `+0x000` within each 4 KB page)
- CHR (PPU) data must land at `addr[11:10] == 2'b01` (offset `+0x400` within each 4 KB page)

This keeps CPU RAM and character RAM in separate SDRAM banks so the NES core can access them independently. The write loops in `firmware/nes_loader.c` enforce this: if the current pointer has the wrong `[11:10]` bits, it advances to the next 4 KB page and forces the correct offset before writing.

Sequence (`nes_loader_cmd`):
1. `nes_control_nes_reset_write(1)` — hold NES in reset
2. Mount SD card via FatFS (`f_mount`)
3. Read & validate 16-byte iNES header
4. Write PRG ROM to `PRG_ROM_BASE` with page-alignment
5. Write CHR ROM (if any) to `CHR_ROM_BASE` with page-alignment
6. Clear work RAM (`CLEARRAM_GEN_OFF`, 0xFFFFF bytes) using `memset` in 0x3FF-byte chunks stepping 0x1000
7. `flush_cpu_dcache()` / `flush_l2_cache()`
8. `nes_control_mapper_flags_write(flags)` — pass parsed flags
9. `busy_wait_us(10000)`, then `nes_control_nes_reset_write(0)` — release reset, NES runs

Entry point: `nes_loader_cmd(const char *path)` — called from `main.c` via `load_prg <path>` command.
Public prototype declared in `firmware/nes_loader.h`.

# Bare-Metal C Library Limitations (picolibc-minimal)

The demo app links against picolibc-minimal, which is missing many standard functions. Known missing symbols:

- `sprintf`, `snprintf` — **not available**; use `memcpy`+`strlen` or manual string construction
- `strcasecmp`, `strcat`, `strcpy` — **not available**; use `memcpy`+`strlen` or local helpers
- `malloc`, `realloc`, `free` — **not available** from libc; provided by `demo/heap.c` (TLSF-backed)
- `__assert_no_args` — must be provided manually (see `demo/heap.c`)
- `__ffssi2` — emitted by `__builtin_ffs` on RISC-V; avoided by compiling `tlsf.c` with `-U__GNUC__`

**Rule:** When writing bare-metal C for the firmware, never use `sprintf`, `snprintf`, `strcat`, `strcpy`, or `strcasecmp`. Use `memcpy` and `strlen` (from `<string.h>`) for string operations.

# Heap / Dynamic Allocation

- TLSF allocator: `firmware/tlsf.c` / `firmware/tlsf.h`
- Wrappers: `firmware/heap.c` / `firmware/heap.h` — provides `malloc`, `realloc`, `free`, `heap_init()`
- `heap_init()` must be called before any `malloc`/`free`/`realloc`
- Heap symbols in `firmware/linker.ld`:
  - `_heap_base = _app_base + 100K` → `0x41028000` — 100 KiB reserved for firmware `.text`/`.rodata`
  - `_heap_end  = ORIGIN(main_ram) + LENGTH(main_ram)`
  - `PROVIDE(_fheap = _heap_base); PROVIDE(_eheap = _heap_end)`
- `tlsf.o` must be compiled with `CFLAGS += -U__GNUC__` to avoid `__ffssi2` linker error

# CDC Modules (`gateware/cdc/`)

Glob `platform.add_source(gateware_dir, "cdc", "*.v")` picks up all CDC modules automatically.

## `cdc_sync.v`
- 2-stage synchronizer, N-wide (default N=1), with `rst_dst`
- `(* ASYNC_REG = "TRUE" *)` on both stages

## `cdc_handshake.v`
- 4-phase handshake for single data word transfer across clock domains
- Parameters: `WIDTH`, `EXTERNAL_ACK` (default 0)
- When `EXTERNAL_ACK=1`: `valid` stays high until `ack_in` is asserted; CDC blocks until then
- Dst logic uses two separate `else if` branches — first asserts valid, second waits for ack:
  ```verilog
  if (req_dst_s2 != ack_dst && !valid) begin
      data_out <= data_hold; valid <= 1'b1;
  end else if (valid && (!EXTERNAL_ACK || ack_in)) begin
      valid <= 1'b0; ack_dst <= ~ack_dst;
  end
  ```

# IRQ / EventManager Pattern

To add an IRQ from a `LiteXModule` submodule:

1. In the submodule (`nes_top.py`), add:
   ```python
   from litex.soc.interconnect.csr_eventmanager import *
   self.ev = EventManager()
   self.ev.my_event = EventSourcePulse()
   self.ev.finalize()
   ```
2. Wire the trigger in `Instance(...)`: `o_my_irq=self.ev.my_event.trigger`
3. In the SoC target (`icepi_zero.py`): `self.irq.add("submodule_name", use_loc_if_exists=True)`
4. In C: register ISR with `irq_attach(NES_CONTROL_INTERRUPT, nes_control_isr)`, set mask with `irq_setmask(irq_getmask() | (1 << NES_CONTROL_INTERRUPT))`, clear pending in ISR with `nes_control_ev_pending_write(nes_control_ev_pending_read())`, enable event with `nes_control_ev_enable_write(1)`
5. The `isr()` dispatcher uses `irq_table[]` — **named ISR symbols are NOT called automatically**; `irq_attach()` is mandatory

# SPI Flash Boot

- `add_spi_flash(with_master=False)` — XIP mode; do NOT use `with_master=True` as it conflicts with BIOS memory-mapped access
- BIOS maps SPI flash at `0x20000000`; bitstream must be at offset 0, BIOS at `+0x100000`

# ROM Rotator (`firmware/rom_rotator.c`)

Scans `/roms` directory on SD card for `.nes` files on init, sorts alphabetically, loads first ROM. Three IRQ sources from `NESControl.ev` EventManager trigger navigation.

- Source: `firmware/rom_rotator.c`
- Entry points: `rom_rotator_init()` (call after `heap_init()`), `rom_rotator_isr()` (call from `nes_control_isr()`)
- Individual ISRs also available: `rom_rotator_next_rom_isr()`, `rom_rotator_previous_rom_isr()`, `rom_rotator_reset_rom_isr()`
- Uses dynamic `char **rom_list` (malloc/realloc), no fixed ROM limit
- Path construction uses `memcpy`+`strlen` (no `strcat`/`strcpy`/`sprintf`)
- `rom_rotator_init()` enables all three events: `nes_control_ev_enable_write(EV_NEXT_ROM | EV_PREVIOUS_ROM | EV_RESET_ROM)`

## EventManager event bits (NESControl)

| Bit | Name            | Trigger combo                          |
|-----|-----------------|----------------------------------------|
| 0   | `next_rom`      | Select+X or X+Y on either controller  |
| 1   | `previous_rom`  | Select+Y on either controller         |
| 2   | `reset_rom`     | Start+Select or X+Y+A+B               |

`reset_rom` ISR: asserts `nes_control_nes_reset_write(1)`, waits 100µs via `busy_wait_us(100)`, then reloads the current ROM (does NOT advance index).

## IRQ dispatch pattern in `rom_rotator_isr`

```c
uint32_t pending = nes_control_ev_pending_read();
nes_control_ev_pending_write(pending);
if (pending & EV_NEXT_ROM)     { ... }
else if (pending & EV_PREVIOUS_ROM) { ... }
else if (pending & EV_RESET_ROM)    { ... }
```

# Audio Pipeline (`gateware/nes_top.v`)

Audio path runs entirely in the `tmds_clk` domain after a `cdc_handshake` crossing from `clk`.

## Signal chain

```
cdc_handshake (EXTERNAL_ACK=1, WIDTH=16)
    data_out -> audio_sample_tmds          [16-bit unsigned]
    valid    -> audio_sample_tmds_valid
    ack_in   <- audio_sample_tmds_ack      (from iir_biquad.in_ready)

  (bias removal: subtract 0x7fff -> 17-bit signed; left-shift by 1 -> 18-bit signed input)

iir_biquad_0  (20 kHz Butterworth LPF, 5-cycle FSM)
    in       <- {audio_sample_tmds_signed, 1'b0}   [18-bit signed]
    in_valid <- audio_sample_tmds_valid
    in_ready -> audio_sample_tmds_ack               (back to cdc ack_in)
    out_ready<- audio_sample_tmds_en               (from hdmi)
    out_valid -> (unconnected — hdmi consumes on audio_sample_en strobe)
    out      -> audio_sample_tmds_filtered         [18-bit signed]

hdmi_0
    audio_sample_word_0/1 <- {audio_sample_tmds_filtered, 6'b0}   [24-bit]
    audio_sample_en       -> audio_sample_tmds_en
```

## Module interfaces

### `dc_blocker` (`gateware/dc_blocker.v`)
- Ports: `clk`, `reset`, `in_valid`, `in_ready`, `out_ready`, `out_valid`, `in [17:0]`, `out [17:0]`
- First-order IIR: `y[n] = x[n] - x[n-1] + alpha*y[n-1]`, alpha = 1 - 2^-10 (~7.4 Hz corner at 48 kHz)
- 20-bit internal accumulator with saturation; `in_ready = !out_valid || out_ready`

### `iir_biquad` (`gateware/iir_filter.v`)
- Ports: `clk`, `reset`, `in_valid`, `in_ready`, `out_ready`, `out_valid`, `in [17:0]`, `out [17:0]`
- 2nd-order Butterworth LPF, 20 kHz cutoff at 48 kHz, Q4.14 coefficients
- 6-state FSM, 5 multiply-accumulate cycles per sample
- `out_valid` is left unconnected in `nes_top.v`; downstream relies on `audio_sample_en` timing

# Yosys / nextpnr Build Options

Toolchain flags (`--yosys-flow3`, `--yosys-abc9`, etc.) are passed via `parser.toolchain_argdict` to `builder.build()`. Set defaults in `boards/targets/icepi_zero.py` via `parser.set_defaults()`:

```python
parser.set_defaults(
    ...
    yosys_flow3=True,
    yosys_abc9=True,
)
```

Additional one-off Yosys commands can be appended before the build:
```python
soc.platform.toolchain._yosys_cmds.append("stat -hierarchy")
```
