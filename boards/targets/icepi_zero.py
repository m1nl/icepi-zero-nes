#!/usr/bin/env python3

#
# This file is part of LiteX-Boards.
#
# Copyright (c) 2020 Florent Kermarrec <florent@enjoy-digital.fr>
# SPDX-License-Identifier: BSD-2-Clause

from litex.build.io import DDROutput
from litex.gen import *
from litex.soc.cores.clock import *
from litex.soc.cores.video import VideoHDMI10to1Serializer
from litex.soc.integration.builder import *
from litex.soc.integration.soc import SoCRegion
from litex.soc.integration.soc_core import *
from litex.soc.interconnect import stream
from migen import *

from boards.platforms import icepi_zero
from gateware.nes_top import NESTop

# CRG ----------------------------------------------------------------------------------------------

SYS_CLK_FREQUENCY = 50e6
TMDS_CLK_FREQUENCY = 27e6
USB_CLK_FREQ = 60e6


class _CRG(LiteXModule):
    def __init__(
        self, platform, sys_clk_freq, sdram_rate="1:2", tmds_clk_freq=TMDS_CLK_FREQUENCY, usb_clk_freq=USB_CLK_FREQ
    ):
        self.rst = Signal()
        self.cd_sys = ClockDomain()
        if sdram_rate == "1:2":
            self.cd_sys2x = ClockDomain()
            self.cd_sys2x_ps = ClockDomain()
        else:
            self.cd_sys_ps = ClockDomain()
        self.cd_usb = ClockDomain()
        self.cd_tmds = ClockDomain()
        self.cd_tmds5x = ClockDomain()

        # Clock
        clk50 = platform.request("clk50")
        rst = platform.request("rst")

        # PLL
        self.pll = pll = ECP5PLL()
        self.comb += pll.reset.eq(~rst)
        pll.register_clkin(clk50, 50e6)
        pll.create_clkout(self.cd_sys, sys_clk_freq)

        if sdram_rate == "1:2":
            pll.create_clkout(self.cd_sys2x, 2 * sys_clk_freq)
            pll.create_clkout(self.cd_sys2x_ps, 2 * sys_clk_freq, phase=180)  # Idealy 90° but needs to be increased.
        else:
            pll.create_clkout(self.cd_sys_ps, sys_clk_freq, phase=90)

        # SDRAM clock
        sdram_clk = ClockSignal("sys2x_ps" if sdram_rate == "1:2" else "sys_ps")
        self.specials += DDROutput(1, 0, platform.request("sdram_clock"), sdram_clk)

        # USB clock
        pll.create_clkout(self.cd_usb, usb_clk_freq)

        # Video PLL
        self.video_pll = video_pll = ECP5PLL()
        self.comb += video_pll.reset.eq(~rst)
        video_pll.register_clkin(clk50, 50e6)
        video_pll.create_clkout(self.cd_tmds, tmds_clk_freq)
        video_pll.create_clkout(self.cd_tmds5x, tmds_clk_freq * 5)


# BaseSoC ------------------------------------------------------------------------------------------


