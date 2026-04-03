# ---------------------------------------------------------------------------
# Copyright 2026 Mateusz Nalewajski
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# SPDX-License-Identifier: GPL-3.0-or-later
# ---------------------------------------------------------------------------

import os

from litex.build.io import DDROutput
from litex.build.vhd2v_converter import VHD2VConverter
from litex.gen import *
from litex.soc.cores.video import VideoHDMI10to1Serializer
from litex.soc.interconnect import stream
from litex.soc.interconnect.csr import *
from litex.soc.interconnect.csr_eventmanager import *
from migen import *


class NESControl(LiteXModule):
    def __init__(self):
        self.mapper_flags = CSRStorage(64, reset=0, description="NES mapper_flags register")
        self.nes_reset = CSRStorage(1, reset=1, description="NES reset (1=hold in reset, 0=run)")
        self.cpu_last_addr = CSRStatus(25, reset=0, description="Last SDRAM address issued by NES CPU")
        self.ppu_last_addr = CSRStatus(25, reset=0, description="Last SDRAM address issued by NES PPU")
        self.cpu_last_data = CSRStatus(8, reset=0, description="Last byte read from SDRAM by NES CPU")
        self.ppu_last_data = CSRStatus(8, reset=0, description="Last byte read from SDRAM by NES PPU")

        self.submodules.ev = EventManager()
        self.ev.next_rom = EventSourcePulse(description="Next ROM trigger")
        self.ev.previous_rom = EventSourcePulse(description="Next ROM trigger")
        self.ev.reset_rom = EventSourcePulse(description="Reset ROM trigger")
        self.ev.finalize()


