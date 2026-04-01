`default_nettype none
`timescale 1 ns / 1 ps

module cdc_sync_gray #(
    parameter N = 3
) (
    input  wire         clk_src,
    input  wire         clk_dst,
    input  wire [N-1:0] in,
    output wire [N-1:0] out
);

wire [N-1:0] in_gray;
assign in_gray = in ^ (in >> 1);

(* ASYNC_REG = "TRUE" *) reg [N-1:0] stage1;
(* ASYNC_REG = "TRUE" *) reg [N-1:0] stage2;

always @(posedge clk_dst) begin
    stage1 <= in_gray;
    stage2 <= stage1;
end

genvar i;
generate
    assign out[N-1] = stage2[N-1];
    for (i = N-2; i >= 0; i = i - 1) begin : gray_decode
        assign out[i] = out[i+1] ^ stage2[i];
    end
endgenerate

endmodule
