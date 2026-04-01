module MMC1 (
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
	wire mapper171 = flags[7:0] == 171;
	reg [4:0] shift;
	reg [4:0] control;
	reg [4:0] chr_bank_0;
	reg [4:0] chr_bank_1;
	reg [4:0] prg_bank;
	reg delay_ctrl;
	reg chr_write_disable;
	wire [3:0] prg_ram_size = flags[29:26];
	wire [3:0] prg_nvram_size = flags[34:31];
	wire [2:0] chr_size = flags[13:11];
	always @(posedge clk)
		if (~enable) begin
			shift <= 5'b10000;
			control <= 5'b01100;
			chr_bank_0 <= 0;
			chr_bank_1 <= 0;
			prg_bank <= 5'b10000;
			delay_ctrl <= 0;
		end
		else if (ce) begin
			if (prg_write && prg_ain[15]) begin
				delay_ctrl <= 1'b1;
				if (prg_din[7]) begin
					shift <= 5'b10000;
					control <= control | 5'b01100;
				end
				else if (!delay_ctrl) begin
					if (shift[0]) begin
						casez (prg_ain[14:13])
							0: control <= {prg_din[0], shift[4:1]};
							1: chr_bank_0 <= {prg_din[0], shift[4:1]};
							2: chr_bank_1 <= {prg_din[0], shift[4:1]};
							3: prg_bank <= {prg_din[0], shift[4:1]};
						endcase
						shift <= 5'b10000;
					end
					else
						shift <= {prg_din[0], shift[4:1]};
				end
			end
			else
				delay_ctrl <= 1'b0;
		end
	reg [3:0] prgsel;
	always @(*)
		casez ({control[3:2], prg_ain[14]})
			3'b0zz: prgsel = {prg_bank[3:1], prg_ain[14]};
			3'b100: prgsel = 4'b0000;
			3'b101: prgsel = prg_bank[3:0];
			3'b110: prgsel = prg_bank[3:0];
			3'b111: prgsel = 4'b1111;
		endcase
	reg [4:0] chrsel;
	always @(*)
		casez ({control[4], chr_ain[12]})
			2'b0z: chrsel = {chr_bank_0[4:1], chr_ain[12]};
			2'b10: chrsel = chr_bank_0;
			2'b11: chrsel = chr_bank_1;
		endcase
	assign chr_aout = {5'b10000, chrsel, chr_ain[11:0]};
	wire [21:0] prg_aout_tmp = {3'b000, chrsel[4], prgsel, prg_ain[13:0]};
	reg vram_a10_t;
	always @(*)
		casez ((mapper171 ? 2'b10 : control[1:0]))
			2'b00: vram_a10_t = 0;
			2'b01: vram_a10_t = 1;
			2'b10: vram_a10_t = chr_ain[10];
			2'b11: vram_a10_t = chr_ain[11];
		endcase
	reg [1:0] prg_ram_a14_13;
	always @(*)
		if ((prg_ram_size == 4'd7) && (prg_nvram_size == 4'd7))
			prg_ram_a14_13 = {1'b0, (chr_size >= 3'd1 ? ~chrsel[4] : ~chrsel[3])};
		else if (prg_nvram_size == 4'd9)
			prg_ram_a14_13 = {chrsel[3], chrsel[2]};
		else
			prg_ram_a14_13 = 2'b00;
	assign vram_a10 = vram_a10_t;
	assign vram_ce = chr_ain[13];
	wire prg_is_ram = (prg_ain >= 'h6000) && (prg_ain < 'h8000);
	assign prg_allow = (prg_ain[15] && !prg_write) || prg_is_ram;
	wire [21:0] prg_ram = {7'b1111000, prg_ram_a14_13, prg_ain[12:0]};
	assign prg_aout = (prg_is_ram ? prg_ram : prg_aout_tmp);
	assign chr_allow = flags[15];
endmodule
module NesEvent (
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
	reg [21:0] prg_aout;
	assign prg_aout_b = (enable ? prg_aout : 22'hzzzzzz);
	wire [21:0] chr_aout;
	assign chr_aout_b = (enable ? chr_aout : 22'hzzzzzz);
	wire irq;
	assign irq_b = (enable ? irq : 1'hz);
	wire [21:0] mmc1_chr_addr;
	wire [3:0] mmc1_chr = mmc1_chr_addr[16:13];
	wire [21:0] mmc1_aout;
	MMC1 mmc1_nesevent(
		.clk(clk),
		.ce(ce),
		.enable(enable),
		.flags(flags),
		.prg_ain(prg_ain),
		.prg_aout_b(mmc1_aout),
		.prg_read(prg_read),
		.prg_write(prg_write),
		.prg_din(prg_din),
		.prg_dout_b(prg_dout_b),
		.prg_allow_b(prg_allow_b),
		.chr_ain(chr_ain),
		.chr_aout_b(mmc1_chr_addr),
		.chr_read(chr_read),
		.chr_allow_b(chr_allow_b),
		.vram_a10_b(vram_a10_b),
		.vram_ce_b(vram_ce_b),
		.irq_b(),
		.flags_out_b(flags_out_b),
		.audio_in(audio_in),
		.audio_b(audio_b)
	);
	reg unlocked;
	reg old_val;
	reg [29:0] counter;
	reg [3:0] oldbits;
	always @(posedge clk)
		if (~enable) begin
			old_val <= 0;
			unlocked <= 0;
			counter <= 0;
		end
		else if (ce) begin
			if (mmc1_chr[3] && !old_val)
				unlocked <= 1;
			old_val <= mmc1_chr[3];
			counter <= (mmc1_chr[3] ? 1'd0 : counter + 1'd1);
			if (mmc1_chr != oldbits)
				oldbits <= mmc1_chr;
		end
	assign irq = counter[29:25] == 5'b10100;
	always if (!prg_ain[15])
		prg_aout = {mmc1_aout[21:15], 2'b00, prg_ain[12:0]};
	else begin
		prg_aout[21:18] = 4'd0;
		if (!unlocked)
			prg_aout[17:15] = 3'd0;
		else if (~mmc1_chr_addr[15])
			prg_aout[17:15] = {1'b0, mmc1_chr_addr[14:13]};
		else
			prg_aout[17:15] = {1'b1, mmc1_aout[16:15]};
		prg_aout[14] = mmc1_aout[14];
		prg_aout[13:0] = prg_ain[13:0];
	end
	assign chr_aout = {9'b100000000, chr_ain[12:0]};
endmodule
