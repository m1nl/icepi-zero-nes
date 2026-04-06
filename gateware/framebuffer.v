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
module framebuffer (
  input wire       clk,
  input wire       enable,
  input wire [5:0] color,
  input wire [8:0] cycle,
  input wire [8:0] scanline,

  input  wire        clk_pixel,
  input  wire  [9:0] cx,
  input  wire  [9:0] cy,
  output reg  [23:0] rgb
);

localparam PIPELINE_DELAY = 4;

wire ena;

reg  [5:0] mem [0:256 * 240 - 1];
reg [23:0] palette_lut  [0:63];
reg  [1:0] palette_luma [0:63];

reg  [3:0] ena_r;
reg  [9:0] cy_r;
reg  [7:0] offset;
reg  [1:0] counter;

assign ena = cx >= (39 - PIPELINE_DELAY) && cx < (679 - PIPELINE_DELAY) && cy < 480;

// 0

// 1 : 2.5 scaler

always @(posedge clk_pixel) begin
  if (ena && !ena_r[0]) begin
    offset  <= 0;
    counter <= 2;
  end else if (counter != 0)
    counter <= counter - 1;
  else begin
    offset  <= offset + 1;
    counter <= offset[0] ? 2 : 1;
  end

  ena_r <= {ena_r[2:0], ena};
  cy_r  <= cy;
end

// 1

wire [15:0] addra;

reg [5:0] dout;

assign addra = {cy_r[8:1], offset};

always @(posedge clk_pixel) begin
  if (ena_r[0])
    dout <= mem[addra];
end

// 2

reg [7:0] ri, gi, bi;
reg [7:0] rir, gir, bir;

reg [1:0] luma;
reg [1:0] luma_r;

always @(posedge clk_pixel) begin
  {ri,  gi,  bi}  <= palette_lut[ena_r[1] ? dout : 63];
  {rir, gir, bir} <= {ri, gi, bi};

  luma   <= palette_luma[dout];
  luma_r <= luma;
end

// 3

reg [7:0] ro, go, bo;

reg sol, eol;

reg signed [2:0] blend;

always @(*) begin
  sol = ena_r[2] && !ena_r[3];
  eol = ena_r[2] && !ena_r[1];

  blend = (sol || eol) ? 0 : $signed({1'b0, luma}) - $signed({1'b0, luma_r});
end

