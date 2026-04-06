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

`default_nettype none
`timescale 1 ns / 1 ps
module nes_top #(
  parameter CPU_ADDR_WIDTH = 25,
  parameter CPU_DATA_WIDTH = 8,
  parameter CPU_ADDR_BANK  = 2'b00,
  parameter PPU_ADDR_WIDTH = 25,
  parameter PPU_DATA_WIDTH = 8,
  parameter PPU_ADDR_BANK  = 2'b01
) (
  input wire clk,
  input wire rst,

  // NES CPU LiteDRAM Native Port
  output reg                         cpu_mem_cmd_valid,
  input  wire                        cpu_mem_cmd_ready,
  output reg                         cpu_mem_cmd_we,
  output reg  [CPU_ADDR_WIDTH-1:0]   cpu_mem_cmd_addr,
  output reg                         cpu_mem_cmd_last,
  output reg                         cpu_mem_wdata_valid,
  input  wire                        cpu_mem_wdata_ready,
  output reg  [CPU_DATA_WIDTH-1:0]   cpu_mem_wdata_data,
  output reg  [CPU_DATA_WIDTH/8-1:0] cpu_mem_wdata_we,
  input  wire                        cpu_mem_rdata_valid,
  output reg                         cpu_mem_rdata_ready,
  input  wire [CPU_DATA_WIDTH-1:0]   cpu_mem_rdata_data,

  // NES PPU LiteDRAM Native Port
  output reg                         ppu_mem_cmd_valid,
  input  wire                        ppu_mem_cmd_ready,
  output reg                         ppu_mem_cmd_we,
  output reg  [PPU_ADDR_WIDTH-1:0]   ppu_mem_cmd_addr,
  output reg                         ppu_mem_cmd_last,
  output reg                         ppu_mem_wdata_valid,
  input  wire                        ppu_mem_wdata_ready,
  output reg  [PPU_DATA_WIDTH-1:0]   ppu_mem_wdata_data,
  output reg  [PPU_DATA_WIDTH/8-1:0] ppu_mem_wdata_we,
  input  wire                        ppu_mem_rdata_valid,
  output reg                         ppu_mem_rdata_ready,
  input  wire [PPU_DATA_WIDTH-1:0]   ppu_mem_rdata_data,

  // NES control
  input wire [63:0] mapper_flags,
  input wire        nes_reset,

  // Debug: last SDRAM addresses
  output reg  [CPU_ADDR_WIDTH-1:0] cpu_last_addr,
  output reg  [PPU_ADDR_WIDTH-1:0] ppu_last_addr,

  // Debug: last SDRAM data read
  output reg  [CPU_DATA_WIDTH-1:0] cpu_last_data,
  output reg  [PPU_DATA_WIDTH-1:0] ppu_last_data,

  // LEDs
  output wire [4:0] leds,

  // ROM rotator IRQ
  output reg next_rom_irq,
  output reg previous_rom_irq,
  output reg reset_rom_irq,

  // TMDS
  input  wire       tmds_clk,
  input  wire       tmds_rst,
  output wire [9:0] tmds_0,
  output wire [9:0] tmds_1,
  output wire [9:0] tmds_2,

  // USB
  input  wire       usb_clk,
  input  wire       usb_rst,
  output wire       usb_pullup_dp_0,
  output wire       usb_pullup_dn_0,
  output wire       usb_pullup_dp_1,
  output wire       usb_pullup_dn_1,
  inout  wire       usb_dp_0,
  inout  wire       usb_dn_0,
  inout  wire       usb_dp_1,
  inout  wire       usb_dn_1
);

localparam integer SYS_CLK_FREQ = 50000;
localparam integer NES_CLK_FREQ = 21487;  // adjusted to match hsync with hdmi framebuffer

localparam integer NES_CLOCK_COUNTER_WIDTH = $clog2(SYS_CLK_FREQ + NES_CLK_FREQ + 1);

wire nes_clock_en;
wire nes_en;

wire cpu_ce;
wire ppu_ce;

wire stall;

reg cpu_mem_busy;
reg ppu_mem_busy;

reg cpu_mem_ready;
reg ppu_mem_ready;

reg [NES_CLOCK_COUNTER_WIDTH-1:0] nes_clock_counter;

