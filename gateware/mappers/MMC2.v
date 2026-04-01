module MMC2 (
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
	flags_out_b,
	chr_ain_o,
	paused
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
	input [13:0] chr_ain_o;
	input paused;
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
	reg [4:0] chr_bank_0a;
	reg [4:0] chr_bank_0b;
	reg [4:0] chr_bank_1a;
	reg [4:0] chr_bank_1b;
	reg mirroring;
	reg latch_0;
	reg latch_1;
	always @(posedge clk)
		if (~enable)
			{prg_bank, chr_bank_0a, chr_bank_0b, chr_bank_1a, chr_bank_1b, mirroring} <= 0;
		else if (ce) begin
			if (prg_write && prg_ain[15])
				case (prg_ain[14:12])
					2: prg_bank <= prg_din[3:0];
					3: chr_bank_0a <= prg_din[4:0];
					4: chr_bank_0b <= prg_din[4:0];
					5: chr_bank_1a <= prg_din[4:0];
					6: chr_bank_1b <= prg_din[4:0];
					7: mirroring <= prg_din[0];
				endcase
		end
	always @(posedge clk)
		if (~enable)
			{latch_0, latch_1} <= 0;
		else if (~paused && chr_read) begin
			latch_0 <= ((chr_ain_o & 14'h3fff) == 14'h0fd8 ? 1'd0 : ((chr_ain_o & 14'h3fff) == 14'h0fe8 ? 1'd1 : latch_0));
			latch_1 <= ((chr_ain_o & 14'h3ff8) == 14'h1fd8 ? 1'd0 : ((chr_ain_o & 14'h3ff8) == 14'h1fe8 ? 1'd1 : latch_1));
		end
	reg [3:0] prgsel;
	always @(*)
		casez (prg_ain[14:13])
			2'b00: prgsel = prg_bank;
			default: prgsel = {2'b11, prg_ain[14:13]};
		endcase
	assign prg_aout = {5'b00000, prgsel, prg_ain[12:0]};
	reg [4:0] chrsel;
	always @(*)
		casez ({chr_ain[12], latch_0, latch_1})
			3'b00z: chrsel = chr_bank_0a;
			3'b01z: chrsel = chr_bank_0b;
			3'b1z0: chrsel = chr_bank_1a;
			3'b1z1: chrsel = chr_bank_1b;
		endcase
	assign chr_aout = {5'b10000, chrsel, chr_ain[11:0]};
	assign vram_a10 = (mirroring ? chr_ain[11] : chr_ain[10]);
	assign vram_ce = chr_ain[13];
	assign prg_allow = prg_ain[15] && !prg_write;
	assign chr_allow = flags[15];
endmodule
module MMC4 (
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
	flags_out_b,
	chr_ain_o,
	paused
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
	input [13:0] chr_ain_o;
	input paused;
	wire [21:0] prg_aout;
	assign prg_aout_b = (enable ? prg_aout : 22'hzzzzzz);
	wire [7:0] prg_dout = 0;
	assign prg_dout_b = (enable ? prg_dout : 8'hzz);
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
	reg [4:0] chr_bank_0a;
	reg [4:0] chr_bank_0b;
	reg [4:0] chr_bank_1a;
	reg [4:0] chr_bank_1b;
	reg mirroring;
	reg latch_0;
	reg latch_1;
	always @(posedge clk)
		if (ce) begin
			if (~enable)
				prg_bank <= 4'b1110;
			else if (prg_write && prg_ain[15])
				case (prg_ain[14:12])
					2: prg_bank <= prg_din[3:0];
					3: chr_bank_0a <= prg_din[4:0];
					4: chr_bank_0b <= prg_din[4:0];
					5: chr_bank_1a <= prg_din[4:0];
					6: chr_bank_1b <= prg_din[4:0];
					7: mirroring <= prg_din[0];
				endcase
		end
	always @(posedge clk)
		if (~paused & chr_read) begin
			latch_0 <= ((chr_ain_o & 14'h3ff8) == 14'h0fd8 ? 1'd0 : ((chr_ain_o & 14'h3ff8) == 14'h0fe8 ? 1'd1 : latch_0));
			latch_1 <= ((chr_ain_o & 14'h3ff8) == 14'h1fd8 ? 1'd0 : ((chr_ain_o & 14'h3ff8) == 14'h1fe8 ? 1'd1 : latch_1));
		end
	reg [3:0] prgsel;
	always @(*)
		casez (prg_ain[14])
			1'b0: prgsel = prg_bank;
			default: prgsel = 4'b1111;
		endcase
	wire [21:0] prg_aout_tmp = {4'b0000, prgsel, prg_ain[13:0]};
	reg [4:0] chrsel;
	always @(*)
		casez ({chr_ain[12], latch_0, latch_1})
			3'b00z: chrsel = chr_bank_0a;
			3'b01z: chrsel = chr_bank_0b;
			3'b1z0: chrsel = chr_bank_1a;
			3'b1z1: chrsel = chr_bank_1b;
		endcase
	assign chr_aout = {5'b10000, chrsel, chr_ain[11:0]};
	assign vram_a10 = (mirroring ? chr_ain[11] : chr_ain[10]);
	assign vram_ce = chr_ain[13];
	assign chr_allow = flags[15];
	wire prg_is_ram = (prg_ain >= 'h6000) && (prg_ain < 'h8000);
	assign prg_allow = (prg_ain[15] && !prg_write) || prg_is_ram;
	wire [21:0] prg_ram = {9'b111100000, prg_ain[12:0]};
	assign prg_aout = (prg_is_ram ? prg_ram : prg_aout_tmp);
endmodule
