// Copyright (c) 2012-2013 Ludvig Strigeus
// This program is GPL Licensed. See COPYING for the full license.

// Changes by Mateusz Nalewajski
// - simplify clock management (skip dejitter since framebuffer is used)
// - disable PAL support, make core NTSC-only
// - route APU signals to MMC5 cartridge to simplify design

// Sprite DMA Works as follows.
// When the CPU writes to $4014 DMA is initiated ASAP.
// DMA runs for 512 cycles, the first cycle it reads from address
// xx00 - xxFF, into a latch, and the second cycle it writes to $2004.

// Facts:
// 1) Sprite DMA always does reads on even cycles and writes on odd cycles.
// 2) There are 1-2 cycles of cpu_read=1 after cpu_read=0 until Sprite DMA starts (pause_cpu=1, aout_enable=0)
// 3) Sprite DMA reads the address value on the last clock of cpu_read=0
// 4) If DMC interrupts Sprite, then it runs on the even cycle, and the odd cycle will be idle (pause_cpu=1, aout_enable=0)
// 5) When DMC triggers && interrupts CPU, there will be 2-3 cycles (pause_cpu=1, aout_enable=0) before DMC DMA starts.

// https://wiki.nesdev.com/w/index.php/PPU_OAM
// https://wiki.nesdev.com/w/index.php/APU_DMC
// https://forums.nesdev.com/viewtopic.php?f=3&t=6100
// https://forums.nesdev.com/viewtopic.php?f=3&t=14120

module DmaController(
  input clk,
  input ce,
  input reset,
  input odd_cycle,               // Current cycle even or odd?
  input sprite_trigger,          // Sprite DMA trigger?
  input dmc_trigger,             // DMC DMA trigger?
  input cpu_read,                // CPU is in a read cycle?
  input [7:0] data_from_cpu,     // Data written by CPU?
  input [7:0] data_from_ram,     // Data read from RAM?
  input [15:0] dmc_dma_addr,     // DMC DMA Address
  output [15:0] aout,            // Address to access
  output aout_enable,            // DMA controller wants bus control
  output read,                   // 1 = read, 0 = write
  output [7:0] data_to_ram,      // Value to write to RAM
  output dmc_ack,                // ACK the DMC DMA
  output pause_cpu               // CPU is pausede
);

// XXX: OAM DMA appears to be 1 cycle too short
reg dmc_state;
reg [1:0] spr_state;
reg [7:0] sprite_dma_lastval;
reg [15:0] sprite_dma_addr;     // sprite dma source addr
wire [8:0] new_sprite_dma_addr = sprite_dma_addr[7:0] + 8'h01;