class NESTop(Module):
    def __init__(
        self,
        platform,
        cpu_mem_port,
        ppu_mem_port,
        leds,
        tmds_0,
        tmds_1,
        tmds_2,
        usb_0,
        usb_1,
        clk_domain="sys",
        tmds_clk_domain="hdmi",
        usb_clk_domain="usb",
    ):
        cpu_aw = cpu_mem_port.address_width
        cpu_dw = cpu_mem_port.data_width
        ppu_aw = ppu_mem_port.address_width
        ppu_dw = ppu_mem_port.data_width

        self.submodules.control = NESControl()

        self.specials += Instance(
            "nes_top",
            p_CPU_ADDR_WIDTH=cpu_aw,
            p_CPU_DATA_WIDTH=cpu_dw,
            p_PPU_ADDR_WIDTH=ppu_aw,
            p_PPU_DATA_WIDTH=ppu_dw,
            i_clk=ClockSignal(clk_domain),
            i_rst=ResetSignal(clk_domain),
            # CPU mem port - cmd
            o_cpu_mem_cmd_valid=cpu_mem_port.cmd.valid,
            i_cpu_mem_cmd_ready=cpu_mem_port.cmd.ready,
            o_cpu_mem_cmd_we=cpu_mem_port.cmd.we,
            o_cpu_mem_cmd_addr=cpu_mem_port.cmd.addr,
            o_cpu_mem_cmd_last=cpu_mem_port.cmd.last,
            # CPU mem port - wdata
            o_cpu_mem_wdata_valid=cpu_mem_port.wdata.valid,
            i_cpu_mem_wdata_ready=cpu_mem_port.wdata.ready,
            o_cpu_mem_wdata_data=cpu_mem_port.wdata.data,
            o_cpu_mem_wdata_we=cpu_mem_port.wdata.we,
            # CPU mem port - rdata
            i_cpu_mem_rdata_valid=cpu_mem_port.rdata.valid,
            o_cpu_mem_rdata_ready=cpu_mem_port.rdata.ready,
            i_cpu_mem_rdata_data=cpu_mem_port.rdata.data,
            # PPU mem port - cmd
            o_ppu_mem_cmd_valid=ppu_mem_port.cmd.valid,
            i_ppu_mem_cmd_ready=ppu_mem_port.cmd.ready,
            o_ppu_mem_cmd_we=ppu_mem_port.cmd.we,
            o_ppu_mem_cmd_addr=ppu_mem_port.cmd.addr,
            o_ppu_mem_cmd_last=ppu_mem_port.cmd.last,
            # PPU mem port - wdata
            o_ppu_mem_wdata_valid=ppu_mem_port.wdata.valid,
            i_ppu_mem_wdata_ready=ppu_mem_port.wdata.ready,
            o_ppu_mem_wdata_data=ppu_mem_port.wdata.data,
            o_ppu_mem_wdata_we=ppu_mem_port.wdata.we,
            # PPU mem port - rdata
            i_ppu_mem_rdata_valid=ppu_mem_port.rdata.valid,
            o_ppu_mem_rdata_ready=ppu_mem_port.rdata.ready,
            i_ppu_mem_rdata_data=ppu_mem_port.rdata.data,
            # NES control
            i_mapper_flags=self.control.mapper_flags.storage,
            i_nes_reset=self.control.nes_reset.storage,
            o_cpu_last_addr=self.control.cpu_last_addr.status,
            o_ppu_last_addr=self.control.ppu_last_addr.status,
            o_cpu_last_data=self.control.cpu_last_data.status,
            o_ppu_last_data=self.control.ppu_last_data.status,
            o_next_rom_irq=self.control.ev.next_rom.trigger,
            o_previous_rom_irq=self.control.ev.previous_rom.trigger,
            o_reset_rom_irq=self.control.ev.reset_rom.trigger,
            o_leds=leds,
            # TMDS
            i_tmds_clk=ClockSignal(tmds_clk_domain),
            i_tmds_rst=ResetSignal(tmds_clk_domain),
            o_tmds_0=tmds_0,
            o_tmds_1=tmds_1,
            o_tmds_2=tmds_2,
            # USB
            i_usb_clk=ClockSignal(usb_clk_domain),
            i_usb_rst=ResetSignal(usb_clk_domain),
            o_usb_pullup_dp_0=usb_0.pullup[0],
            o_usb_pullup_dn_0=usb_0.pullup[1],
            o_usb_pullup_dp_1=usb_1.pullup[0],
            o_usb_pullup_dn_1=usb_1.pullup[1],
            io_usb_dp_0=usb_0.d_p,
            io_usb_dn_0=usb_0.d_n,
            io_usb_dp_1=usb_1.d_p,
            io_usb_dn_1=usb_1.d_n,
        )

        gateware_dir = os.path.dirname(__file__)
        platform.add_source(os.path.join(gateware_dir, "nes_top.v"))
        platform.add_source(os.path.join(gateware_dir, "nes.v"))
        platform.add_source(os.path.join(gateware_dir, "apu.v"))
        platform.add_source(os.path.join(gateware_dir, "ppu.v"))
        platform.add_source(os.path.join(gateware_dir, "cart.v"))
        platform.add_source(os.path.join(gateware_dir, "framebuffer.v"))
        platform.add_source(os.path.join(gateware_dir, "iir_filter.v"))
        platform.add_source(os.path.join(gateware_dir, "dc_blocker.v"))
        platform.add_source_dir(os.path.join(gateware_dir, "mappers"))
        platform.add_source_dir(os.path.join(gateware_dir, "hdmi"))
        platform.add_source_dir(os.path.join(gateware_dir, "cdc"))
        platform.add_source_dir(os.path.join(gateware_dir, "usb_hid_host/rtl"))
        platform.add_source_dir(os.path.join(gateware_dir, "usb_hid_host/rom"))

        cpu6502_dir = os.path.join(gateware_dir, "6502n")
        cpu6502 = VHD2VConverter(
            platform,
            name="proc_core",
            sources=[
                os.path.join(cpu6502_dir, "alu.vhd"),
                os.path.join(cpu6502_dir, "bit_cpx_cpy.vhd"),
                os.path.join(cpu6502_dir, "data_oper.vhd"),
                os.path.join(cpu6502_dir, "implied.vhd"),
                os.path.join(cpu6502_dir, "pkg_6502_decode.vhd"),
                os.path.join(cpu6502_dir, "pkg_6502_defs.vhd"),
                os.path.join(cpu6502_dir, "pkg_6502_opcodes.vhd"),
                os.path.join(cpu6502_dir, "proc_control.vhd"),
                os.path.join(cpu6502_dir, "proc_core.vhd"),
                os.path.join(cpu6502_dir, "proc_interrupt.vhd"),
                os.path.join(cpu6502_dir, "proc_registers.vhd"),
                os.path.join(cpu6502_dir, "shifter.vhd"),
            ],
        )
        cpu6502._ghdl_opts.append("-fsynopsys")
        self.submodules.cpu6502 = cpu6502
