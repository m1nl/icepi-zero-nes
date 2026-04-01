`default_nettype none
`timescale 1 ns / 1 ps
module iir_biquad (
    input  wire clk,
    input  wire reset,
    input  wire in_valid,
    output wire in_ready,
    input  wire out_ready,
    output reg  out_valid,

    input  wire signed [17:0] in,
    output reg signed [17:0] out
);

// Coefficients in Q4.14 format
// butter(2, (20 / (48/2)), 'low')
parameter signed [17:0] b0 = 18'sd11294;
parameter signed [17:0] b1 = 18'sd22587;
parameter signed [17:0] b2 = 18'sd11294;

parameter signed [17:0] a1 = 18'sd20965;
parameter signed [17:0] a2 = 18'sd7825;

// History registers
reg signed [17:0] x1, x2;
reg signed [17:0] y1, y2;

// Registered input sample
reg signed [17:0] x0;

// 38-bit accumulator: 2 guard bits above the 36-bit product to absorb 5-term sum
reg signed [37:0] acc;

// FSM state (0-5)
reg [2:0] state;

assign in_ready = (state == 3'd0) && (out_ready || !out_valid);

// Combinational multiplier
reg signed [17:0] mul_a, mul_b;
wire signed [35:0] mul_out = mul_a * mul_b;
wire signed [37:0] mul_out_ext = {{2{mul_out[35]}}, mul_out};

// Final accumulator value for state 5 (acc - y2*a2)
wire signed [37:0] acc_final = acc - mul_out_ext;

always @(*) begin
    case (state)
        3'd1:    begin mul_a = x0; mul_b = b0; end
        3'd2:    begin mul_a = x1; mul_b = b1; end
        3'd3:    begin mul_a = x2; mul_b = b2; end
        3'd4:    begin mul_a = y1; mul_b = a1; end
        3'd5:    begin mul_a = y2; mul_b = a2; end
        default: begin mul_a = 18'sdx; mul_b = 18'sdx; end
    endcase
end

always @(posedge clk) begin
    if (reset) begin
        x0 <= 0;
        x1 <= 0; x2 <= 0;
        y1 <= 0; y2 <= 0;
        out <= 0;
        acc <= 0;
        state <= 0;
        out_valid <= 1'b0;
    end else begin
        case (state)
            3'd0: begin
                if (in_valid && in_ready) begin
                    x0 <= in;
                    out_valid <= 1'b0;
                    state <= 3'd1;
                end
            end
            3'd1: begin
                acc   <= mul_out_ext;        // x0*b0
                state <= 3'd2;
            end
            3'd2: begin
                acc   <= acc + mul_out_ext;  // + x1*b1
                state <= 3'd3;
            end
            3'd3: begin
                acc   <= acc + mul_out_ext;  // + x2*b2
                state <= 3'd4;
            end
            3'd4: begin
                acc   <= acc - mul_out_ext;  // - y1*a1
                state <= 3'd5;
            end
            3'd5: begin
                // acc_final = acc - y2*a2  (combinational, avoids extra cycle)
                // input Q2.15 * coeff Q4.14 = Q6.29 (36-bit); bits [32:15] -> 18-bit Q2.15 output
                out <= acc_final[32:15];

                x2 <= x1;
                x1 <= x0;
                y2 <= y1;
                y1 <= acc_final[32:15];

                state     <= 3'd0;
                out_valid <= 1'b1;
            end
            default:
                state <= 3'd0;
        endcase
    end
end

endmodule
`default_nettype wire