always @(posedge clk) begin
  if (reset) begin
    dmc_state <= 0;
    spr_state <= 0;
    sprite_dma_lastval <= 0;
    sprite_dma_addr <= 0;

  end else if (ce) begin
    if (dmc_state == 0 && dmc_trigger && cpu_read && !odd_cycle) dmc_state <= 1;
    if (dmc_state == 1 && !odd_cycle) dmc_state <= 0;

    if (sprite_trigger) begin sprite_dma_addr <= {data_from_cpu, 8'h00}; spr_state <= 1; end
    if (spr_state == 1 && cpu_read && odd_cycle) spr_state <= 3;
    if (spr_state[1] && !odd_cycle && dmc_state == 1) spr_state <= 1;
    if (spr_state[1] && odd_cycle) sprite_dma_addr[7:0] <= new_sprite_dma_addr[7:0];
    if (spr_state[1] && odd_cycle && new_sprite_dma_addr[8]) spr_state <= 0;
    if (spr_state[1]) sprite_dma_lastval <= data_from_ram;
  end
end

assign pause_cpu = (spr_state[0] || dmc_trigger);
assign dmc_ack   = (dmc_state == 1 && !odd_cycle);
assign aout_enable = dmc_ack || spr_state[1];
assign read = !odd_cycle;
assign data_to_ram = sprite_dma_lastval;
assign aout = dmc_ack ? dmc_dma_addr : !odd_cycle ? sprite_dma_addr : 16'h2004;

endmodule

module NES #(
  parameter CPU_MODEL = 0
) (
  input         clk,
  input         reset,
  input         enable,
  input         pause,
  output reg    paused,

  input  [63:0] mapper_flags,
  output  [5:0] color,         // pixel generated from PPU
  output  [2:0] joypad_out,    // Set to 1 to strobe joypads. Then set to zero to keep the value (bit0)
  output  [1:0] joypad_clock,  // Set to 1 for each joypad to clock it.
  input   [4:0] joypad1_data,  // Port1
  input   [4:0] joypad2_data,  // Port2
  input   [1:0] mask,

  // Access signals for the SDRAM.
  output [21:0] cpumem_addr,
  output        cpumem_read,
  output        cpumem_write,
  output  [7:0] cpumem_dout,
  input   [7:0] cpumem_din,

  output [21:0] ppumem_addr,
  output        ppumem_read,
  output        ppumem_write,
  output  [7:0] ppumem_dout,
  input   [7:0] ppumem_din,

  output  [8:0] cycle,
  output  [8:0] scanline,
  output  [2:0] emphasis,

  input   [4:0] audio_channels,  // Enabled audio channels
  output [15:0] sample,          // sample generated from APU
  input         int_audio,
  input         ext_audio,

  output        cpu_ce,
  output        ppu_ce
);


/**********************************************************/
/*************            Clocks            ***************/
/**********************************************************/

// odd or even apu cycle, AKA div_apu or apu_/clk2. This is actually not 50% duty cycle. It is high for 18
// master cycles and low for 6 master cycles. It is considered active when low or "even".
reg odd_or_even = 0; // 1 == odd, 0 == even

// Main counter
wire [11:0] clock_start = 12'b000000000010;

reg [11:0] div_cpu = clock_start;

// CE's
assign cpu_ce  = div_cpu[0];
assign ppu_ce  = div_cpu[4] || div_cpu[8] || div_cpu[0];

wire cart_ce = div_cpu[4];
wire apu_ce  = div_cpu[0];

// Signals
wire cart_pre  = div_cpu[4];
wire ppu_read  = div_cpu[8];
wire ppu_write = div_cpu[4];

// APU PHI2
wire phi2 = |(div_cpu[11:5]);

always @(posedge clk) begin
  if (reset) begin
    div_cpu     <= clock_start;
    odd_or_even <= 1'b0;
    paused      <= pause;

  end else if (enable) begin
    if (div_cpu != clock_start || !paused) begin
      div_cpu <= {div_cpu[10:0], div_cpu[11]};

      if (apu_ce)
         odd_or_even <= ~odd_or_even;

      if (cpu_ce && cpu_rnw)
        paused <= pause;

    end else
      paused <= pause;
  end
end

/**********************************************************/
/*************              CPU             ***************/
/**********************************************************/

wire  [7:0] from_data_bus;

wire  [7:0] cpu_dout;
wire  [7:0] cpu_din;
wire [15:0] cpu_addr;
wire        cpu_rnw;
wire        dma_pause_cpu;
wire        nmi;
wire        mapper_irq;
wire        apu_irq;

assign cpu_din = cpu_rnw ? from_data_bus : cpu_dout;

