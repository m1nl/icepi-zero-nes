`default_nettype none
`timescale 1 ns / 1 ps
module framebuffer(
  input wire       clk,
  input wire       enable,
  input wire [5:0] color,
  input wire [8:0] cycle,
  input wire [8:0] scanline,

  input  wire        clk_pixel,
  input  wire  [9:0] cx,
  input  wire  [9:0] cy,
  output wire [23:0] rgb
);

reg  [5:0] mem [0:256 * 240 - 1];
reg [23:0] palette_lut [0:63];

wire        ena;
wire [15:0] offset;
wire  [7:0] offset_round;
wire [15:0] addra;

reg        ena_r [0:1];
reg  [9:0] cy_r  [0:1];
reg [15:0] offset_r;

reg        jitter;

reg [5:0]  dout;
reg        dout_valid;

assign ena    = cx > 35 && cx <= 675 && cy < 480;
assign offset = (cx - (jitter ? 34 : 35)) * 102;

always @(posedge clk_pixel) begin
  ena_r[0] <= ena;
  ena_r[1] <= ena_r[0];

  cy_r[0] <= cy;
  cy_r[1] <= cy_r[0];

  offset_r <= offset;

  if (cx == 675)
    jitter <= !jitter;
end

util_convround #(
  .IWID(16),
  .OWID(8),
  .SHIFT(0)
) offset_round_0 (
  .i_clk(clk),
  .i_ce(ena[0]),
  .i_val(offset_r),
  .o_val(offset_round)
);

assign addra  = {1'b0, cy_r[1][8:1], 8'b0} + {8'b0, offset_round};

always @(posedge clk_pixel) begin
  if (ena_r[1])
    dout <= mem[addra];

  dout_valid <= ena_r[1];
end

reg [7:0] ro, go, bo;

always @(posedge clk_pixel) begin
  {ro, go, bo} <= palette_lut[dout_valid ? dout : 63];
end

assign rgb = {ro, go, bo};

wire [15:0] addrb;
wire        enb;

reg        enb_r;
reg [15:0] addrb_r;
reg [5:0]  color_r;

assign addrb = {scanline, 8'b0} + {8'b0, cycle};
assign enb   = scanline < 240 && cycle < 256 && enable;

always @(posedge clk) begin
  enb_r   <= enb;
  addrb_r <= addrb;
  color_r <= color;
end

always @(posedge clk) begin
  if (enb_r)
    mem[addrb_r] <= color_r;
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

endmodule
`default_nettype wire
// vim:ts=2 sw=2 tw=120 et
