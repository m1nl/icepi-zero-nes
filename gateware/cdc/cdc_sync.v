`default_nettype none
`timescale 1 ns / 1 ps

module cdc_sync #(
    parameter N = 1
) (
    input  wire         clk_dst,
    input  wire         rst_dst,
    input  wire [N-1:0] in,
    output wire [N-1:0] out
);

(* ASYNC_REG = "TRUE" *) reg [N-1:0] stage1;
(* ASYNC_REG = "TRUE" *) reg [N-1:0] stage2;

always @(posedge clk_dst or posedge rst_dst) begin
    if (rst_dst) begin
        stage1 <= {N{1'b0}};
        stage2 <= {N{1'b0}};
    end else begin
        stage1 <= in;
        stage2 <= stage1;
    end
end

assign out = stage2;

endmodule