// IRQ only changes once per CPU ce and with our current
// limited CPU model, NMI is only latched on the falling edge
// of M2, which corresponds with CPU ce, so no latches needed.
generate
  if (CPU_MODEL) begin : CPU_6502N
    proc_core cpu (
      .clock        (clk),
      .clock_en     (cpu_ce && enable),
      .reset        (reset),
      .ready        (~(dma_pause_cpu || pause || paused)),
      .irq_n        (~(apu_irq || mapper_irq)),
      .nmi_n        (~nmi),
      .so_n         (1'b1),
      .addr_out     (cpu_addr),
      .data_in      (cpu_din),
      .data_out     (cpu_dout),
      .read_write_n (cpu_rnw),
      .interrupt_ack(),
      .pc_out       ()
    );
  end else begin : CPU_T65
    T65 cpu (
      .Mode   (2'b00),
      .BCD_en (1'b0),
      .Res_n  (~reset),
      .Enable (cpu_ce && enable),
      .Clk    (clk),
      .Rdy    (~(dma_pause_cpu || pause || paused)),
      .Abort_n(1'b1),
      .IRQ_n  (~(apu_irq || mapper_irq)),
      .NMI_n  (~nmi),
      .SO_n   (1'b1),
      .R_W_n  (cpu_rnw),
      .A      (cpu_addr),
      .DI     (cpu_din),
      .DO     (cpu_dout),
      .NMI_ack()
    );
  end
endgenerate

wire dma_cs;
wire [15:0] dma_aout;
wire dma_aout_enable;
wire dma_read;
wire [7:0] dma_data_to_ram;
wire apu_dma_request, apu_dma_ack;
wire [15:0] apu_dma_addr;

// Determine the values on the bus outgoing from the CPU chip (after DMA / APU)
wire [15:0] addr   = dma_aout_enable ? dma_aout        : cpu_addr;
wire  [7:0] dbus   = dma_aout_enable ? dma_data_to_ram : cpu_dout;
wire        mr_int = dma_aout_enable ? dma_read        : cpu_rnw;
wire        mw_int = dma_aout_enable ? !dma_read       : !cpu_rnw;

assign dma_cs  = addr == 'h4014;

DmaController dma (
  .clk           (clk),
  .ce            (cpu_ce && enable),
  .reset         (reset),
  .odd_cycle     (odd_or_even),                 // Even or odd cycle
  .sprite_trigger(dma_cs && mw_int),            // Sprite trigger
  .dmc_trigger   (apu_dma_request),             // DMC Trigger
  .cpu_read      (cpu_rnw),                     // CPU in a read cycle?
  .data_from_cpu (cpu_dout),                    // Data from cpu
  .data_from_ram (from_data_bus),               // Data from RAM etc.
  .dmc_dma_addr  (apu_dma_addr),                // DMC addr
  .aout          (dma_aout),
  .aout_enable   (dma_aout_enable),
  .read          (dma_read),
  .data_to_ram   (dma_data_to_ram),
  .dmc_ack       (apu_dma_ack),
  .pause_cpu     (dma_pause_cpu)
);

/**********************************************************/
/*************             APU              ***************/
/**********************************************************/

wire apu_cs = addr >= 'h4000 && addr < 'h4018;

wire  [7:0] apu_dout;
wire [15:0] sample_apu;

APU apu (
  .MMC5          (1'b0),
  .clk           (clk),
  .PHI2          (phi2),
  .CS            (apu_cs),
  .PAL           (1'b0),
  .ce            (apu_ce && enable),
  .reset         (reset),
  .cold_reset    (reset),
  .ADDR          (addr[4:0]),
  .DIN           (dbus),
  .DOUT          (apu_dout),
  .RW            (cpu_rnw),
  .audio_channels(audio_channels),
  .Sample        (sample_apu),
  .DmaReq        (apu_dma_request),
  .DmaAck        (apu_dma_ack),
  .DmaAddr       (apu_dma_addr),
  .DmaData       (from_data_bus),
  .odd_or_even   (odd_or_even),
  .IRQ           (apu_irq),
  .allow_us      (1'b0)
);

assign sample = sample_a;

reg [15:0] sample_a;

always @(*) begin
  case (audio_en)
    0: sample_a = 16'd0;
    1: sample_a = sample_ext;
    2: sample_a = sample_inverted;
    3: sample_a = sample_ext;
  endcase
end

wire [15:0] sample_inverted = ~sample_apu;
wire [1:0]  audio_en        = {int_audio, ext_audio};
wire [15:0] audio_mappers   = (audio_en == 2'b01) ? 16'd0 : sample_inverted;

reg [2:0] joy_out;

always @(posedge clk) begin
  if (joypad1_cs && mw_int)
    joy_out <= cpu_dout[2:0];
end

// Joypads are mapped into the APU's range.
wire joypad1_cs = (addr == 'h4016);
wire joypad2_cs = (addr == 'h4017);

assign joypad_out   = joy_out;
assign joypad_clock = {joypad2_cs && mr_int, joypad1_cs && mr_int};

/**********************************************************/
/*************             PPU              ***************/
/**********************************************************/

// The real PPU has a CS pin which is a combination of the output of the 74319 (ppu address selector)
// and the M2 pin from the CPU. This will only be low for 1 and 7/8th PPU cycles, or
// 7 and 1/2 master cycles on NTSC. Therefore, the PPU should read or write once per cpu cycle, and
// with our alignment, this should occur at PPU cycle 2 (the *third* cycle).

wire mr_ppu = mr_int && ppu_read;   // Read *from* the PPU.
wire mw_ppu = mw_int && ppu_write;  // Write *to* the PPU.
wire ppu_cs = addr >= 'h2000 && addr < 'h4000;

wire [7:0] ppu_dout;           // Data from PPU to CPU
wire chr_read, chr_write;      // If PPU reads/writes from VRAM
wire [13:0] chr_addr;          // Address PPU accesses in VRAM
wire [7:0] chr_from_ppu;       // Data from PPU to VRAM
wire [7:0] chr_to_ppu;
wire [19:0] mapper_ppu_flags;  // PPU flags for mapper cheating
wire [8:0] ppu_cycle;

assign cycle = ppu_cycle;

PPU ppu (
  .clk             (clk),
  .ce              (ppu_ce && enable),
  .reset           (reset),
  .sys_type        (2'b00),
  .color           (color),
  .din             (dbus),
  .dout            (ppu_dout),
  .ain             (addr[2:0]),
  .read            (ppu_cs && mr_ppu),
  .write           (ppu_cs && mw_ppu),
  .nmi             (nmi),
  .vram_r          (chr_read),
  .vram_w          (chr_write),
  .vram_a          (chr_addr),
  .vram_din        (chr_to_ppu),
  .vram_dout       (chr_from_ppu),
  .scanline        (scanline),
  .cycle           (ppu_cycle),
  .mapper_ppu_flags(mapper_ppu_flags),
  .emphasis        (emphasis),
  .short_frame     (),
  .mask            (mask)
);

/**********************************************************/
/*************             Cart             ***************/
/**********************************************************/

wire prg_allow, prg_bus_write, prg_conflict, prg_conflict_d0, vram_a10, vram_ce, chr_allow;
wire [21:0] prg_linaddr, chr_linaddr;
wire [7:0] prg_dout_mapper, chr_from_ppu_mapper;
wire has_chr_from_ppu_mapper;
wire [15:0] sample_ext;

wire [15:0] prg_addr = addr;
wire  [7:0] prg_din = (dbus & (prg_conflict ? cpumem_din : 8'hFF)) | (prg_conflict_d0 ? cpumem_din & 8'h01 : 8'h00);

wire prg_read  = mr_int && cart_pre && !apu_cs && !ppu_cs && !dma_cs;
wire prg_write = mw_int && cart_pre && !apu_cs && !ppu_cs && !dma_cs;

cart_top multi_mapper (
  // FPGA specific
  .clk            (clk),
  .reset          (reset),
  .flags          (mapper_flags),             // iNES header data
  .paused         (1'b0),
  // Cart pins (slightly abstracted)
  .ce             (cart_ce && enable),        // M2
  .cpu_ce         (cpu_ce && enable),         // Serves as M2 Inverted
  .prg_ain        (prg_addr),                 // CPU Address in (a15 abstracted from ROMSEL)
  .prg_read       (prg_read),                 // CPU RnW split
  .prg_write      (prg_write),                // CPU RnW split
  .prg_din        (prg_din),                  // CPU Data bus in (split from bid)
  .prg_dout       (prg_dout_mapper),          // CPU Data bus out (split from bid)
  .chr_ain        (chr_addr),                 // PPU address in
  .chr_read       (chr_read),                 // PPU read (inverted, active high)
  .chr_write      (chr_write),                // PPU write (inverted, active high)
  .chr_din        (chr_from_ppu),             // PPU data bus in (split from bid)
  .chr_dout       (chr_from_ppu_mapper),      // PPU data bus in (split from bid)
  .vram_a10       (vram_a10),                 // CIRAM a10 line
  .vram_ce        (vram_ce),                  // CIRAM chip enable
  .irq            (mapper_irq),               // IRQ (inverted, active high)
  .audio_in       (audio_mappers),            // Amplified and inverted APU audio
  .audio          (sample_ext),               // Mixed audio output from cart
  // SDRAM Communication
  .prg_aout       (prg_linaddr),              // SDRAM adjusted PRG RAM address
  .prg_allow      (prg_allow),                // Simulates internal CE/Locking
  .chr_aout       (chr_linaddr),              // SDRAM adjusted CHR RAM address
  .chr_allow      (chr_allow),                // Simulates internal CE/Locking
  // Cheats
  .prg_from_ram   (from_data_bus),            // Hacky cpu din <= get rid of this!
  .ppuflags       (mapper_ppu_flags),         // Cheat for MMC5
  .ppu_ce         (ppu_ce && enable),         // PPU Clock (cheat for MMC5)
  .apu_ce         (apu_ce && enable),         // CE for MMC5 APU
  .phi2           (phi2),                     // PHI2 for MMC5 APU
  .odd_or_even    (odd_or_even),              // odd_or_even for MMC5 APU
  // Behavior helper flags
  .has_chr_dout   (has_chr_from_ppu_mapper),  // Output specific data for CHR rather than from SDRAM
  .prg_bus_write  (prg_bus_write),            // PRG data driven to bus
  .prg_conflict   (prg_conflict),             // Simulate bus conflicts
  .prg_conflict_d0(prg_conflict_d0)           // Simulate bus conflicts for Mapper 144
);

/**********************************************************/
/*************       Bus Arbitration        ***************/
/**********************************************************/

assign chr_to_ppu = has_chr_from_ppu_mapper ? chr_from_ppu_mapper : ppumem_din;

assign cpumem_addr  = prg_linaddr;
assign cpumem_read  = ((prg_read && prg_allow) || (prg_write && prg_conflict)) && !reset;
assign cpumem_write = prg_write && prg_allow && !reset;
assign cpumem_dout  = prg_din;

assign ppumem_addr  = chr_linaddr;
assign ppumem_read  = chr_read  && !reset;
assign ppumem_write = chr_write && (chr_allow || vram_ce) && !reset;
assign ppumem_dout  = chr_from_ppu;

reg [7:0] open_bus_data;

always @(posedge clk) begin
  if (reset)
    open_bus_data <= 0;
  else
    open_bus_data <= from_data_bus;
end

assign from_data_bus = raw_data_bus;

reg [7:0] raw_data_bus;

always @(*) begin
  raw_data_bus = open_bus_data;

  if (apu_cs) begin
    if (joypad1_cs)
      raw_data_bus = {open_bus_data[7:5], joypad1_data};
    else if (joypad2_cs)
      raw_data_bus = {open_bus_data[7:5], joypad2_data};
    else
      raw_data_bus = (addr == 16'h4015) ? apu_dout : open_bus_data;
  end else if (ppu_cs) begin
    raw_data_bus = ppu_dout;
  end else if (dma_cs) begin
    raw_data_bus = open_bus_data;
  end else if (prg_allow) begin
    raw_data_bus = cpumem_din;
  end else if (prg_bus_write) begin
    raw_data_bus = prg_dout_mapper;
  end
end

endmodule
// vim:ts=2 sw=2 tw=120 et