class BaseSoC(SoCCore):
    mem_map = {
        **SoCCore.mem_map,
        **{
            "spiflash": 0x20000000,
        },
    }

    def __init__(
        self,
        device="LFE5U-25F",
        toolchain="trellis",
        sys_clk_freq=SYS_CLK_FREQUENCY,
        sdram_rate="1:2",
        l2_size=0,
        with_spi_flash=True,
        **kwargs,
    ):
        platform = icepi_zero.Platform(device=device, toolchain=toolchain)

        # CRG --------------------------------------------------------------------------------------
        uart_name = kwargs.get("uart_name", "serial")
        self.crg = _CRG(platform, sys_clk_freq, sdram_rate=sdram_rate)

        # SoCCore ----------------------------------------------------------------------------------
        SoCCore.__init__(self, platform, sys_clk_freq, ident="LiteX SoC on Icepi Zero", **kwargs)

        # SDR SDRAM --------------------------------------------------------------------------------
        if not self.integrated_main_ram_size:
            from litedram.core import ControllerSettings
            from litedram.modules import W9825G6KH6
            from litedram.phy import GENSDRPHY, HalfRateGENSDRPHY

            controller_settings = ControllerSettings(address_mapping="ROW_BANK_COL")
            sdrphy_cls = HalfRateGENSDRPHY if sdram_rate == "1:2" else GENSDRPHY
            self.sdrphy = sdrphy_cls(platform.request("sdram"), sys_clk_freq)
            self.add_sdram(
                "sdram",
                phy=self.sdrphy,
                module=W9825G6KH6(sys_clk_freq, sdram_rate),
                size=0x40000000,
                l2_cache_size=l2_size,
                controller_settings=controller_settings,
            )

        # NES PPU Native LiteDRAM Interface -------------------------------------------------------
        if hasattr(self, "sdram"):
            self.nes_ppu_mem_port = self.sdram.crossbar.get_port(clock_domain="sys", data_width=8)

        # NES CPU Native LiteDRAM Interface -------------------------------------------------------
        if hasattr(self, "sdram"):
            self.nes_cpu_mem_port = self.sdram.crossbar.get_port(clock_domain="sys", data_width=8)

        # SPI Flash --------------------------------------------------------------------------------
        if with_spi_flash:
            from litespi.modules import W25Q128JV
            from litespi.opcodes import SpiNorFlashOpCodes as Codes

            bios_flash_offset = 0x100000
            bios_flash_size = 0x10000
            self.add_spi_flash(mode="4x", module=W25Q128JV(Codes.READ_1_1_4), with_master=False)
            self.bus.add_region(
                "rom",
                SoCRegion(
                    origin=self.bus.regions["spiflash"].origin + bios_flash_offset,
                    size=bios_flash_size,
                    linker=True,
                    mode="rx",
                ),
            )
            self.cpu.set_reset_address(self.bus.regions["rom"].origin)

        # TMDS -------------------------------------------------------------------------------------
        tmds = platform.request("gpdi")

        self.tmds_0 = Signal(10)
        self.tmds_1 = Signal(10)
        self.tmds_2 = Signal(10)

        drive_pols = []
        for pol in ["p", "n"]:
            if hasattr(tmds, f"clk_{pol}"):
                drive_pols.append(pol)

        for pol in drive_pols:
            self.specials += DDROutput(
                i1={"p": 1, "n": 0}[pol],
                i2={"p": 0, "n": 1}[pol],
                o=getattr(tmds, f"clk_{pol}"),
                clk=ClockSignal("tmds"),
            )

        for pol in drive_pols:
            for i, port in enumerate([self.tmds_0, self.tmds_1, self.tmds_2]):
                # 10:2 Gearbox.
                # data_in = Endpoint([("data", 10)])
                # data_in.ready.eq(gb.sink.ready)
                gearbox = ClockDomainsRenamer("tmds5x")(stream.Gearbox(i_dw=10, o_dw=2, msb_first=False))
                self.comb += gearbox.sink.data.eq(port)
                self.comb += gearbox.sink.valid.eq(1)
                self.add_module(f"tmds_{i}_gearbox_{pol}", gearbox)

                # 2:1 Output DDR.
                data_o = getattr(tmds, f"data{i}_{pol}")
                self.comb += gearbox.source.ready.eq(1)
                self.specials += DDROutput(
                    clk=ClockSignal("tmds5x"),
                    i1=gearbox.source.data[0],
                    i2=gearbox.source.data[1],
                    o=data_o,
                )

        # NES Top ----------------------------------------------------------------------------------
        if hasattr(self, "nes_ppu_mem_port") and hasattr(self, "nes_cpu_mem_port"):
            self.nes_top = NESTop(
                platform,
                cpu_mem_port=self.nes_cpu_mem_port,
                ppu_mem_port=self.nes_ppu_mem_port,
                leds=platform.request_all("user_led"),
                tmds_0=self.tmds_0,
                tmds_1=self.tmds_1,
                tmds_2=self.tmds_2,
                usb_0=platform.request("usb", 1),  # swap USB inputs
                usb_1=platform.request("usb", 0),
                clk_domain="sys",
                tmds_clk_domain="tmds",
                usb_clk_domain="usb",
            )
            self.nes_control = self.nes_top.control
            self.irq.add("nes_control", use_loc_if_exists=True)


# Build --------------------------------------------------------------------------------------------


def main():
    from litex.build.parser import LiteXArgumentParser

    parser = LiteXArgumentParser(platform=icepi_zero.Platform, description="LiteX SoC on Icepi Zero.")
    parser.add_target_argument("--device", default="LFE5U-25F", help="FPGA device (LFE5U-25F).")
    parser.add_target_argument("--sdram-rate", default="1:2", help="SDRAM Rate (1:1 Full Rate or 1:2 Half Rate).")
    parser.add_target_argument("--with-spi-flash", action="store_true", help="Enable memory-mapped SPI flash.")
    parser.add_target_argument("--sys-clk-freq", default=SYS_CLK_FREQUENCY, type=float, help="System clock frequency.")

    parser.set_defaults(
        l2_size=0,
        integrated_main_ram_size=0,
        integrated_rom_size=0,
        integrated_sram_size=8192,
        bios_lto=True,
        sys_clk_freq=SYS_CLK_FREQUENCY,
        with_spi_flash=True,
        cpu_variant="lite",
        yosys_flow3=True,
        yosys_abc9=True,
    )
    args = parser.parse_args()

    soc = BaseSoC(
        device=args.device,
        toolchain=args.toolchain,
        sys_clk_freq=args.sys_clk_freq,
        sdram_rate=args.sdram_rate,
        with_spi_flash=args.with_spi_flash,
        **parser.soc_argdict,
    )

    soc.add_spi_sdcard()

    builder = Builder(soc, **parser.builder_argdict)
    if args.build:
        soc.platform.toolchain._yosys_cmds.append("stat -hierarchy")
        builder.build(**parser.toolchain_argdict)

    if args.load:
        prog = soc.platform.create_programmer()
        prog.load_bitstream(builder.get_bitstream_filename(mode="sram", ext=".bit"))


if __name__ == "__main__":
    main()
