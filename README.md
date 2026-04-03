# icepi-zero-nes

A complete NES implementation for the IcePi-Zero FPGA board, featuring HDMI output, USB gamepad support, and SD card ROM loading.

## Features

- **Full NES emulation** running on FPGA hardware at cycle-accurate timing
- **HDMI video output** at 720x480 resolution with 2.4x horizontal and 2x vertical scaling
- **48 kHz audio** with filtering via HDMI
- **USB gamepad support** for two controllers (USB 1.1, including X-Input and 8BitDo devices)
- **SD card ROM loading** with automatic ROM rotation via gamepad controls
- **Multiple mapper support** including MMC1-5 and various other mappers
- **iNES and NES 2.0** ROM format support

## Hardware Requirements

- [IcePi-Zero](https://github.com/cheyao/icepi-zero) FPGA board (Lattice ECP5U-25F with 256Mbit SDRAM)
- SD card (FAT32 formatted)
- HDMI display (via MiniGPDI connector)
- USB gamepads (at least one required for gameplay)
- USB-C power supply

## Building

### Prerequisites

Install the following tools:
- GHDL
- Yosys
- Project Trellis
- nextpnr (with ECP5 support)
- Python 3.8+
- openFPGALoader

### Setup Build Environment

```bash
# Clone repository with submodules
git clone --recursive https://github.com/yourusername/icepi-zero-nes
cd icepi-zero-nes

# Initialize git submodules
git submodule update --init

# Create Python virtual environment
python3 -m venv venv
source venv/bin/activate

# Install LiteX
cd litex_src
wget https://raw.githubusercontent.com/enjoy-digital/litex/master/litex_setup.py
chmod +x litex_setup.py
./litex_setup.py --init --install
cd ..
```

### Build Gateware and Firmware

```bash
# Build FPGA bitstream
python3 -m boards.targets.icepi_zero --build

# Build firmware
make -C firmware BUILD_DIR=../build/icepi_zero/
```

## Installation

### Flash FPGA

```bash
# Flash bitstream to SPI flash
openFPGALoader -b icepi-zero --write-flash build/icepi_zero/gateware/icepi_zero.bit

# Flash BIOS to SPI flash at offset 0x100000
openFPGALoader -b icepi-zero --write-flash --offset 0x100000 build/icepi_zero/software/bios/bios.bin
```

### Prepare SD Card

1. Format SD card as FAT32
2. Copy `firmware/boot.json` to SD card root
3. Copy `firmware/icepi-zero-nes.bin` to SD card root
4. Create a `roms` directory on the SD card
5. Copy your `.nes` ROM files to the `roms` directory

## Usage

### Controls

- **X + Y + UP/DOWN**: Switch between ROMs
- **X + Y + A**: Select button (for controllers missing Select)
- **X + Y + B**: Start button (for controllers missing Start)
- **X + Y + A + B**: Reset current game
- **Standard NES controls**: D-pad, A, B, Start, Select

### Serial Console Commands

Connect via serial at 115200 baud:

- `help` - Show available commands
- `load_nes <path>` - Load a specific NES ROM
- `ls [path]` - List SD card directory contents
- `debug_mem` - Show last CPU/PPU SDRAM addresses
- `hexdump <addr> [len]` - Display memory contents
- `reboot` - Reboot the system

## Technical Details

### Architecture

- **System Clock**: 50 MHz (default, as in LiteX target definiton)
- **NES Clock**: 21.487 MHz (generated via phase accumulator, avoids CDC with memory controller)
- **Video Output**: 256x240 native resolution, scaled to 720x480 HDMI
- **Memory**: 32 MB SDRAM with separate banks for firmware, NES CPU, and NES PPU
- **Audio**: 16-bit samples, DC-blocked and filtered at 20 kHz

### Memory Map

| Region    | Base Address | Size   | Description |
|-----------|-------------|--------|-------------|
| ROM       | 0x00000000  | 128 KB | Boot ROM (SPI Flash) |
| SRAM      | 0x10000000  | 8 KB   | Internal SRAM |
| MAIN_RAM  | 0x40000000  | 32 MB  | SDRAM |
| CSR       | 0xF0000000  | 64 KB  | Control/Status Registers |

### NES ROM Layout in SDRAM

| Offset     | Description |
|------------|-------------|
| 0x40000000 | PRG ROM (CPU data) |
| 0x40800400 | CHR ROM (PPU data) |
| 0x40380000 | Work RAM |
| 0x41000000 | Firmware code |

### Key Components

- **NES Core**: Based on the [MiSTer NES](https://github.com/MiSTer-devel/NES_MiSTer) project (originally by Ludvig Strigeus)
- **HDMI Output**: Modified from [hdl-util/hdmi](https://github.com/hdl-util/hdmi) by Sameer Puri
- **USB HID Host**: By m1nl and nand2mario ([m1nl/usb_hid_host](https://github.com/m1nl/usb_hid_host))
- **SoC Framework**: Built with [LiteX](https://github.com/enjoy-digital/litex)

## Design Decisions

### Memory Architecture
The SDRAM controller runs at 100 MHz (2x system clock) to provide sufficient bandwidth for concurrent NES CPU and PPU access. To avoid memory conflicts, the SDRAM address space is carefully partitioned:
- **Bank separation**: CPU data uses bank bits `[11:10] = 2'b00`, PPU data uses `[11:10] = 2'b01` within each 4KB page
- **System clock at 50 MHz**: Chosen to avoid clock domain crossing with the memory controller, simplifying the design and improving timing
- **Separate LiteDRAM ports**: Independent 8-bit wide ports for CPU and PPU allow concurrent access patterns

### Audio Processing
- **Clock domain isolation**: Audio runs entirely in the TMDS clock domain (27 MHz), CDC is moved out of HDMI core
- **DC blocking**: Implemented by subtracting bias (0x7FFF) from the unsigned NES audio samples
- **20 kHz Butterworth filter**: Removes high-frequency artifacts while preserving NES audio character
- **HDMI integration**: Audio samples are packed into HDMI data islands at 48 kHz

### Video Pipeline
- **Framebuffer design**: Eliminates screen tearing and simplifies HDMI timing
- **Scaling choice (2.4x H, 2x V)**: Produces 720x480 output that's compatible with most HDMI displays
- **Fixed HDMI timing**: Always outputs stable 720x480@60Hz regardless of NES PPU state

### NES Core Integration
- **Black box approach**: NES core is instantiated as Verilog within LiteX, maintaining clean interfaces
- **CSR integration**: Control registers exposed via LiteX CSR bus for firmware control
- **Mapper conversion**: SystemVerilog mappers converted to Verilog using sv2v for tool compatibility
- **Phase accumulator timing**: Ensures 21.487 MHz NES clock from 50 MHz system clock

### USB and Input Handling
- **Dual USB hosts**: Allows two-player support with independent USB controllers
- **ROM rotation via IRQ**: Controller combos trigger interrupts for seamless ROM switching
- **Gamepad compatibility**: USB 1.1 HID implementation supports wide range of controllers including modern 8BitDo devices

### Build System
- **LiteX BIOS in SPI flash**: Frees up valuable BRAM for NES implementation
- **Firmware at 0x41000000**: Placed after NES memory regions to avoid conflicts
- **TLSF heap allocator**: Provides dynamic memory for ROM list management

## Limitations

- NTSC timing only (no PAL support)
- Some mappers disabled to meet timing constraints
- USB 1.1 speed only (sufficient for gamepad input)

## License

This project contains components under various open-source licenses:
- NES core: GPL-3.0 (based on Ludvig Strigeus's work)
- LiteX framework: BSD-2-Clause
- See individual component directories for specific licenses

## Acknowledgments

- cheyao for the [IcePi-Zero](https://github.com/cheyao/icepi-zero) board design
- The [MiSTer NES](https://github.com/MiSTer-devel/NES_MiSTer) project and its contributors
- Gideon Zweijtzer for [6502n](https://github.com/GideonZ/1541ultimate/tree/master/fpga/6502n/vhdl_source) CPU implementation
- Ludvig Strigeus for the [original FPGA NES](https://github.com/strigeus/fpganes) implementation
- Sameer Puri for the [HDMI core](https://github.com/hdl-util/hdmi) implementation
- The LiteX team for the [SoC framework](https://github.com/enjoy-digital/litex)
- All contributors to the various mapper implementations