reg [7:0] nes_lost_ticks;

assign stall = ((cpu_mem_pending || cpu_ce) && !cpu_mem_ready) || ((ppu_mem_pending || ppu_ce) && !ppu_mem_ready);

assign nes_clock_en = nes_clock_counter >= SYS_CLK_FREQ;
assign nes_en       = (nes_clock_en || nes_lost_ticks != 0) && !stall;

always @(posedge clk) begin
  if (rst || nes_reset) begin
    nes_clock_counter <= 0;

  end else begin
    nes_clock_counter <= nes_clock_counter + NES_CLK_FREQ;

    if (nes_clock_en)
      nes_clock_counter <= nes_clock_counter + NES_CLK_FREQ - SYS_CLK_FREQ;
  end
end

always @(posedge clk) begin
  if (rst || nes_reset) begin
    nes_lost_ticks <= 0;

  end else if (nes_clock_en) begin
    if (stall && !(&nes_lost_ticks))
      nes_lost_ticks <= nes_lost_ticks + 1;

  end else begin
    if (!stall && nes_lost_ticks != 0)
      nes_lost_ticks <= nes_lost_ticks - 1;

  end
end

wire [5:0] color;
wire [8:0] scanline;
wire [8:0] cycle;

wire [21:0] cpumem_addr;
wire        cpumem_read;
wire        cpumem_write;
wire  [7:0] cpumem_dout;

wire [21:0] ppumem_addr;
wire        ppumem_read;
wire        ppumem_write;
wire  [7:0] ppumem_dout;

wire [2:0] joypad_out;
wire       joypad_strobe = joypad_out[0];
wire [1:0] joypad_clock;
wire [4:0] joypad1_data;
wire [4:0] joypad2_data;

wire cpu_mem_pending;
wire ppu_mem_pending;

wire  [9:0] cx;
wire  [9:0] cy;
wire [23:0] rgb;

wire [15:0] audio_sample;

wire int_audio;
wire ext_audio;

reg [7:0] cpumem_din;
reg [7:0] cpumem_din_r;

reg [7:0] ppumem_din;
reg [7:0] ppumem_din_r;

reg cpumem_read_r;
reg cpumem_write_r;

reg ppumem_read_r;
reg ppumem_write_r;

assign cpu_mem_pending = (cpumem_read && !cpumem_read_r) || (cpumem_write && !cpumem_write_r);
assign ppu_mem_pending = (ppumem_read && !ppumem_read_r) || (ppumem_write && !ppumem_write_r);

assign int_audio = 1;  // for VCR6
assign ext_audio = (mapper_flags[7:0] == 19) || (mapper_flags[7:0] == 24) || (mapper_flags[7:0] == 26);