always @(posedge clk_pixel) begin
  case (blend)
    -3: begin
      ro <= rir - {1'b0, rir[7:1]};
      go <= gir - {1'b0, gir[7:1]};
      bo <= bir - {1'b0, bir[7:1]};
    end
    -2: begin
      ro <= rir - {2'b0, rir[7:2]};
      go <= gir - {2'b0, gir[7:2]};
      bo <= bir - {2'b0, bir[7:2]};
    end
    -1: begin
      ro <= rir - {3'b0, rir[7:3]};
      go <= gir - {3'b0, gir[7:3]};
      bo <= bir - {3'b0, bir[7:3]};
    end
    3: begin
      ro <= ri - {1'b0, ri[7:1]};
      go <= gi - {1'b0, gi[7:1]};
      bo <= bi - {1'b0, bi[7:1]};
    end
    2: begin
      ro <= ri - {2'b0, ri[7:2]};
      go <= gi - {2'b0, gi[7:2]};
      bo <= bi - {2'b0, bi[7:2]};
    end
    1: begin
      ro <= ri - {3'b0, ri[7:3]};
      go <= gi - {3'b0, gi[7:3]};
      bo <= bi - {3'b0, bi[7:3]};
    end
    default: begin
      ro <= ri;
      go <= gi;
      bo <= bi;
    end
  endcase
end

// 4

always @(posedge clk_pixel)
  rgb <= {ro, go, bo};

wire [15:0] addrb;
wire        enb;

assign enb   = scanline < 240 && cycle < 256 && enable;
assign addrb = {scanline[7:0], cycle[7:0]};

always @(posedge clk) begin
  if (enb)
    mem[addrb] <= color;
end

// Sony CXA by FirebrandX

initial begin
  palette_lut[ 0] = 24'h585858; palette_lut[ 1] = 24'h00238C;
  palette_lut[ 2] = 24'h00139B; palette_lut[ 3] = 24'h2D0585;
  palette_lut[ 4] = 24'h5D0052; palette_lut[ 5] = 24'h7A0017;
  palette_lut[ 6] = 24'h7A0800; palette_lut[ 7] = 24'h5F1800;
  palette_lut[ 8] = 24'h352A00; palette_lut[ 9] = 24'h093900;
  palette_lut[10] = 24'h003F00; palette_lut[11] = 24'h003C22;
  palette_lut[12] = 24'h00325D; palette_lut[13] = 24'h000000;
  palette_lut[14] = 24'h000000; palette_lut[15] = 24'h000000;

  palette_lut[16] = 24'hA1A1A1; palette_lut[17] = 24'h0053EE;
  palette_lut[18] = 24'h153CFE; palette_lut[19] = 24'h6028E4;
  palette_lut[20] = 24'hA91D98; palette_lut[21] = 24'hD41E41;
  palette_lut[22] = 24'hD22C00; palette_lut[23] = 24'hAA4400;
  palette_lut[24] = 24'h6C5E00; palette_lut[25] = 24'h2D7300;
  palette_lut[26] = 24'h007D06; palette_lut[27] = 24'h007852;
  palette_lut[28] = 24'h0069A9; palette_lut[29] = 24'h000000;
  palette_lut[30] = 24'h000000; palette_lut[31] = 24'h000000;

  palette_lut[32] = 24'hFFFFFF; palette_lut[33] = 24'h1FA5FE;
  palette_lut[34] = 24'h5E89FE; palette_lut[35] = 24'hB572FE;
  palette_lut[36] = 24'hFE65F6; palette_lut[37] = 24'hFE6790;
  palette_lut[38] = 24'hFE773C; palette_lut[39] = 24'hFE9308;
  palette_lut[40] = 24'hC4B200; palette_lut[41] = 24'h79CA10;
  palette_lut[42] = 24'h3AD54A; palette_lut[43] = 24'h11D1A4;
  palette_lut[44] = 24'h06BFFE; palette_lut[45] = 24'h424242;
  palette_lut[46] = 24'h000000; palette_lut[47] = 24'h000000;

  palette_lut[48] = 24'hFFFFFF; palette_lut[49] = 24'hA0D9FE;
  palette_lut[50] = 24'hBDCCFE; palette_lut[51] = 24'hE1C2FE;
  palette_lut[52] = 24'hFEBCFB; palette_lut[53] = 24'hFEBDD0;
  palette_lut[54] = 24'hFEC5A9; palette_lut[55] = 24'hFED18E;
  palette_lut[56] = 24'hE9DE86; palette_lut[57] = 24'hC7E992;
  palette_lut[58] = 24'hA8EEB0; palette_lut[59] = 24'h95ECD9;
  palette_lut[60] = 24'h91E4FE; palette_lut[61] = 24'hACACAC;
  palette_lut[62] = 24'h000000; palette_lut[63] = 24'h000000;
end

// 0.75 (luma.py)
// [1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 2 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 3 2 2 2 2 2 2 2 2 2 2 2 2 1 0 0 3 2 2 2 2 2 2 2 2 2 2 2 2 2 0 0]

initial begin
  palette_luma[0] = 2'd1; palette_luma[1] = 2'd1;
  palette_luma[2] = 2'd1; palette_luma[3] = 2'd1;
  palette_luma[4] = 2'd1; palette_luma[5] = 2'd1;
  palette_luma[6] = 2'd1; palette_luma[7] = 2'd1;
  palette_luma[8] = 2'd1; palette_luma[9] = 2'd1;
  palette_luma[10] = 2'd1; palette_luma[11] = 2'd1;
  palette_luma[12] = 2'd1; palette_luma[13] = 2'd0;
  palette_luma[14] = 2'd0; palette_luma[15] = 2'd0;
  palette_luma[16] = 2'd2; palette_luma[17] = 2'd1;
  palette_luma[18] = 2'd1; palette_luma[19] = 2'd1;
  palette_luma[20] = 2'd1; palette_luma[21] = 2'd1;
  palette_luma[22] = 2'd1; palette_luma[23] = 2'd1;
  palette_luma[24] = 2'd1; palette_luma[25] = 2'd1;
  palette_luma[26] = 2'd1; palette_luma[27] = 2'd1;
  palette_luma[28] = 2'd1; palette_luma[29] = 2'd0;
  palette_luma[30] = 2'd0; palette_luma[31] = 2'd0;
  palette_luma[32] = 2'd3; palette_luma[33] = 2'd2;
  palette_luma[34] = 2'd2; palette_luma[35] = 2'd2;
  palette_luma[36] = 2'd2; palette_luma[37] = 2'd2;
  palette_luma[38] = 2'd2; palette_luma[39] = 2'd2;
  palette_luma[40] = 2'd2; palette_luma[41] = 2'd2;
  palette_luma[42] = 2'd2; palette_luma[43] = 2'd2;
  palette_luma[44] = 2'd2; palette_luma[45] = 2'd1;
  palette_luma[46] = 2'd0; palette_luma[47] = 2'd0;
  palette_luma[48] = 2'd3; palette_luma[49] = 2'd2;
  palette_luma[50] = 2'd2; palette_luma[51] = 2'd2;
  palette_luma[52] = 2'd2; palette_luma[53] = 2'd2;
  palette_luma[54] = 2'd2; palette_luma[55] = 2'd2;
  palette_luma[56] = 2'd2; palette_luma[57] = 2'd2;
  palette_luma[58] = 2'd2; palette_luma[59] = 2'd2;
  palette_luma[60] = 2'd2; palette_luma[61] = 2'd2;
  palette_luma[62] = 2'd0; palette_luma[63] = 2'd0;
end

endmodule
`default_nettype wire
// vim:ts=2 sw=2 tw=120 et
