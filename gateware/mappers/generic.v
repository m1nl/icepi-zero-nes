module MMC0 (
	clk,
	ce,
	enable,
	flags,
	prg_ain,
	prg_aout_b,
	prg_read,
	prg_write,
	prg_din,
	prg_dout_b,
	prg_allow_b,
	chr_ain,
	chr_aout_b,
	chr_read,
	chr_allow_b,
	vram_a10_b,
	vram_ce_b,
	irq_b,
	audio_in,
	audio_b,
	flags_out_b
);
	input clk;
	input ce;
	input enable;
	input [31:0] flags;
	input [15:0] prg_ain;
	inout [21:0] prg_aout_b;
	input prg_read;
	input prg_write;
	input [7:0] prg_din;
	inout [7:0] prg_dout_b;
	inout prg_allow_b;
	input [13:0] chr_ain;
	inout [21:0] chr_aout_b;
	input chr_read;
	inout chr_allow_b;
	inout vram_a10_b;
	inout vram_ce_b;
	inout irq_b;
	input [15:0] audio_in;
	inout [15:0] audio_b;
	inout [15:0] flags_out_b;
	wire [21:0] prg_aout;
	assign prg_aout_b = (enable ? prg_aout : 22'hzzzzzz);
	assign prg_dout_b = (enable ? 8'hff : 8'hzz);
	wire prg_allow;
	assign prg_allow_b = (enable ? prg_allow : 1'hz);
	wire [21:0] chr_aout;
	assign chr_aout_b = (enable ? chr_aout : 22'hzzzzzz);
	wire chr_allow;
	assign chr_allow_b = (enable ? chr_allow : 1'hz);
	wire vram_a10;
	assign vram_a10_b = (enable ? vram_a10 : 1'hz);
	wire vram_ce;
	assign vram_ce_b = (enable ? vram_ce : 1'hz);
	assign irq_b = (enable ? 1'b0 : 1'hz);
	reg [15:0] flags_out = 16'h0008;
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	assign prg_aout = {7'b0000000, prg_ain[14:0]};
	assign prg_allow = prg_ain[15] && !prg_write;
	assign chr_allow = flags[15];
	assign chr_aout = {9'b100000000, chr_ain[12:0]};
	assign vram_ce = chr_ain[13];
	assign vram_a10 = (flags[14] ? chr_ain[10] : chr_ain[11]);
endmodule
module Mapper13 (
	clk,
	ce,
	enable,
	flags,
	prg_ain,
	prg_aout_b,
	prg_read,
	prg_write,
	prg_din,
	prg_dout_b,
	prg_allow_b,
	chr_ain,
	chr_aout_b,
	chr_read,
	chr_allow_b,
	vram_a10_b,
	vram_ce_b,
	irq_b,
	audio_in,
	audio_b,
	flags_out_b
);
	input clk;
	input ce;
	input enable;
	input [31:0] flags;
	input [15:0] prg_ain;
	inout [21:0] prg_aout_b;
	input prg_read;
	input prg_write;
	input [7:0] prg_din;
	inout [7:0] prg_dout_b;
	inout prg_allow_b;
	input [13:0] chr_ain;
	inout [21:0] chr_aout_b;
	input chr_read;
	inout chr_allow_b;
	inout vram_a10_b;
	inout vram_ce_b;
	inout irq_b;
	input [15:0] audio_in;
	inout [15:0] audio_b;
	inout [15:0] flags_out_b;
	wire [21:0] prg_aout;
	assign prg_aout_b = (enable ? prg_aout : 22'hzzzzzz);
	assign prg_dout_b = (enable ? 8'hff : 8'hzz);
	wire prg_allow;
	assign prg_allow_b = (enable ? prg_allow : 1'hz);
	wire [21:0] chr_aout;
	assign chr_aout_b = (enable ? chr_aout : 22'hzzzzzz);
	wire chr_allow;
	assign chr_allow_b = (enable ? chr_allow : 1'hz);
	wire vram_a10;
	assign vram_a10_b = (enable ? vram_a10 : 1'hz);
	wire vram_ce;
	assign vram_ce_b = (enable ? vram_ce : 1'hz);
	assign irq_b = (enable ? 1'b0 : 1'hz);
	reg [15:0] flags_out = 0;
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	reg [1:0] chr_bank;
	always @(posedge clk)
		if (~enable)
			chr_bank <= 0;
		else if (ce) begin
			if (prg_ain[15] && prg_write)
				chr_bank <= prg_din[1:0];
		end
	assign prg_aout = {7'b0000000, prg_ain[14:0]};
	assign prg_allow = prg_ain[15] && !prg_write;
	assign chr_allow = flags[15];
	assign chr_aout = {8'b01000000, (chr_ain[12] ? chr_bank : 2'b00), chr_ain[11:0]};
	assign vram_ce = chr_ain[13];
	assign vram_a10 = (flags[14] ? chr_ain[10] : chr_ain[11]);
endmodule
module Mapper30 (
	clk,
	ce,
	enable,
	flags,
	prg_ain,
	prg_aout_b,
	prg_read,
	prg_write,
	prg_din,
	prg_dout_b,
	prg_allow_b,
	chr_ain,
	chr_aout_b,
	chr_read,
	chr_allow_b,
	vram_a10_b,
	vram_ce_b,
	irq_b,
	audio_in,
	audio_b,
	flags_out_b
);
	input clk;
	input ce;
	input enable;
	input [31:0] flags;
	input [15:0] prg_ain;
	inout [21:0] prg_aout_b;
	input prg_read;
	input prg_write;
	input [7:0] prg_din;
	inout [7:0] prg_dout_b;
	inout prg_allow_b;
	input [13:0] chr_ain;
	inout [21:0] chr_aout_b;
	input chr_read;
	inout chr_allow_b;
	inout vram_a10_b;
	inout vram_ce_b;
	inout irq_b;
	input [15:0] audio_in;
	inout [15:0] audio_b;
	inout [15:0] flags_out_b;
	wire [21:0] prg_aout;
	assign prg_aout_b = (enable ? prg_aout : 22'hzzzzzz);
	assign prg_dout_b = (enable ? 8'hff : 8'hzz);
	wire prg_allow;
	assign prg_allow_b = (enable ? prg_allow : 1'hz);
	wire [21:0] chr_aout;
	assign chr_aout_b = (enable ? chr_aout : 22'hzzzzzz);
	wire chr_allow;
	assign chr_allow_b = (enable ? chr_allow : 1'hz);
	reg vram_a10;
	assign vram_a10_b = (enable ? vram_a10 : 1'hz);
	wire vram_ce;
	assign vram_ce_b = (enable ? vram_ce : 1'hz);
	assign irq_b = (enable ? 1'b0 : 1'hz);
	wire battery = flags[25];
	wire [15:0] flags_out = {10'h000, battery, 5'b01000};
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	reg [4:0] prgbank;
	reg [1:0] chrbank;
	reg nametable;
	wire four_screen = flags[16] && flags[14];
	reg [1:0] write_state;
	localparam [1:0] STATE_IDLE = 2'b00;
	localparam [1:0] STATE_UNLOCK1 = 2'b01;
	localparam [1:0] STATE_UNLOCK2 = 2'b10;
	localparam [1:0] STATE_CMD = 2'b11;
	wire [14:0] prg_addr_15bit = {(prg_ain[15:14] == 2'b11 ? 1'b1 : prgbank[0]), prg_ain[13:0]};
	wire unlock1_match = prg_addr_15bit == 15'h5555;
	wire unlock2_match = prg_addr_15bit == 15'h2aaa;
	wire flash_write = ((write_state == STATE_CMD) && (prg_ain[15:14] == 2'b10)) && prg_write;
	always @(posedge clk)
		if (~enable) begin
			prgbank <= 0;
			chrbank <= 0;
			nametable <= 0;
			write_state <= STATE_IDLE;
		end
		else if (ce) begin
			if (prg_ain[15] && prg_write) begin
				if ((battery ? prg_ain[14] : 1'b1))
					{nametable, chrbank, prgbank} <= prg_din[7:0];
				else if (battery && !prg_ain[14])
					case (write_state)
						STATE_IDLE: write_state <= (unlock1_match && (prg_din == 8'haa) ? STATE_UNLOCK1 : STATE_IDLE);
						STATE_UNLOCK1: write_state <= (unlock2_match && (prg_din == 8'h55) ? STATE_UNLOCK2 : STATE_IDLE);
						STATE_UNLOCK2: write_state <= (unlock1_match && (prg_din == 8'ha0) ? STATE_CMD : STATE_IDLE);
						STATE_CMD: write_state <= STATE_IDLE;
					endcase
			end
		end
	always casez ({flags[16], flags[14]})
		3'b000: vram_a10 = chr_ain[11];
		3'b001: vram_a10 = chr_ain[10];
		3'b010: vram_a10 = nametable;
		default: vram_a10 = chr_ain[10];
	endcase
	assign prg_aout = {3'b000, (prg_ain[15:14] == 2'b11 ? 5'b11111 : prgbank), prg_ain[13:0]};
	assign prg_allow = prg_ain[15] && (!prg_write || flash_write);
	assign chr_allow = flags[15];
	assign chr_aout = {(flags[15] ? 7'b1111111 : 7'b1000000), (four_screen && chr_ain[13] ? 2'b11 : chrbank), chr_ain[12:0]};
	assign vram_ce = chr_ain[13] && !four_screen;
endmodule
module Mapper66 (
	clk,
	ce,
	enable,
	flags,
	prg_ain,
	prg_aout_b,
	prg_read,
	prg_write,
	prg_din,
	prg_dout_b,
	prg_allow_b,
	chr_ain,
	chr_aout_b,
	chr_read,
	chr_allow_b,
	vram_a10_b,
	vram_ce_b,
	irq_b,
	audio_in,
	audio_b,
	flags_out_b
);
	input clk;
	input ce;
	input enable;
	input [31:0] flags;
	input [15:0] prg_ain;
	inout [21:0] prg_aout_b;
	input prg_read;
	input prg_write;
	input [7:0] prg_din;
	inout [7:0] prg_dout_b;
	inout prg_allow_b;
	input [13:0] chr_ain;
	inout [21:0] chr_aout_b;
	input chr_read;
	inout chr_allow_b;
	inout vram_a10_b;
	inout vram_ce_b;
	inout irq_b;
	input [15:0] audio_in;
	inout [15:0] audio_b;
	inout [15:0] flags_out_b;
	wire [21:0] prg_aout;
	assign prg_aout_b = (enable ? prg_aout : 22'hzzzzzz);
	assign prg_dout_b = (enable ? 8'hff : 8'hzz);
	wire prg_allow;
	assign prg_allow_b = (enable ? prg_allow : 1'hz);
	wire [21:0] chr_aout;
	assign chr_aout_b = (enable ? chr_aout : 22'hzzzzzz);
	wire chr_allow;
	assign chr_allow_b = (enable ? chr_allow : 1'hz);
	wire vram_a10;
	assign vram_a10_b = (enable ? vram_a10 : 1'hz);
	wire vram_ce;
	assign vram_ce_b = (enable ? vram_ce : 1'hz);
	assign irq_b = (enable ? 1'b0 : 1'hz);
	wire [7:0] mapper = flags[7:0];
	wire Mapper144 = mapper == 144;
	wire Mapper149 = mapper == 149;
	wire prg_conflict = prg_ain[15] && (Mapper144 || Mapper149);
	wire prg_conflict_d0 = prg_ain[15] && Mapper144;
	wire [15:0] flags_out = {11'h000, prg_conflict_d0, 1'b1, prg_conflict, 2'b00};
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	reg [4:0] prg_bank;
	reg [6:0] chr_bank;
	wire GXROM = mapper == 66;
	wire BitCorps = mapper == 38;
	wire Mapper140 = mapper == 140;
	wire Mapper101 = mapper == 101;
	wire Mapper46 = mapper == 46;
	wire Mapper86 = mapper == 86;
	wire Mapper87 = mapper == 87;
	wire Mapper145 = mapper == 145;
	always @(posedge clk)
		if (~enable) begin
			prg_bank <= 0;
			chr_bank <= 0;
		end
		else if (ce) begin
			if (prg_ain[15] & prg_write) begin
				if (GXROM)
					{prg_bank, chr_bank} <= {3'b000, prg_din[5:4], 5'b00000, prg_din[1:0]};
				else if (Mapper149)
					{chr_bank} <= {6'b000000, prg_din[7]};
				else if (Mapper46)
					{chr_bank[2:0], prg_bank[0]} <= {prg_din[6:4], prg_din[0]};
				else
					{chr_bank, prg_bank} <= {3'b000, prg_din[7:4], 3'b000, prg_din[1:0]};
			end
			else if (((prg_ain[15:12] == 4'h7) & prg_write) & BitCorps)
				{chr_bank, prg_bank} <= {5'b00000, prg_din[3:2], 3'b000, prg_din[1:0]};
			else if ((prg_ain[15:12] == 4'h6) & prg_write) begin
				if (Mapper140)
					{prg_bank, chr_bank} <= {3'b000, prg_din[5:4], 3'b000, prg_din[3:0]};
				else if (Mapper46)
					{chr_bank[6:3], prg_bank[4:1]} <= {prg_din[7:4], prg_din[3:0]};
				else if (Mapper101)
					{chr_bank} <= {3'b000, prg_din[3:0]};
				else if (Mapper87)
					{chr_bank} <= {5'b00000, prg_din[0], prg_din[1]};
				else if (Mapper86)
					{prg_bank, chr_bank} <= {3'b000, prg_din[5:4], 4'b0000, prg_din[6], prg_din[1:0]};
			end
			else if ((prg_ain[15:8] == 8'h41) & prg_write) begin
				if (Mapper145)
					{chr_bank} <= {6'b000000, prg_din[7]};
			end
		end
	assign prg_aout = {2'b00, prg_bank, prg_ain[14:0]};
	assign prg_allow = prg_ain[15] && !prg_write;
	assign chr_allow = flags[15];
	assign chr_aout = {2'b10, chr_bank, chr_ain[12:0]};
	assign vram_ce = chr_ain[13];
	assign vram_a10 = (flags[14] ? chr_ain[10] : chr_ain[11]);
endmodule
module Mapper34 (
	clk,
	ce,
	enable,
	flags,
	prg_ain,
	prg_aout_b,
	prg_read,
	prg_write,
	prg_din,
	prg_dout_b,
	prg_allow_b,
	chr_ain,
	chr_aout_b,
	chr_read,
	chr_allow_b,
	vram_a10_b,
	vram_ce_b,
	irq_b,
	audio_in,
	audio_b,
	flags_out_b
);
	input clk;
	input ce;
	input enable;
	input [31:0] flags;
	input [15:0] prg_ain;
	inout [21:0] prg_aout_b;
	input prg_read;
	input prg_write;
	input [7:0] prg_din;
	inout [7:0] prg_dout_b;
	inout prg_allow_b;
	input [13:0] chr_ain;
	inout [21:0] chr_aout_b;
	input chr_read;
	inout chr_allow_b;
	inout vram_a10_b;
	inout vram_ce_b;
	inout irq_b;
	input [15:0] audio_in;
	inout [15:0] audio_b;
	inout [15:0] flags_out_b;
	wire [21:0] prg_aout;
	assign prg_aout_b = (enable ? prg_aout : 22'hzzzzzz);
	assign prg_dout_b = (enable ? 8'hff : 8'hzz);
	wire prg_allow;
	assign prg_allow_b = (enable ? prg_allow : 1'hz);
	wire [21:0] chr_aout;
	assign chr_aout_b = (enable ? chr_aout : 22'hzzzzzz);
	wire chr_allow;
	assign chr_allow_b = (enable ? chr_allow : 1'hz);
	wire vram_a10;
	assign vram_a10_b = (enable ? vram_a10 : 1'hz);
	wire vram_ce;
	assign vram_ce_b = (enable ? vram_ce : 1'hz);
	assign irq_b = (enable ? 1'b0 : 1'hz);
	reg [15:0] flags_out = 16'h0008;
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	reg [5:0] prg_bank;
	reg [3:0] chr_bank_0;
	reg [3:0] chr_bank_1;
	wire NINA = flags[13:11] != 0;
	always @(posedge clk)
		if (~enable) begin
			prg_bank <= 0;
			chr_bank_0 <= 0;
			chr_bank_1 <= 1;
		end
		else if (ce && prg_write) begin
			if (!NINA) begin
				if (prg_ain[15])
					prg_bank <= prg_din[5:0];
			end
			else if (prg_ain == 16'h7ffd)
				prg_bank <= prg_din[5:0];
			else if (prg_ain == 16'h7ffe)
				chr_bank_0 <= prg_din[3:0];
			else if (prg_ain == 16'h7fff)
				chr_bank_1 <= prg_din[3:0];
		end
	wire [21:0] prg_aout_tmp = {1'b0, prg_bank, prg_ain[14:0]};
	assign chr_allow = flags[15];
	assign chr_aout = {6'b100000, (chr_ain[12] == 0 ? chr_bank_0 : chr_bank_1), chr_ain[11:0]};
	assign vram_ce = chr_ain[13];
	assign vram_a10 = (flags[14] ? chr_ain[10] : chr_ain[11]);
	wire prg_is_ram = ((prg_ain >= 'h6000) && (prg_ain < 'h8000)) && NINA;
	assign prg_allow = (prg_ain[15] && !prg_write) || prg_is_ram;
	wire [21:0] prg_ram = {9'b111100000, prg_ain[12:0]};
	assign prg_aout = (prg_is_ram ? prg_ram : prg_aout_tmp);
endmodule
module Mapper71 (
	clk,
	ce,
	enable,
	flags,
	prg_ain,
	prg_aout_b,
	prg_read,
	prg_write,
	prg_din,
	prg_dout_b,
	prg_allow_b,
	chr_ain,
	chr_aout_b,
	chr_read,
	chr_allow_b,
	vram_a10_b,
	vram_ce_b,
	irq_b,
	audio_in,
	audio_b,
	flags_out_b
);
	input clk;
	input ce;
	input enable;
	input [31:0] flags;
	input [15:0] prg_ain;
	inout [21:0] prg_aout_b;
	input prg_read;
	input prg_write;
	input [7:0] prg_din;
	inout [7:0] prg_dout_b;
	inout prg_allow_b;
	input [13:0] chr_ain;
	inout [21:0] chr_aout_b;
	input chr_read;
	inout chr_allow_b;
	inout vram_a10_b;
	inout vram_ce_b;
	inout irq_b;
	input [15:0] audio_in;
	inout [15:0] audio_b;
	inout [15:0] flags_out_b;
	wire [21:0] prg_aout;
	assign prg_aout_b = (enable ? prg_aout : 22'hzzzzzz);
	assign prg_dout_b = (enable ? 8'hff : 8'hzz);
	wire prg_allow;
	assign prg_allow_b = (enable ? prg_allow : 1'hz);
	wire [21:0] chr_aout;
	assign chr_aout_b = (enable ? chr_aout : 22'hzzzzzz);
	wire chr_allow;
	assign chr_allow_b = (enable ? chr_allow : 1'hz);
	wire vram_a10;
	assign vram_a10_b = (enable ? vram_a10 : 1'hz);
	wire vram_ce;
	assign vram_ce_b = (enable ? vram_ce : 1'hz);
	assign irq_b = (enable ? 1'b0 : 1'hz);
	reg [15:0] flags_out = 16'h0008;
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	reg [3:0] prg_bank;
	reg ciram_select;
	wire mapper232 = flags[7:0] == 232;
	always @(posedge clk)
		if (~enable) begin
			prg_bank <= 0;
			ciram_select <= 0;
		end
		else if (ce) begin
			if (prg_ain[15] && prg_write) begin
				if (!prg_ain[14] && mapper232)
					prg_bank[3:2] <= prg_din[4:3];
				if (prg_ain[14:13] == 0)
					ciram_select <= prg_din[4];
				if (prg_ain[14])
					prg_bank <= {(mapper232 ? prg_bank[3:2] : prg_din[3:2]), prg_din[1:0]};
			end
		end
	reg [3:0] prgout;
	always casez ({prg_ain[14], mapper232})
		2'b0z: prgout = prg_bank;
		2'b10: prgout = 4'b1111;
		2'b11: prgout = {prg_bank[3:2], 2'b11};
	endcase
	assign prg_aout = {4'b0000, prgout, prg_ain[13:0]};
	assign prg_allow = prg_ain[15] && !prg_write;
	assign chr_allow = flags[15];
	assign chr_aout = {9'b100000000, chr_ain[12:0]};
	assign vram_ce = chr_ain[13];
	assign vram_a10 = (flags[14] ? chr_ain[10] : ciram_select);
endmodule
module Mapper77 (
	clk,
	ce,
	enable,
	flags,
	prg_ain,
	prg_aout_b,
	prg_read,
	prg_write,
	prg_din,
	prg_dout_b,
	prg_allow_b,
	chr_ain,
	chr_aout_b,
	chr_read,
	chr_allow_b,
	vram_a10_b,
	vram_ce_b,
	irq_b,
	audio_in,
	audio_b,
	flags_out_b
);
	input clk;
	input ce;
	input enable;
	input [31:0] flags;
	input [15:0] prg_ain;
	inout [21:0] prg_aout_b;
	input prg_read;
	input prg_write;
	input [7:0] prg_din;
	inout [7:0] prg_dout_b;
	inout prg_allow_b;
	input [13:0] chr_ain;
	inout [21:0] chr_aout_b;
	input chr_read;
	inout chr_allow_b;
	inout vram_a10_b;
	inout vram_ce_b;
	inout irq_b;
	input [15:0] audio_in;
	inout [15:0] audio_b;
	inout [15:0] flags_out_b;
	wire [21:0] prg_aout;
	assign prg_aout_b = (enable ? prg_aout : 22'hzzzzzz);
	assign prg_dout_b = (enable ? 8'hff : 8'hzz);
	wire prg_allow;
	assign prg_allow_b = (enable ? prg_allow : 1'hz);
	wire [21:0] chr_aout;
	assign chr_aout_b = (enable ? chr_aout : 22'hzzzzzz);
	wire chr_allow;
	assign chr_allow_b = (enable ? chr_allow : 1'hz);
	reg vram_a10;
	assign vram_a10_b = (enable ? vram_a10 : 1'hz);
	wire vram_ce;
	assign vram_ce_b = (enable ? vram_ce : 1'hz);
	assign irq_b = (enable ? 1'b0 : 1'hz);
	reg [15:0] flags_out = 16'h0008;
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	reg [3:0] prgbank;
	reg [3:0] chrbank;
	always @(posedge clk)
		if (~enable) begin
			prgbank <= 0;
			chrbank <= 0;
		end
		else if (ce) begin
			if (prg_ain[15] & prg_write)
				{chrbank, prgbank} <= prg_din[7:0];
		end
	always vram_a10 = {chr_ain[10]};
	assign prg_aout = {3'b000, prgbank, prg_ain[14:0]};
	assign prg_allow = prg_ain[15] && !prg_write;
	wire chrram = chr_ain[13:11] != 3'b000;
	assign chr_allow = chrram;
	assign chr_aout[10:0] = {chr_ain[10:0]};
	assign chr_aout[21:11] = (chrram ? {8'b11111111, chr_ain[13:11]} : {7'b1000000, chrbank});
	assign vram_ce = 0;
endmodule
module Mapper78 (
	clk,
	ce,
	enable,
	flags,
	prg_ain,
	prg_aout_b,
	prg_read,
	prg_write,
	prg_din,
	prg_dout_b,
	prg_allow_b,
	chr_ain,
	chr_aout_b,
	chr_read,
	chr_allow_b,
	vram_a10_b,
	vram_ce_b,
	irq_b,
	audio_in,
	audio_b,
	flags_out_b
);
	input clk;
	input ce;
	input enable;
	input [31:0] flags;
	input [15:0] prg_ain;
	inout [21:0] prg_aout_b;
	input prg_read;
	input prg_write;
	input [7:0] prg_din;
	inout [7:0] prg_dout_b;
	inout prg_allow_b;
	input [13:0] chr_ain;
	inout [21:0] chr_aout_b;
	input chr_read;
	inout chr_allow_b;
	inout vram_a10_b;
	inout vram_ce_b;
	inout irq_b;
	input [15:0] audio_in;
	inout [15:0] audio_b;
	inout [15:0] flags_out_b;
	wire [21:0] prg_aout;
	assign prg_aout_b = (enable ? prg_aout : 22'hzzzzzz);
	assign prg_dout_b = (enable ? 8'hff : 8'hzz);
	wire prg_allow;
	assign prg_allow_b = (enable ? prg_allow : 1'hz);
	wire [21:0] chr_aout;
	assign chr_aout_b = (enable ? chr_aout : 22'hzzzzzz);
	wire chr_allow;
	assign chr_allow_b = (enable ? chr_allow : 1'hz);
	wire vram_a10;
	assign vram_a10_b = (enable ? vram_a10 : 1'hz);
	wire vram_ce;
	assign vram_ce_b = (enable ? vram_ce : 1'hz);
	assign irq_b = (enable ? 1'b0 : 1'hz);
	reg [15:0] flags_out = 16'h0008;
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	reg [3:0] prg_bank;
	reg [3:0] chr_bank;
	reg mirroring;
	wire vmirror;
	wire mapper70 = flags[7:0] == 70;
	wire mapper81 = flags[7:0] == 81;
	wire mapper152 = flags[7:0] == 152;
	wire onescreen = (flags[22:21] == 1) | mapper152;
	always @(posedge clk)
		if (~enable) begin
			prg_bank <= 0;
			chr_bank <= 0;
			mirroring <= 0;
		end
		else if (ce) begin
			if ((prg_ain[15] == 1'b1) && prg_write)
				case (flags[7:0])
					70: {prg_bank, chr_bank} <= prg_din;
					78: {chr_bank, mirroring, prg_bank[2:0]} <= prg_din;
					81: {prg_bank[1:0], chr_bank[1:0]} <= prg_din[3:0];
					152: {mirroring, prg_bank[2:0], chr_bank} <= prg_din;
				endcase
		end
	assign prg_aout = {4'b0000, (prg_ain[14] ? 4'b1111 : prg_bank), prg_ain[13:0]};
	assign prg_allow = prg_ain[15] && !prg_write;
	assign chr_allow = flags[15];
	assign chr_aout = {5'b10000, chr_bank, chr_ain[12:0]};
	assign vram_ce = chr_ain[13];
	assign vmirror = (mapper70 || mapper81 ? flags[14] : mirroring);
	reg vram_a10_t;
	always case ({onescreen, vmirror})
		2'b00: vram_a10_t = chr_ain[11];
		2'b01: vram_a10_t = chr_ain[10];
		2'b10: vram_a10_t = 0;
		2'b11: vram_a10_t = 1;
	endcase
	assign vram_a10 = vram_a10_t;
endmodule
module Mapper79 (
	clk,
	ce,
	enable,
	flags,
	prg_ain,
	prg_aout_b,
	prg_read,
	prg_write,
	prg_din,
	prg_dout_b,
	prg_allow_b,
	chr_ain,
	chr_aout_b,
	chr_read,
	chr_allow_b,
	vram_a10_b,
	vram_ce_b,
	irq_b,
	audio_in,
	audio_b,
	flags_out_b
);
	input clk;
	input ce;
	input enable;
	input [31:0] flags;
	input [15:0] prg_ain;
	inout [21:0] prg_aout_b;
	input prg_read;
	input prg_write;
	input [7:0] prg_din;
	inout [7:0] prg_dout_b;
	inout prg_allow_b;
	input [13:0] chr_ain;
	inout [21:0] chr_aout_b;
	input chr_read;
	inout chr_allow_b;
	inout vram_a10_b;
	inout vram_ce_b;
	inout irq_b;
	input [15:0] audio_in;
	inout [15:0] audio_b;
	inout [15:0] flags_out_b;
	wire [21:0] prg_aout;
	assign prg_aout_b = (enable ? prg_aout : 22'hzzzzzz);
	assign prg_dout_b = (enable ? 8'hff : 8'hzz);
	wire prg_allow;
	assign prg_allow_b = (enable ? prg_allow : 1'hz);
	wire [21:0] chr_aout;
	assign chr_aout_b = (enable ? chr_aout : 22'hzzzzzz);
	wire chr_allow;
	assign chr_allow_b = (enable ? chr_allow : 1'hz);
	wire vram_a10;
	assign vram_a10_b = (enable ? vram_a10 : 1'hz);
	wire vram_ce;
	assign vram_ce_b = (enable ? vram_ce : 1'hz);
	assign irq_b = (enable ? 1'b0 : 1'hz);
	wire mapper148 = flags[7:0] == 148;
	wire prg_conflict = prg_ain[15] && mapper148;
	wire [15:0] flags_out = {13'h0001, prg_conflict, 2'b00};
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	reg [2:0] prg_bank;
	reg [3:0] chr_bank;
	reg mirroring;
	wire mapper113 = flags[7:0] == 113;
	wire mapper133 = flags[7:0] == 133;
	always @(posedge clk)
		if (~enable) begin
			prg_bank <= 0;
			chr_bank <= 0;
			mirroring <= 0;
		end
		else if (ce) begin
			if (((prg_ain[15:13] == 3'b010) && prg_ain[8]) && prg_write) begin
				if (mapper133)
					{mirroring, chr_bank[3], prg_bank, chr_bank[2:0]} <= {4'h0, prg_din[2], 1'b0, prg_din[1:0]};
				else
					{mirroring, chr_bank[3], prg_bank, chr_bank[2:0]} <= prg_din;
			end
			if ((prg_ain[15] == 1'b1) && prg_write) begin
				if (mapper148)
					{mirroring, chr_bank[3], prg_bank, chr_bank[2:0]} <= prg_din;
			end
		end
	assign prg_aout = {4'b0000, prg_bank, prg_ain[14:0]};
	assign prg_allow = prg_ain[15] && !prg_write;
	assign chr_allow = flags[15];
	assign chr_aout = {5'b10000, chr_bank, chr_ain[12:0]};
	assign vram_ce = chr_ain[13];
	wire mirrconfig = (mapper113 ? mirroring : flags[14]);
	assign vram_a10 = (mirrconfig ? chr_ain[10] : chr_ain[11]);
endmodule
module Mapper89 (
	clk,
	ce,
	enable,
	flags,
	prg_ain,
	prg_aout_b,
	prg_read,
	prg_write,
	prg_din,
	prg_dout_b,
	prg_allow_b,
	chr_ain,
	chr_aout_b,
	chr_read,
	chr_allow_b,
	vram_a10_b,
	vram_ce_b,
	irq_b,
	audio_in,
	audio_b,
	flags_out_b
);
	input clk;
	input ce;
	input enable;
	input [31:0] flags;
	input [15:0] prg_ain;
	inout [21:0] prg_aout_b;
	input prg_read;
	input prg_write;
	input [7:0] prg_din;
	inout [7:0] prg_dout_b;
	inout prg_allow_b;
	input [13:0] chr_ain;
	inout [21:0] chr_aout_b;
	input chr_read;
	inout chr_allow_b;
	inout vram_a10_b;
	inout vram_ce_b;
	inout irq_b;
	input [15:0] audio_in;
	inout [15:0] audio_b;
	inout [15:0] flags_out_b;
	wire [21:0] prg_aout;
	assign prg_aout_b = (enable ? prg_aout : 22'hzzzzzz);
	assign prg_dout_b = (enable ? 8'hff : 8'hzz);
	wire prg_allow;
	assign prg_allow_b = (enable ? prg_allow : 1'hz);
	wire [21:0] chr_aout;
	assign chr_aout_b = (enable ? chr_aout : 22'hzzzzzz);
	wire chr_allow;
	assign chr_allow_b = (enable ? chr_allow : 1'hz);
	reg vram_a10;
	assign vram_a10_b = (enable ? vram_a10 : 1'hz);
	wire vram_ce;
	assign vram_ce_b = (enable ? vram_ce : 1'hz);
	assign irq_b = (enable ? 1'b0 : 1'hz);
	reg [15:0] flags_out = 16'h0008;
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	reg [2:0] prgsel;
	reg [3:0] chrsel0;
	reg [3:0] chrsel1;
	reg [2:0] prg_temp;
	reg [4:0] chr_temp;
	reg mirror;
	wire [7:0] mapper = flags[7:0];
	wire mapper89 = mapper == 8'd89;
	wire mapper93 = mapper == 8'd93;
	wire mapper184 = mapper == 8'd184;
	always @(posedge clk)
		if (~enable) begin
			prgsel <= 3'b110;
			chrsel0 <= 4'b1111;
			chrsel1 <= 4'b1111;
		end
		else if (ce) begin
			if ((prg_ain[15] & prg_write) & mapper89)
				{chrsel0[3], prgsel, mirror, chrsel0[2:0]} <= prg_din;
			else if ((prg_ain[15] & prg_write) & mapper93)
				prgsel <= prg_din[6:4];
			else if (((prg_ain[15:13] == 3'b011) & prg_write) & mapper184)
				{chrsel1[3:0], chrsel0[3:0]} <= {2'b01, prg_din[5:4], 1'b0, prg_din[2:0]};
		end
	always begin
		casez ({mapper89, flags[14]})
			2'b00: vram_a10 = {chr_ain[11]};
			2'b01: vram_a10 = {chr_ain[10]};
			2'b1z: vram_a10 = {mirror};
		endcase
		casez ({mapper184, prg_ain[14]})
			2'b00: prg_temp = {prgsel};
			2'b01: prg_temp = 3'b111;
			2'b1z: prg_temp = {2'b00, prg_ain[14]};
		endcase
		casez ({mapper184, chr_ain[12]})
			2'b0z: chr_temp = {chrsel0, chr_ain[12]};
			2'b10: chr_temp = {1'b0, chrsel0};
			2'b11: chr_temp = {1'b0, chrsel1};
		endcase
	end
	assign vram_ce = chr_ain[13];
	assign prg_aout = {5'b00000, prg_temp, prg_ain[13:0]};
	assign prg_allow = prg_ain[15] && !prg_write;
	assign chr_allow = flags[15];
	assign chr_aout = {5'b10000, chr_temp, chr_ain[11:0]};
endmodule
module Mapper107 (
	clk,
	ce,
	enable,
	flags,
	prg_ain,
	prg_aout_b,
	prg_read,
	prg_write,
	prg_din,
	prg_dout_b,
	prg_allow_b,
	chr_ain,
	chr_aout_b,
	chr_read,
	chr_allow_b,
	vram_a10_b,
	vram_ce_b,
	irq_b,
	audio_in,
	audio_b,
	flags_out_b
);
	input clk;
	input ce;
	input enable;
	input [31:0] flags;
	input [15:0] prg_ain;
	inout [21:0] prg_aout_b;
	input prg_read;
	input prg_write;
	input [7:0] prg_din;
	inout [7:0] prg_dout_b;
	inout prg_allow_b;
	input [13:0] chr_ain;
	inout [21:0] chr_aout_b;
	input chr_read;
	inout chr_allow_b;
	inout vram_a10_b;
	inout vram_ce_b;
	inout irq_b;
	input [15:0] audio_in;
	inout [15:0] audio_b;
	inout [15:0] flags_out_b;
	wire [21:0] prg_aout;
	assign prg_aout_b = (enable ? prg_aout : 22'hzzzzzz);
	assign prg_dout_b = (enable ? 8'hff : 8'hzz);
	wire prg_allow;
	assign prg_allow_b = (enable ? prg_allow : 1'hz);
	wire [21:0] chr_aout;
	assign chr_aout_b = (enable ? chr_aout : 22'hzzzzzz);
	wire chr_allow;
	assign chr_allow_b = (enable ? chr_allow : 1'hz);
	wire vram_a10;
	assign vram_a10_b = (enable ? vram_a10 : 1'hz);
	wire vram_ce;
	assign vram_ce_b = (enable ? vram_ce : 1'hz);
	assign irq_b = (enable ? 1'b0 : 1'hz);
	reg [15:0] flags_out = 0;
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	reg [6:0] prg_bank;
	reg [7:0] chr_bank;
	always @(posedge clk)
		if (~enable) begin
			prg_bank <= 0;
			chr_bank <= 0;
		end
		else if (ce) begin
			if (prg_ain[15] & prg_write) begin
				prg_bank <= prg_din[7:1];
				chr_bank <= prg_din[7:0];
			end
		end
	assign vram_a10 = (flags[14] ? chr_ain[10] : chr_ain[11]);
	assign prg_aout = {1'b0, prg_bank[5:0], prg_ain[14:0]};
	assign prg_allow = prg_ain[15] && !prg_write;
	assign chr_allow = flags[15];
	assign chr_aout = {2'b10, chr_bank[6:0], chr_ain[12:0]};
	assign vram_ce = chr_ain[13];
endmodule
module Mapper28 (
	clk,
	ce,
	enable,
	flags,
	prg_ain,
	prg_aout_b,
	prg_read,
	prg_write,
	prg_din,
	prg_dout_b,
	prg_allow_b,
	chr_ain,
	chr_aout_b,
	chr_dout_b,
	chr_read,
	chr_allow_b,
	vram_a10_b,
	vram_ce_b,
	irq_b,
	audio_in,
	audio_b,
	flags_out_b
);
	input clk;
	input ce;
	input enable;
	input [63:0] flags;
	input [15:0] prg_ain;
	inout [21:0] prg_aout_b;
	input prg_read;
	input prg_write;
	input [7:0] prg_din;
	inout [7:0] prg_dout_b;
	inout prg_allow_b;
	input [13:0] chr_ain;
	inout [21:0] chr_aout_b;
	inout [7:0] chr_dout_b;
	input chr_read;
	inout chr_allow_b;
	inout vram_a10_b;
	inout vram_ce_b;
	inout irq_b;
	input [15:0] audio_in;
	inout [15:0] audio_b;
	inout [15:0] flags_out_b;
	wire [21:0] prg_aout;
	assign prg_aout_b = (enable ? prg_aout : 22'hzzzzzz);
	assign prg_dout_b = (enable ? 8'hff : 8'hzz);
	wire prg_allow;
	assign prg_allow_b = (enable ? prg_allow : 1'hz);
	wire [21:0] chr_aout;
	assign chr_aout_b = (enable ? chr_aout : 22'hzzzzzz);
	reg [7:0] chr_dout;
	assign chr_dout_b = (enable ? chr_dout : 8'hzz);
	wire chr_allow;
	assign chr_allow_b = (enable ? chr_allow : 1'hz);
	reg vram_a10;
	assign vram_a10_b = (enable ? vram_a10 : 1'hz);
	wire vram_ce;
	assign vram_ce_b = (enable ? vram_ce : 1'hz);
	assign irq_b = (enable ? 1'b0 : 1'hz);
	wire has_chr_dout;
	wire prg_conflict;
	wire [15:0] flags_out = {13'h0001, prg_conflict, 1'b0, has_chr_dout};
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	reg [6:0] a53prg;
	reg [1:0] a53chr;
	reg [3:0] inner;
	reg [5:0] mode;
	reg [5:0] outer;
	reg [2:0] selreg;
	reg [3:0] security;
	wire [7:0] mapper = flags[7:0];
	wire allow_select = mapper == 8'd28;
	wire extend_bit = mapper == 97;
	always @(posedge clk)
		if (~enable) begin
			mode[5:2] <= 0;
			outer[5:0] <= 6'h3f;
			inner <= 0;
			selreg <= 1;
			if ((((((mapper == 2) || (mapper == 0)) || (mapper == 3)) || (mapper == 94)) || (mapper == 180)) || (mapper == 185))
				mode[1:0] <= (flags[14] ? 2'b10 : 2'b11);
			if (mapper == 2)
				mode[5:2] <= 4'b1111;
			if (mapper == 3)
				selreg <= 0;
			if (mapper == 185)
				selreg <= 4;
			if (mapper == 180) begin
				selreg <= 1;
				mode[5:2] <= 4'b1110;
				outer[5:0] <= 6'h00;
			end
			if (mapper == 97) begin
				selreg <= 6;
				mode[5:2] <= 4'b1110;
				outer[5:0] <= 6'h3f;
			end
			if (mapper == 94) begin
				selreg <= 7;
				mode[5:2] <= 4'b1111;
			end
			if (mapper == 7) begin
				mode[1:0] <= 2'b00;
				mode[5:2] <= 4'b1100;
				outer[5:0] <= 6'h00;
			end
		end
		else if (ce) begin
			if (((prg_ain[15:12] == 4'h5) & prg_write) && allow_select)
				selreg <= {1'b0, prg_din[7], prg_din[0]};
			if (prg_ain[15] & prg_write)
				casez (selreg)
					3'b000: {mode[0], a53chr} <= {(mode[1] ? mode[0] : prg_din[4]), prg_din[1:0]};
					3'b001: begin
						{mode[0], inner} <= {(mode[1] ? mode[0] : prg_din[4]), prg_din[3:0]};
						{outer[5:3]} <= {(mapper == 2 ? prg_din[6:4] : outer[5:3])};
					end
					3'b010: {mode} <= {prg_din[5:0]};
					3'b011: {outer} <= {prg_din[5:0]};
					3'b10z: {security} <= {prg_din[5:4], prg_din[1:0]};
					3'b110: {mode[1:0], inner} <= {prg_din[7] ^ prg_din[6], prg_din[6], prg_din[3:0]};
					3'b111: {inner} <= {prg_din[5:2]};
				endcase
		end
	always begin
		casez (mode[1:0])
			2'b0z: vram_a10 = {mode[0]};
			2'b10: vram_a10 = {chr_ain[10]};
			2'b11: vram_a10 = {chr_ain[11]};
		endcase
		casez ({mode[5:2], prg_ain[14]})
			5'b000zz: a53prg = {outer[5:0], prg_ain[14]};
			5'b010zz: a53prg = {outer[5:1], inner[0], prg_ain[14]};
			5'b100zz: a53prg = {outer[5:2], inner[1:0], prg_ain[14]};
			5'b110zz: a53prg = {outer[5:3], inner[2:0], prg_ain[14]};
			5'b00101, 5'b00110: a53prg = {outer[5:0], inner[0]};
			5'b01101, 5'b01110: a53prg = {outer[5:1], inner[1:0]};
			5'b10101, 5'b10110: a53prg = {outer[5:2], inner[2:0]};
			5'b11101, 5'b11110: a53prg = {outer[5:3], inner[3:0]};
			default: a53prg = {(mapper == 2 ? 6'h3f : outer[5:0]), (extend_bit ? outer[0] : prg_ain[14])};
		endcase
		chr_dout = 8'hff;
	end
	assign vram_ce = chr_ain[13];
	wire prg_is_ram = (prg_ain[15:13] == 3'b011) && (|flags[29:26] | (|flags[34:31]));
	wire [21:0] prg_aout_tmp = {1'b0, a53prg, prg_ain[13:0]};
	wire [21:0] prg_ram = {9'b111100000, prg_ain[12:0]};
	assign prg_aout = (prg_is_ram ? prg_ram : prg_aout_tmp);
	assign prg_allow = (prg_ain[15] && !prg_write) || prg_is_ram;
	wire [4:0] submapper = flags[24:21];
	assign prg_conflict = (prg_ain[15] && (mapper == 3)) && (submapper != 1);
	assign chr_allow = flags[15];
	assign chr_aout = {7'b1000000, a53chr, chr_ain[12:0]};
	assign has_chr_dout = (mapper == 185) && ((((((submapper == 0) && (security[1:0] == 2'b00)) || ((submapper == 4) && (security[1:0] != 2'b00))) || ((submapper == 5) && (security[1:0] != 2'b01))) || ((submapper == 6) && (security[1:0] != 2'b10))) || ((submapper == 7) && (security[1:0] != 2'b11)));
endmodule