NES nes_0 (
  .clk(clk),
  .enable(nes_en),
  .reset(nes_reset),
  .cpumem_addr(cpumem_addr),
  .cpumem_read(cpumem_read),
  .cpumem_write(cpumem_write),
  .cpumem_dout(cpumem_dout),
  .cpumem_din(cpumem_din),
  .ppumem_addr(ppumem_addr),
  .ppumem_read(ppumem_read),
  .ppumem_write(ppumem_write),
  .ppumem_dout(ppumem_dout),
  .ppumem_din(ppumem_din),
  .mapper_flags(mapper_flags),
  .color(color),
  .emphasis(),
  .scanline(scanline),
  .cycle(cycle),
  .cpu_ce(cpu_ce),
  .ppu_ce(ppu_ce),
  .joypad_out(joypad_out),
  .joypad_clock(joypad_clock),
  .joypad1_data(joypad1_data),
  .joypad2_data(joypad2_data),
  .sample(audio_sample),
  .audio_channels(5'b11111),
  .mask(2'b11),
  .int_audio(int_audio),
  .ext_audio(ext_audio),
  .vblank(),
  .hblank()
);

always @(*) begin
  cpu_mem_cmd_last = 1'b1;
  ppu_mem_cmd_last = 1'b1;

  cpu_mem_wdata_we = 1'b1;
  ppu_mem_wdata_we = 1'b1;

  cpu_mem_busy = cpu_mem_cmd_valid || cpu_mem_wdata_valid || cpu_mem_rdata_ready;
  ppu_mem_busy = ppu_mem_cmd_valid || ppu_mem_wdata_valid || ppu_mem_rdata_ready;

  cpu_mem_ready = (cpu_mem_rdata_ready && cpu_mem_rdata_valid) || !cpu_mem_busy;
  ppu_mem_ready = (ppu_mem_rdata_ready && ppu_mem_rdata_valid) || !ppu_mem_busy;

  cpumem_din = (cpu_mem_rdata_ready && cpu_mem_rdata_valid) ? cpu_mem_rdata_data : cpumem_din_r;
  ppumem_din = (ppu_mem_rdata_ready && ppu_mem_rdata_valid) ? ppu_mem_rdata_data : ppumem_din_r;
end

always @(posedge clk) begin
  if (rst) begin
    cpumem_read_r       <= 1'b0;
    cpumem_write_r      <= 1'b0;
    cpu_mem_cmd_valid   <= 1'b0;
    cpu_mem_wdata_valid <= 1'b0;
    cpu_mem_rdata_ready <= 1'b0;

    ppumem_read_r       <= 1'b0;
    ppumem_write_r      <= 1'b0;
    ppu_mem_cmd_valid   <= 1'b0;
    ppu_mem_wdata_valid <= 1'b0;
    ppu_mem_rdata_ready <= 1'b0;

  end else begin
    if (!cpu_mem_pending || !cpu_mem_busy) begin
      cpumem_read_r  <= cpumem_read;
      cpumem_write_r <= cpumem_write;
    end

    if (cpu_mem_busy) begin
      if (cpu_mem_wdata_ready)
        cpu_mem_wdata_valid <= 1'b0;

      if (cpu_mem_rdata_valid) begin
        cpu_mem_rdata_ready <= 1'b0;

        cpumem_din_r  <= cpu_mem_rdata_data;
        cpu_last_addr <= cpu_mem_cmd_addr;
        cpu_last_data <= cpu_mem_rdata_data;
      end

      if (cpu_mem_cmd_ready)
        cpu_mem_cmd_valid <= 1'b0;

    end else if (cpu_mem_pending) begin
      cpu_mem_cmd_valid <= 1'b1;

      cpu_mem_rdata_ready <= cpumem_read;
      cpu_mem_cmd_addr    <= {1'b0, cpumem_addr[21:10], CPU_ADDR_BANK[1:0], cpumem_addr[9:0]};
      cpu_mem_cmd_we      <= cpumem_write;
      cpu_mem_wdata_data  <= cpumem_dout;
      cpu_mem_wdata_valid <= cpumem_write;
    end

    if (!ppu_mem_pending || !ppu_mem_busy) begin
      ppumem_read_r  <= ppumem_read;
      ppumem_write_r <= ppumem_write;
    end

    if (ppu_mem_busy) begin
      if (ppu_mem_wdata_ready)
        ppu_mem_wdata_valid <= 1'b0;

      if (ppu_mem_rdata_valid) begin
        ppu_mem_rdata_ready <= 1'b0;

        ppumem_din_r  <= ppu_mem_rdata_data;
        ppu_last_addr <= ppu_mem_cmd_addr;
        ppu_last_data <= ppu_mem_rdata_data;
      end

      if (ppu_mem_cmd_ready)
        ppu_mem_cmd_valid <= 1'b0;

    end else if (ppu_mem_pending) begin
      ppu_mem_cmd_valid <= 1'b1;

      ppu_mem_rdata_ready <= ppumem_read;
      ppu_mem_cmd_addr    <= {1'b0, ppumem_addr[21:10], PPU_ADDR_BANK[1:0], ppumem_addr[9:0]};
      ppu_mem_cmd_we      <= ppumem_write;
      ppu_mem_wdata_data  <= ppumem_dout;
      ppu_mem_wdata_valid <= ppumem_write;
    end
  end
end

framebuffer framebuffer_0 (
  .clk(clk),
  .enable(ppu_ce && nes_en),
  .color(color),
  .cycle(cycle),
  .scanline(scanline),
  .clk_pixel(tmds_clk),
  .cx(cx),
  .cy(cy),
  .rgb(rgb)
);

wire        [15:0] audio_sample_tmds;
wire signed [16:0] audio_sample_tmds_signed;
wire               audio_sample_tmds_valid;
wire               audio_sample_tmds_ack;
wire               audio_sample_tmds_en;

cdc_handshake #(
  .WIDTH(16),
  .EXTERNAL_ACK(1)
) audio_cdc (
  .clk_src(clk),
  .rst_src(rst),
  .data_in(audio_sample),
  .send(1'b1),
  .busy(),
  .clk_dst(tmds_clk),
  .rst_dst(tmds_rst),
  .data_out(audio_sample_tmds),
  .valid(audio_sample_tmds_valid),
  .ack_in(audio_sample_tmds_ack)
);

// normalize to signed integer
assign audio_sample_tmds_signed = $signed({1'b0, audio_sample_tmds}) - $signed({1'b0, 16'h7fff});

wire signed [17:0] audio_sample_tmds_dc_blocked;
wire               audio_sample_tmds_dc_valid;
wire               audio_sample_tmds_dc_ready;

dc_blocker dc_blocker_0 (
  .clk(tmds_clk),
  .reset(tmds_rst),
  .in_valid(audio_sample_tmds_valid),
  .in_ready(audio_sample_tmds_ack),
  .out_ready(audio_sample_tmds_dc_ready),
  .out_valid(audio_sample_tmds_dc_valid),
  .in({audio_sample_tmds_signed, 1'b0}),
  .out(audio_sample_tmds_dc_blocked)
);

wire signed [17:0] audio_sample_tmds_filtered;

// 20kHz LPF
iir_biquad iir_biquad_0 (
  .clk(tmds_clk),
  .reset(tmds_rst),
  .in_ready(audio_sample_tmds_dc_ready),
  .in_valid(audio_sample_tmds_dc_valid),
  .out_ready(audio_sample_tmds_en),
  .out_valid(),
  .in(audio_sample_tmds_dc_blocked),
  .out(audio_sample_tmds_filtered)
);

hdmi #(
  .VENDOR_NAME(64'h4e45530000000000),  // NES
  .PRODUCT_DESCRIPTION(128'h4e455300000000000000000000000000),  // NES
  .SOURCE_DEVICE_INFORMATION(8'h08)  // Game
) hdmi_0 (
  .clk_pixel(tmds_clk),
  .reset(tmds_rst),
  .rgb(rgb),
  .audio_sample_word_0({audio_sample_tmds_filtered, 6'b0}),
  .audio_sample_word_1({audio_sample_tmds_filtered, 6'b0}),
  .audio_sample_en(audio_sample_tmds_en),
  .cx(cx),
  .cy(cy),
  .tmds_0(tmds_0),
  .tmds_1(tmds_1),
  .tmds_2(tmds_2),
  .hblank(),
  .vblank()
);

wire usb_dm_i [0:1];
wire usb_dp_i [0:1];
wire usb_dm_o [0:1];
wire usb_dp_o [0:1];

wire usb_oe [0:1];

assign usb_pullup_dp_0 = 1'b0;
assign usb_pullup_dn_0 = 1'b0;
assign usb_pullup_dp_1 = 1'b0;
assign usb_pullup_dn_1 = 1'b0;

assign usb_dm_i[0] = usb_dn_0;
assign usb_dp_i[0] = usb_dp_0;
assign usb_dm_i[1] = usb_dn_1;
assign usb_dp_i[1] = usb_dp_1;

assign usb_dn_0 = usb_oe[0] ? usb_dm_o[0] : 1'bz;
assign usb_dp_0 = usb_oe[0] ? usb_dp_o[0] : 1'bz;
assign usb_dn_1 = usb_oe[1] ? usb_dm_o[1] : 1'bz;
assign usb_dp_1 = usb_oe[1] ? usb_dp_o[1] : 1'bz;

wire game_l_usb [0:1];
wire game_r_usb [0:1];
wire game_u_usb [0:1];
wire game_d_usb [0:1];
wire game_a_usb [0:1];
wire game_b_usb [0:1];
wire game_x_usb [0:1];
wire game_y_usb [0:1];

wire game_sel_usb [0:1];
wire game_sta_usb [0:1];

wire [3:0] game_extra_usb [0:1];

wire [3:0] usb_rom_dout [0:1];
wire [9:0] usb_rom_addr [0:1];
wire       usb_rom_en   [0:1];

wire       usb_full_report [0:1];
wire [1:0] usb_typ         [0:1];

wire [1:0] typ [0:1];

usb_hid_host_dual_rom #(
  .MEMORY_FILE("../rom/usb_hid_host_rom.mem")
) usb_hid_host_dual_rom_0 (
  .clk(usb_clk),
  .ena(usb_rom_en[0]),
  .addra(usb_rom_addr[0]),
  .douta(usb_rom_dout[0]),
  .enb(usb_rom_en[1]),
  .addrb(usb_rom_addr[1]),
  .doutb(usb_rom_dout[1])
);

usb_hid_host #(
  .FULL_SPEED(1),
  .KEYBOARD_SUPPORT(0),
  .MOUSE_SUPPORT(0),
  .GAME_SUPPORT(1)
) usb_hid_0 (
  .clk(usb_clk),
  .reset(usb_rst),
  .cs(1),
  .usb_dm_i(usb_dm_i[0]),
  .usb_dp_i(usb_dp_i[0]),
  .usb_dm_o(usb_dm_o[0]),
  .usb_dp_o(usb_dp_o[0]),
  .usb_oe(usb_oe[0]),
  .typ(usb_typ[0]),
  .rom_addr(usb_rom_addr[0]),
  .rom_dout(usb_rom_dout[0]),
  .rom_en(usb_rom_en[0]),
  .full_report(usb_full_report[0]),
  .game_l(game_l_usb[0]),
  .game_r(game_r_usb[0]),
  .game_u(game_u_usb[0]),
  .game_d(game_d_usb[0]),
  .game_a(game_a_usb[0]),
  .game_b(game_b_usb[0]),
  .game_x(game_x_usb[0]),
  .game_y(game_y_usb[0]),
  .game_sel(game_sel_usb[0]),
  .game_sta(game_sta_usb[0]),
  .game_extra(game_extra_usb[0])
);

usb_hid_host #(
  .FULL_SPEED(1),
  .KEYBOARD_SUPPORT(0),
  .MOUSE_SUPPORT(0),
  .GAME_SUPPORT(1)
) usb_hid_1 (
  .clk(usb_clk),
  .reset(usb_rst),
  .cs(1),
  .usb_dm_i(usb_dm_i[1]),
  .usb_dp_i(usb_dp_i[1]),
  .usb_dm_o(usb_dm_o[1]),
  .usb_dp_o(usb_dp_o[1]),
  .usb_oe(usb_oe[1]),
  .typ(usb_typ[1]),
  .rom_addr(usb_rom_addr[1]),
  .rom_dout(usb_rom_dout[1]),
  .rom_en(usb_rom_en[1]),
  .full_report(usb_full_report[1]),
  .game_l(game_l_usb[1]),
  .game_r(game_r_usb[1]),
  .game_u(game_u_usb[1]),
  .game_d(game_d_usb[1]),
  .game_a(game_a_usb[1]),
  .game_b(game_b_usb[1]),
  .game_x(game_x_usb[1]),
  .game_y(game_y_usb[1]),
  .game_sel(game_sel_usb[1]),
  .game_sta(game_sta_usb[1]),
  .game_extra(game_extra_usb[1])
);

wire [9:0] game [0:1];

reg [1:0] joypad_clock_r;
reg [7:0] joypad_bits [0:1];

cdc_sync #(
  .N(4)
) cdc_typ_0 (
  .clk_dst(clk),
  .rst_dst(rst),
  .in({usb_typ[1], usb_typ[0]}),
  .out({typ[1], typ[0]})
);

cdc_handshake #(
  .WIDTH(10)
) cdc_game_0 (
  .clk_src(usb_clk),
  .rst_src(usb_rst),
  .data_in({game_y_usb[0], game_x_usb[0], game_r_usb[0], game_l_usb[0],
            game_d_usb[0], game_u_usb[0], game_sta_usb[0], game_sel_usb[0],
            game_b_usb[0] || (|game_extra_usb[0][3:2]), game_a_usb[0] || |(game_extra_usb[0][1:0])}),
  .send(usb_full_report[0]),
  .busy(),
  .clk_dst(clk),
  .rst_dst(rst),
  .data_out(game[0]),
  .valid()
);

cdc_handshake #(
  .WIDTH(10)
) cdc_game_1 (
  .clk_src(usb_clk),
  .rst_src(usb_rst),
  .data_in({game_y_usb[1], game_x_usb[1], game_r_usb[1], game_l_usb[1],
            game_d_usb[1], game_u_usb[1], game_sta_usb[1], game_sel_usb[1],
            game_b_usb[1] || (|game_extra_usb[1][3:2]), game_a_usb[0] || (|game_extra_usb[1][1:0])}),
  .send(usb_full_report[1]),
  .busy(),
  .clk_dst(clk),
  .rst_dst(rst),
  .data_out(game[1]),
  .valid()
);

wire extra_sel_0 = (game[0][8] && game[0][9] && game[0][0]);  // A + X + Y
wire extra_sta_0 = (game[0][8] && game[0][9] && game[0][1]);  // B + X + Y

wire extra_sel_1 = (game[1][8] && game[1][9] && game[1][0]);  // A + X + Y
wire extra_sta_1 = (game[1][8] && game[1][9] && game[1][1]);  // B + X + Y

always @(posedge clk) begin
  if (rst || nes_reset) begin
    joypad_bits[0] <= 8'b0;
    joypad_bits[0] <= 8'b0;

    joypad_clock_r <= 2'b0;
  end else begin
    if (typ[0] != 2'b11)
      joypad_bits[0] <= 8'b0;
    else if (joypad_strobe)
      joypad_bits[0] <= (extra_sta_0 || extra_sel_0) ?
        {4'b0, extra_sta_0, extra_sel_0, 2'b0} : game[0][7:0];

    if (typ[1] != 2'b11)
      joypad_bits[1] <= 8'b0;
    else if (joypad_strobe)
      joypad_bits[1] <= (extra_sta_1 || extra_sel_1) ?
        {4'b0, extra_sta_1, extra_sel_1, 2'b0} : game[1][7:0];

    if (!joypad_clock[0] && joypad_clock_r[0])
      joypad_bits[0] <= {1'b0, joypad_bits[0][7:1]};

    if (!joypad_clock[1] && joypad_clock_r[1])
      joypad_bits[1] <= {1'b0, joypad_bits[1][7:1]};

    joypad_clock_r <= joypad_clock;
  end
end

assign joypad1_data = {4'b0, joypad_bits[0][0]};
assign joypad2_data = {4'b0, joypad_bits[1][0]};

wire next_rom_trigger =
  (game[0][8] && game[0][9] && game[0][5]) ||  // DOWN + X + Y
  (game[1][8] && game[1][9] && game[1][5]);    // DOWN + X + Y

wire previous_rom_trigger =
  (game[0][8] && game[0][9] && game[0][4]) ||  // UP + X + Y
  (game[1][8] && game[1][9] && game[1][4]);    // UP + X + Y

wire reset_rom_trigger =
  (game[0][0] && game[0][1] && game[0][8] && game[0][9]) ||  // X + Y + A + B
  (game[1][0] && game[1][1] && game[1][8] && game[1][9]);    // X + Y + A + B

reg next_rom_trigger_r;
reg previous_rom_trigger_r;
reg reset_rom_trigger_r;

always @(posedge clk) begin
  if (rst) begin
    next_rom_irq     <= 1'b0;
    previous_rom_irq <= 1'b0;
    reset_rom_irq    <= 1'b0;

    next_rom_trigger_r     <= 1'b0;
    previous_rom_trigger_r <= 1'b0;
    reset_rom_trigger_r    <= 1'b0;

  end else begin
    next_rom_irq       <= next_rom_trigger && !next_rom_trigger_r;
    next_rom_trigger_r <= next_rom_trigger;

    previous_rom_irq       <= previous_rom_trigger && !previous_rom_trigger_r;
    previous_rom_trigger_r <= previous_rom_trigger;

    reset_rom_irq       <= reset_rom_trigger && !reset_rom_trigger_r;
    reset_rom_trigger_r <= reset_rom_trigger;
  end
end

assign leds = {&(nes_lost_ticks), usb_oe[1], usb_oe[0], 1'b0, 1'b0};

endmodule
`default_nettype wire
// vim:ts=2 sw=2 tw=120 et
