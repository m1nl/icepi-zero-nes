module Mapper15 (
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
	reg [15:0] flags_out = 0;
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	reg [1:0] prg_rom_bank_mode;
	reg prg_rom_bank_lowbit;
	reg mirroring;
	reg [5:0] prg_rom_bank;
	always @(posedge clk)
		if (~enable) begin
			prg_rom_bank_mode <= 0;
			prg_rom_bank_lowbit <= 0;
			mirroring <= 0;
			prg_rom_bank <= 0;
		end
		else if (ce) begin
			if (prg_ain[15] && prg_write)
				{prg_rom_bank_mode, prg_rom_bank_lowbit, mirroring, prg_rom_bank} <= {prg_ain[1:0], prg_din[7:0]};
		end
	reg [6:0] prg_bank;
	always casez ({prg_rom_bank_mode, prg_ain[14]})
		3'b000: prg_bank = {prg_rom_bank, prg_ain[13]};
		3'b001: prg_bank = {prg_rom_bank | 6'b000001, prg_ain[13]};
		3'b010: prg_bank = {prg_rom_bank, prg_ain[13]};
		3'b011: prg_bank = {6'b111111, prg_ain[13]};
		3'b10z: prg_bank = {prg_rom_bank, prg_rom_bank_lowbit};
		3'b11z: prg_bank = {prg_rom_bank, prg_ain[13]};
	endcase
	assign prg_aout = {2'b00, prg_bank, prg_ain[12:0]};
	assign prg_allow = prg_ain[15] && !prg_write;
	assign chr_allow = flags[15];
	assign chr_aout = {9'b100000000, chr_ain[12:0]};
	assign vram_ce = chr_ain[13];
	wire [1:1] sv2v_tmp_C3571;
	assign sv2v_tmp_C3571 = (mirroring ? chr_ain[11] : chr_ain[10]);
	always @(*) vram_a10 = sv2v_tmp_C3571;
endmodule
module Mapper18 (
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
	reg [7:0] prg_dout;
	assign prg_dout_b = (enable ? prg_dout : 8'hzz);
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
	reg irq;
	assign irq_b = (enable ? irq : 1'hz);
	reg [15:0] flags_out = 16'h0008;
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	reg [7:0] prg_bank_0;
	reg [7:0] prg_bank_1;
	reg [7:0] prg_bank_2;
	reg [7:0] chr_bank_0;
	reg [7:0] chr_bank_1;
	reg [7:0] chr_bank_2;
	reg [7:0] chr_bank_3;
	reg [7:0] chr_bank_4;
	reg [7:0] chr_bank_5;
	reg [7:0] chr_bank_6;
	reg [7:0] chr_bank_7;
	reg [1:0] mirroring;
	reg irq_ack;
	reg [3:0] irq_enable;
	reg [15:0] irq_reload;
	reg [15:0] irq_counter;
	reg [1:0] ram_enable;
	always @(posedge clk)
		if (~enable) begin
			prg_bank_0 <= 8'hff;
			prg_bank_1 <= 8'hff;
			prg_bank_2 <= 8'hff;
			chr_bank_0 <= 0;
			chr_bank_1 <= 0;
			chr_bank_2 <= 0;
			chr_bank_3 <= 0;
			chr_bank_4 <= 0;
			chr_bank_5 <= 0;
			chr_bank_6 <= 0;
			chr_bank_7 <= 0;
			mirroring <= 0;
			irq_reload <= 0;
			irq_counter <= 0;
			irq_enable <= 4'h0;
		end
		else if (ce) begin
			irq_ack <= 1'b0;
			if (irq_enable[0]) begin
				irq_counter[3:0] <= irq_counter[3:0] - 4'd1;
				if (irq_counter[3:0] == 4'h0) begin
					if (irq_enable[3])
						irq <= 1'b1;
					else begin
						irq_counter[7:4] <= irq_counter[7:4] - 4'd1;
						if (irq_counter[7:4] == 4'h0) begin
							if (irq_enable[2])
								irq <= 1'b1;
							else begin
								irq_counter[11:8] <= irq_counter[11:8] - 4'd1;
								if (irq_counter[11:8] == 4'h0) begin
									if (irq_enable[1])
										irq <= 1'b1;
									else begin
										irq_counter[15:12] <= irq_counter[15:12] - 4'd1;
										if (irq_counter[15:12] == 4'h0)
											irq <= 1'b1;
									end
								end
							end
						end
					end
				end
			end
			if (prg_write) begin
				if (prg_ain[15])
					case ({prg_ain[14:12], prg_ain[1:0]})
						5'b00000: prg_bank_0[3:0] <= prg_din[3:0];
						5'b00001: prg_bank_0[7:4] <= prg_din[3:0];
						5'b00010: prg_bank_1[3:0] <= prg_din[3:0];
						5'b00011: prg_bank_1[7:4] <= prg_din[3:0];
						5'b00100: prg_bank_2[3:0] <= prg_din[3:0];
						5'b00101: prg_bank_2[7:4] <= prg_din[3:0];
						5'b00110: ram_enable <= prg_din[1:0];
						5'b01000: chr_bank_0[3:0] <= prg_din[3:0];
						5'b01001: chr_bank_0[7:4] <= prg_din[3:0];
						5'b01010: chr_bank_1[3:0] <= prg_din[3:0];
						5'b01011: chr_bank_1[7:4] <= prg_din[3:0];
						5'b01100: chr_bank_2[3:0] <= prg_din[3:0];
						5'b01101: chr_bank_2[7:4] <= prg_din[3:0];
						5'b01110: chr_bank_3[3:0] <= prg_din[3:0];
						5'b01111: chr_bank_3[7:4] <= prg_din[3:0];
						5'b10000: chr_bank_4[3:0] <= prg_din[3:0];
						5'b10001: chr_bank_4[7:4] <= prg_din[3:0];
						5'b10010: chr_bank_5[3:0] <= prg_din[3:0];
						5'b10011: chr_bank_5[7:4] <= prg_din[3:0];
						5'b10100: chr_bank_6[3:0] <= prg_din[3:0];
						5'b10101: chr_bank_6[7:4] <= prg_din[3:0];
						5'b10110: chr_bank_7[3:0] <= prg_din[3:0];
						5'b10111: chr_bank_7[7:4] <= prg_din[3:0];
						5'b11000: irq_reload[3:0] <= prg_din[3:0];
						5'b11001: irq_reload[7:4] <= prg_din[3:0];
						5'b11010: irq_reload[11:8] <= prg_din[3:0];
						5'b11011: irq_reload[15:12] <= prg_din[3:0];
						5'b11100: {irq_ack, irq_counter} <= {1'b1, irq_reload};
						5'b11101: {irq_ack, irq_enable} <= {1'b1, prg_din[3:0]};
						5'b11110: mirroring <= prg_din[1:0];
					endcase
			end
			if (irq_ack)
				irq <= 1'b0;
		end
	always casez (mirroring[1:0])
		2'b00: vram_a10 = {chr_ain[11]};
		2'b01: vram_a10 = {chr_ain[10]};
		2'b1z: vram_a10 = {mirroring[0]};
	endcase
	reg [7:0] prgsel;
	always case (prg_ain[14:13])
		2'b00: prgsel = prg_bank_0;
		2'b01: prgsel = prg_bank_1;
		2'b10: prgsel = prg_bank_2;
		2'b11: prgsel = 8'hff;
	endcase
	reg [7:0] chrsel;
	always casez (chr_ain[12:10])
		0: chrsel = chr_bank_0;
		1: chrsel = chr_bank_1;
		2: chrsel = chr_bank_2;
		3: chrsel = chr_bank_3;
		4: chrsel = chr_bank_4;
		5: chrsel = chr_bank_5;
		6: chrsel = chr_bank_6;
		7: chrsel = chr_bank_7;
	endcase
	assign chr_aout = {4'b1000, chrsel, chr_ain[9:0]};
	wire [21:0] prg_aout_tmp = {2'b00, prgsel[6:0], prg_ain[12:0]};
	wire prg_is_ram = (prg_ain >= 'h6000) && (prg_ain < 'h8000);
	wire [21:0] prg_ram = {9'b111100000, prg_ain[12:0]};
	assign prg_aout = (prg_is_ram ? prg_ram : prg_aout_tmp);
	wire [8:1] sv2v_tmp_0E42F;
	assign sv2v_tmp_0E42F = 8'hff;
	always @(*) prg_dout = sv2v_tmp_0E42F;
	assign prg_allow = (prg_ain[15] && !prg_write) || ((prg_is_ram && ram_enable[0]) && (ram_enable[1] || !prg_write));
	assign chr_allow = flags[15];
	assign vram_ce = chr_ain[13];
endmodule
module Mapper32 (
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
	reg [4:0] prgreg0;
	reg [4:0] prgreg1;
	reg [7:0] chrreg0;
	reg [7:0] chrreg1;
	reg [7:0] chrreg2;
	reg [7:0] chrreg3;
	reg [7:0] chrreg4;
	reg [7:0] chrreg5;
	reg [7:0] chrreg6;
	reg [7:0] chrreg7;
	reg prgmode;
	reg mirror;
	wire submapper1 = flags[21] == 1;
	wire ram_support = flags[29:26] == 4'd7;
	reg [4:0] prgsel;
	reg [7:0] chrsel;
	always @(posedge clk)
		if (~enable)
			prgmode <= 1'b0;
		else if (ce) begin
			if ((prg_ain[15:14] == 2'b10) & prg_write)
				casez ({prg_ain[13:12], submapper1, prg_ain[2:0]})
					6'b00zzzz: prgreg0 <= prg_din[4:0];
					6'b010zzz: {prgmode, mirror} <= prg_din[1:0];
					6'b10zzzz: prgreg1 <= prg_din[4:0];
					6'b11z000: chrreg0 <= prg_din;
					6'b11z001: chrreg1 <= prg_din;
					6'b11z010: chrreg2 <= prg_din;
					6'b11z011: chrreg3 <= prg_din;
					6'b11z100: chrreg4 <= prg_din;
					6'b11z101: chrreg5 <= prg_din;
					6'b11z110: chrreg6 <= prg_din;
					6'b11z111: chrreg7 <= prg_din;
				endcase
		end
	always begin
		casez ({submapper1, mirror})
			2'b00: vram_a10 = {chr_ain[10]};
			2'b01: vram_a10 = {chr_ain[11]};
			2'b1z: vram_a10 = 1'b1;
		endcase
		casez ({prg_ain[14:13], prgmode})
			3'b000: prgsel = prgreg0;
			3'b001: prgsel = 5'b11110;
			3'b01z: prgsel = prgreg1;
			3'b100: prgsel = 5'b11110;
			3'b101: prgsel = prgreg0;
			3'b11z: prgsel = 5'b11111;
		endcase
		casez ({chr_ain[12:10]})
			3'b000: chrsel = chrreg0;
			3'b001: chrsel = chrreg1;
			3'b010: chrsel = chrreg2;
			3'b011: chrsel = chrreg3;
			3'b100: chrsel = chrreg4;
			3'b101: chrsel = chrreg5;
			3'b110: chrsel = chrreg6;
			3'b111: chrsel = chrreg7;
		endcase
	end
	wire [21:0] prg_ram = {9'b111100000, prg_ain[12:0]};
	wire prg_is_ram = (prg_ain[15:13] == 3'b011) && ram_support;
	assign vram_ce = chr_ain[13];
	assign prg_aout = (prg_is_ram ? prg_ram : {4'b0000, prgsel, prg_ain[12:0]});
	assign prg_allow = (prg_ain[15] && !prg_write) || prg_is_ram;
	assign chr_allow = flags[15];
	assign chr_aout = {4'b1000, chrsel, chr_ain[9:0]};
endmodule
module Mapper42 (
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
	reg irq;
	assign irq_b = (enable ? irq : 1'hz);
	reg [15:0] flags_out = 0;
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	wire [7:0] mapper = flags[7:0];
	reg [3:0] prg_bank;
	reg [3:0] chr_bank;
	reg [3:0] prg_sel;
	reg mirroring;
	reg irq_enable;
	reg [14:0] irq_counter;
	always @(posedge clk)
		if (~enable) begin
			prg_bank <= 0;
			chr_bank <= 0;
			mirroring <= flags[14];
			irq_counter <= 0;
		end
		else if (ce) begin
			if (prg_write)
				case (mapper)
					40:
						case (prg_ain & 16'he000)
							16'h8000: irq_enable <= 0;
							16'ha000: irq_enable <= 1;
							16'he000: prg_bank <= prg_din[2:0];
						endcase
					default:
						case (prg_ain & 16'he003)
							16'h8000: chr_bank <= prg_din[3:0];
							16'he000: prg_bank <= prg_din[3:0];
							16'he001: mirroring <= prg_din[3];
							16'he002: irq_enable <= prg_din[1];
						endcase
				endcase
			if (irq_enable)
				case (mapper)
					40: irq_counter <= irq_counter + 13'd1;
					default: irq_counter <= irq_counter + 15'd1;
				endcase
			else
				irq_counter <= 0;
			case (mapper)
				40: irq <= irq_counter[12];
				default: irq <= &irq_counter[14:13];
			endcase
		end
	always @(*)
		case (mapper)
			40:
				case (prg_ain[15:13])
					3'b011: prg_sel = 3'h6;
					3'b100: prg_sel = 3'h4;
					3'b101: prg_sel = 3'h5;
					3'b110: prg_sel = prg_bank;
					3'b111: prg_sel = 3'h7;
					default: prg_sel = 0;
				endcase
			default:
				case (prg_ain[15:13])
					3'b011: prg_sel = prg_bank;
					3'b100: prg_sel = 4'hc;
					3'b101: prg_sel = 4'hd;
					3'b110: prg_sel = 4'he;
					3'b111: prg_sel = 4'hf;
					default: prg_sel = 0;
				endcase
		endcase
	assign prg_aout = {5'b00000, prg_sel, prg_ain[12:0]};
	assign chr_aout = {5'b10000, chr_bank, chr_ain[12:0]};
	assign prg_allow = (prg_ain >= 16'h6000) && !prg_write;
	assign chr_allow = flags[15];
	assign vram_ce = chr_ain[13];
	wire [1:1] sv2v_tmp_C3571;
	assign sv2v_tmp_C3571 = (mirroring ? chr_ain[11] : chr_ain[10]);
	always @(*) vram_a10 = sv2v_tmp_C3571;
endmodule
module KS202 (
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
	reg irq;
	assign irq_b = (enable ? irq : 1'hz);
	reg [15:0] flags_out = 0;
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	reg [3:0] prg_bank [3:0];
	reg [2:0] bank_select;
	reg [4:0] irq_enable;
	reg [15:0] irq_latch;
	reg [15:0] irq_counter;
	always @(posedge clk)
		if (~enable) begin
			irq <= 0;
			irq_enable <= 0;
			irq_latch <= 0;
			bank_select <= 0;
			prg_bank[0] <= 0;
			prg_bank[1] <= 1;
			prg_bank[2] <= 2;
			prg_bank[3] <= 3;
		end
		else if (ce) begin
			irq_enable[3] <= 1'b0;
			if (prg_ain[15] & prg_write)
				case (prg_ain[14:12])
					3'b000: irq_latch[3:0] <= prg_din[3:0];
					3'b001: irq_latch[7:4] <= prg_din[3:0];
					3'b010: irq_latch[11:8] <= prg_din[3:0];
					3'b011: irq_latch[15:12] <= prg_din[3:0];
					3'b100: irq_enable[4:0] <= {2'b11, prg_din[2:0]};
					3'b101: irq_enable[4:3] <= 2'b01;
					3'b110: bank_select <= prg_din[2:0];
					3'b111:
						case (bank_select)
							1: prg_bank[0] <= prg_din[3:0];
							2: prg_bank[1] <= prg_din[3:0];
							3: prg_bank[2] <= prg_din[3:0];
							4: prg_bank[3] <= prg_din[3:0];
						endcase
				endcase
			if (irq_enable[1]) begin
				irq_counter[7:0] <= irq_counter[7:0] + 8'd1;
				if (irq_counter[7:0] == 8'hff) begin
					if (irq_enable[2])
						irq <= 1'b1;
					else begin
						irq_counter[15:8] <= irq_counter[15:8] + 8'd1;
						if (irq_counter[15:8] == 8'hff)
							irq <= 1'b1;
					end
				end
			end
			if (irq_enable[3]) begin
				irq <= 1'b0;
				if (irq_enable[4])
					irq_counter <= irq_latch;
			end
		end
	reg [3:0] prgout;
	always @(*)
		casez ({prg_ain[15:13]})
			3'b011: prgout = prg_bank[3];
			3'b100: prgout = prg_bank[0];
			3'b101: prgout = prg_bank[1];
			3'b110: prgout = prg_bank[2];
			3'b111: prgout = 4'b1111;
			default: prgout = 4'bxxxx;
		endcase
	assign vram_ce = chr_ain[13];
	wire [1:1] sv2v_tmp_D3ED4;
	assign sv2v_tmp_D3ED4 = (flags[14] ? chr_ain[10] : chr_ain[11]);
	always @(*) vram_a10 = sv2v_tmp_D3ED4;
	assign prg_aout = {2'b00, prgout[3:0], prg_ain[12:0]};
	assign prg_allow = (prg_ain >= 16'h6000) && !prg_write;
	assign chr_allow = flags[15];
	assign chr_aout = {8'b10000000, chr_ain[13:0]};
endmodule
module Mapper65 (
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
	reg irq;
	assign irq_b = (enable ? irq : 1'hz);
	reg [15:0] flags_out = 16'h0008;
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	reg [7:0] prg_bank_0;
	reg [7:0] prg_bank_1;
	reg [7:0] prg_bank_2;
	reg [7:0] chr_bank_0;
	reg [7:0] chr_bank_1;
	reg [7:0] chr_bank_2;
	reg [7:0] chr_bank_3;
	reg [7:0] chr_bank_4;
	reg [7:0] chr_bank_5;
	reg [7:0] chr_bank_6;
	reg [7:0] chr_bank_7;
	reg mirroring;
	reg irq_ack;
	reg irq_enable;
	reg [15:0] irq_reload;
	reg [15:0] irq_counter;
	always @(posedge clk)
		if (~enable) begin
			prg_bank_0 <= 8'h00;
			prg_bank_1 <= 8'h01;
			prg_bank_2 <= 8'hfe;
			chr_bank_0 <= 0;
			chr_bank_1 <= 0;
			chr_bank_2 <= 0;
			chr_bank_3 <= 0;
			chr_bank_4 <= 0;
			chr_bank_5 <= 0;
			chr_bank_6 <= 0;
			chr_bank_7 <= 0;
			mirroring <= 0;
			irq_reload <= 0;
			irq_counter <= 0;
			irq_enable <= 0;
		end
		else if (ce) begin
			irq_ack <= 1'b0;
			if (prg_write && prg_ain[15])
				case ({prg_ain[14:12], prg_ain[2:0]})
					6'b000000: prg_bank_0 <= prg_din;
					6'b010000: prg_bank_1 <= prg_din;
					6'b100000: prg_bank_2 <= prg_din;
					6'b011000: chr_bank_0 <= prg_din;
					6'b011001: chr_bank_1 <= prg_din;
					6'b011010: chr_bank_2 <= prg_din;
					6'b011011: chr_bank_3 <= prg_din;
					6'b011100: chr_bank_4 <= prg_din;
					6'b011101: chr_bank_5 <= prg_din;
					6'b011110: chr_bank_6 <= prg_din;
					6'b011111: chr_bank_7 <= prg_din;
					6'b001001: mirroring <= prg_din[7];
					6'b001011: {irq_ack, irq_enable} <= {1'b1, prg_din[7]};
					6'b001100: {irq_ack, irq_counter} <= {1'b1, irq_reload};
					6'b001101: irq_reload[15:8] <= prg_din;
					6'b001110: irq_reload[7:0] <= prg_din;
				endcase
			if (irq_enable) begin
				irq_counter <= irq_counter - 16'd1;
				if (irq_counter == 16'h0000) begin
					irq <= 1'b1;
					irq_enable <= 0;
					irq_counter <= 0;
				end
			end
			if (irq_ack)
				irq <= 1'b0;
		end
	always vram_a10 = (mirroring ? chr_ain[11] : chr_ain[10]);
	reg [7:0] prgsel;
	always case (prg_ain[14:13])
		2'b00: prgsel = prg_bank_0;
		2'b01: prgsel = prg_bank_1;
		2'b10: prgsel = prg_bank_2;
		2'b11: prgsel = 8'hff;
	endcase
	reg [7:0] chrsel;
	always casez (chr_ain[12:10])
		0: chrsel = chr_bank_0;
		1: chrsel = chr_bank_1;
		2: chrsel = chr_bank_2;
		3: chrsel = chr_bank_3;
		4: chrsel = chr_bank_4;
		5: chrsel = chr_bank_5;
		6: chrsel = chr_bank_6;
		7: chrsel = chr_bank_7;
	endcase
	assign chr_aout = {4'b1000, chrsel, chr_ain[9:0]};
	assign prg_aout = {2'b00, prgsel[6:0], prg_ain[12:0]};
	assign prg_allow = prg_ain[15] && !prg_write;
	assign chr_allow = flags[15];
	assign vram_ce = chr_ain[13];
endmodule
module Mapper41 (
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
	reg [15:0] flags_out = 0;
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	reg [2:0] prg_bank;
	reg [1:0] chr_outer_bank;
	reg [1:0] chr_inner_bank;
	reg mirroring;
	always @(posedge clk)
		if (~enable) begin
			prg_bank <= 0;
			chr_outer_bank <= 0;
			chr_inner_bank <= 0;
			mirroring <= 0;
		end
		else if (ce && prg_write) begin
			if (prg_ain[15:11] == 5'b01100)
				{mirroring, chr_outer_bank, prg_bank} <= prg_ain[5:0];
			else if (prg_ain[15] && prg_bank[2])
				chr_inner_bank <= prg_din[1:0];
		end
	assign prg_aout = {4'b0000, prg_bank, prg_ain[14:0]};
	assign chr_allow = flags[15];
	assign chr_aout = {5'b10000, chr_outer_bank, chr_inner_bank, chr_ain[12:0]};
	assign vram_ce = chr_ain[13];
	wire [1:1] sv2v_tmp_C3571;
	assign sv2v_tmp_C3571 = (mirroring ? chr_ain[11] : chr_ain[10]);
	always @(*) vram_a10 = sv2v_tmp_C3571;
	assign prg_allow = prg_ain[15] && !prg_write;
endmodule
module Mapper218 (
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
	assign prg_aout = {7'b0000000, prg_ain[14:0]};
	assign chr_allow = 1'b1;
	assign chr_aout = {9'b100000000, chr_ain[12:11], vram_a10, chr_ain[9:0]};
	assign vram_ce = 1'b1;
	wire [1:1] sv2v_tmp_58FEF;
	assign sv2v_tmp_58FEF = (flags[16] ? (flags[14] ? chr_ain[13] : chr_ain[12]) : (flags[14] ? chr_ain[10] : chr_ain[11]));
	always @(*) vram_a10 = sv2v_tmp_58FEF;
	assign prg_allow = prg_ain[15] && !prg_write;
endmodule
module Mapper228 (
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
	reg [15:0] flags_out = 0;
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	reg mirroring;
	reg [1:0] prg_chip;
	reg [4:0] prg_bank;
	reg prg_bank_mode;
	reg [5:0] chr_bank;
	always @(posedge clk)
		if (~enable) begin
			{mirroring, prg_chip, prg_bank, prg_bank_mode} <= 0;
			chr_bank <= 0;
		end
		else if (ce) begin
			if (prg_ain[15] & prg_write) begin
				{mirroring, prg_chip, prg_bank, prg_bank_mode} <= prg_ain[13:5];
				chr_bank <= {prg_ain[3:0], prg_din[1:0]};
			end
		end
	wire [1:1] sv2v_tmp_C3571;
	assign sv2v_tmp_C3571 = (mirroring ? chr_ain[11] : chr_ain[10]);
	always @(*) vram_a10 = sv2v_tmp_C3571;
	wire prglow = (prg_bank_mode ? prg_bank[0] : prg_ain[14]);
	wire [1:0] addrsel = {prg_chip[1], prg_chip[1] ^ prg_chip[0]};
	assign prg_aout = {1'b0, addrsel, prg_bank[4:1], prglow, prg_ain[13:0]};
	assign prg_allow = prg_ain[15] && !prg_write;
	assign chr_allow = flags[15];
	assign chr_aout = {3'b100, chr_bank, chr_ain[12:0]};
	assign vram_ce = chr_ain[13];
endmodule
module Mapper234 (
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
	reg [15:0] flags_out = 0;
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	reg [2:0] block;
	reg [2:0] inner_chr;
	reg mode;
	reg mirroring;
	reg inner_prg;
	always @(posedge clk)
		if (~enable) begin
			block <= 0;
			{mode, mirroring} <= 0;
			inner_chr <= 0;
			inner_prg <= 0;
		end
		else if (ce) begin
			if (prg_read && (prg_ain[15:7] == 9'b111111111)) begin
				if ((prg_ain[6:0] < 7'h20) && (block == 0)) begin
					{mirroring, mode} <= prg_din[7:6];
					block <= prg_din[3:1];
					{inner_chr[2], inner_prg} <= {prg_din[0], prg_din[0]};
				end
				if ((prg_ain[6:0] >= 7'h68) && (prg_ain[6:0] < 7'h78)) begin
					{inner_chr[2], inner_prg} <= (mode ? {prg_din[6], prg_din[0]} : {inner_chr[2], inner_prg});
					inner_chr[1:0] <= prg_din[5:4];
				end
			end
		end
	wire [1:1] sv2v_tmp_C3571;
	assign sv2v_tmp_C3571 = (mirroring ? chr_ain[11] : chr_ain[10]);
	always @(*) vram_a10 = sv2v_tmp_C3571;
	assign prg_aout = {3'b000, block, inner_prg, prg_ain[14:0]};
	assign chr_aout = {3'b100, block, inner_chr, chr_ain[12:0]};
	assign prg_allow = prg_ain[15] && !prg_write;
	assign chr_allow = flags[15];
	assign vram_ce = chr_ain[13];
endmodule
module Mapper246 (
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
	wire [15:0] flags_out = 0;
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	reg [7:0] prg_bank0;
	reg [7:0] prg_bank1;
	reg [7:0] prg_bank2;
	reg [7:0] prg_bank3;
	reg [7:0] chr_bank0;
	reg [7:0] chr_bank1;
	reg [7:0] chr_bank2;
	reg [7:0] chr_bank3;
	reg [7:0] prgsel;
	reg [7:0] chrsel;
	always @(posedge clk)
		if (~enable)
			prg_bank3 <= 8'hff;
		else if (ce) begin
			if (((prg_ain[15:8] == 8'h60) && !prg_ain[7:5]) && prg_write)
				case (prg_ain[2:0])
					3'd0: prg_bank0 <= prg_din;
					3'd1: prg_bank1 <= prg_din;
					3'd2: prg_bank2 <= prg_din;
					3'd3: prg_bank3 <= prg_din;
					3'd4: chr_bank0 <= prg_din;
					3'd5: chr_bank1 <= prg_din;
					3'd6: chr_bank2 <= prg_din;
					3'd7: chr_bank3 <= prg_din;
				endcase
		end
	always begin
		case (prg_ain[14:13])
			2'b00: prgsel = prg_bank0;
			2'b01: prgsel = prg_bank1;
			2'b10: prgsel = prg_bank2;
			2'b11: prgsel = prg_bank3;
		endcase
		case (chr_ain[12:11])
			2'b00: chrsel = chr_bank0;
			2'b01: chrsel = chr_bank1;
			2'b10: chrsel = chr_bank2;
			2'b11: chrsel = chr_bank3;
		endcase
	end
	wire [21:0] prg_ram = {9'b111100000, prg_ain[12:0]};
	wire prg_is_ram = prg_ain[15:11] == 5'b01101;
	wire [1:1] sv2v_tmp_D3ED4;
	assign sv2v_tmp_D3ED4 = (flags[14] ? chr_ain[10] : chr_ain[11]);
	always @(*) vram_a10 = sv2v_tmp_D3ED4;
	assign vram_ce = chr_ain[13];
	assign prg_aout = (prg_is_ram ? prg_ram : {1'b0, prgsel, prg_ain[12:0]});
	assign prg_allow = (prg_ain[15] & ~prg_write) | prg_is_ram;
	assign chr_allow = flags[15];
	assign chr_aout = {3'b100, chrsel, chr_ain[10:0]};
endmodule
module Mapper72 (
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
	reg [3:0] prg_bank;
	reg [3:0] chr_bank;
	wire [7:0] mapper = flags[7:0];
	reg last_prg;
	reg last_chr;
	wire mapper72 = mapper == 72;
	always @(posedge clk)
		if (~enable) begin
			prg_bank <= 0;
			chr_bank <= 0;
			last_prg <= 0;
			last_chr <= 0;
		end
		else if (ce) begin
			if (prg_ain[15] & prg_write) begin
				if (!last_prg && prg_din[7])
					{prg_bank} <= {prg_din[3:0]};
				if (!last_chr && prg_din[6])
					{chr_bank} <= {prg_din[3:0]};
				{last_prg, last_chr} <= prg_din[7:6];
			end
		end
	assign prg_aout = {4'b0000, (prg_ain[14] ^ mapper72 ? prg_bank : (mapper72 ? 4'b1111 : 4'b0000)), prg_ain[13:0]};
	assign prg_allow = prg_ain[15] && !prg_write;
	assign chr_allow = flags[15];
	assign chr_aout = {5'b10000, chr_bank, chr_ain[12:0]};
	assign vram_ce = chr_ain[13];
	wire [1:1] sv2v_tmp_D3ED4;
	assign sv2v_tmp_D3ED4 = (flags[14] ? chr_ain[10] : chr_ain[11]);
	always @(*) vram_a10 = sv2v_tmp_D3ED4;
endmodule
module Mapper162 (
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
	reg _sv2v_0;
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
	reg [15:0] flags_out = 0;
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	wire [1:0] reg_a = (flags[7:0] == 162 ? 2'd1 : 2'd2);
	wire [1:0] reg_b = (flags[7:0] == 162 ? 2'd2 : 2'd1);
	reg [31:0] state;
	reg [7:0] prg_bank;
	always @(*) begin
		if (_sv2v_0)
			;
		case ({state[2], 1'b0, state[0]})
			0: prg_bank = {state[((3 - reg_b) * 8) + 3-:4], state[27-:2], state[((3 - reg_a) * 8) + 1], 1'b0};
			1: prg_bank = {state[((3 - reg_b) * 8) + 3-:4], state[27-:2], 2'b00};
			4: prg_bank = {state[((3 - reg_b) * 8) + 3-:4], state[27-:3], state[((3 - reg_a) * 8) + 1]};
			5: prg_bank = {state[((3 - reg_b) * 8) + 3-:4], state[27-:4]};
		endcase
	end
	always @(posedge clk)
		if (~enable)
			state <= 32'h03000007;
		else if (ce) begin
			if ((prg_ain[14:12] == 3'b101) && prg_write)
				state[(3 - prg_ain[9:8]) * 8+:8] <= prg_din;
		end
	wire prg_is_ram = (prg_ain >= 'h6000) && (prg_ain < 'h8000);
	wire [21:0] prg_ram = {9'b111100000, prg_ain[12:0]};
	assign prg_aout = (prg_is_ram ? prg_ram : {prg_bank[5:0], prg_ain[14:0]});
	assign prg_allow = (prg_ain[15] && !prg_write) || prg_is_ram;
	assign chr_allow = flags[15];
	assign chr_aout = {9'b100000000, chr_ain[12:0]};
	assign vram_ce = chr_ain[13];
	wire [1:1] sv2v_tmp_D3ED4;
	assign sv2v_tmp_D3ED4 = (flags[14] ? chr_ain[10] : chr_ain[11]);
	always @(*) vram_a10 = sv2v_tmp_D3ED4;
	initial _sv2v_0 = 0;
endmodule
module Mapper164 (
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
	reg [15:0] flags_out = 0;
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	reg [7:0] prg_bank;
	always @(posedge clk)
		if (~enable)
			prg_bank <= 8'h0f;
		else if (ce) begin
			if (prg_write)
				case (prg_ain & 16'h7300)
					'h5000: prg_bank[3:0] <= prg_din[3:0];
					'h5100: prg_bank[7:4] <= prg_din[3:0];
				endcase
		end
	wire prg_is_ram = (prg_ain >= 'h6000) && (prg_ain < 'h8000);
	wire [21:0] prg_ram = {9'b111100000, prg_ain[12:0]};
	assign prg_aout = (prg_is_ram ? prg_ram : {prg_bank[5:0], prg_ain[14:0]});
	assign prg_allow = (prg_ain[15] && !prg_write) || prg_is_ram;
	assign chr_allow = flags[15];
	assign chr_aout = {9'b100000000, chr_ain[12:0]};
	assign vram_ce = chr_ain[13];
	wire [1:1] sv2v_tmp_D3ED4;
	assign sv2v_tmp_D3ED4 = (flags[14] ? chr_ain[10] : chr_ain[11]);
	always @(*) vram_a10 = sv2v_tmp_D3ED4;
endmodule
module Nanjing (
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
	ppuflags,
	ppu_ce
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
	input [19:0] ppuflags;
	input ppu_ce;
	wire [21:0] prg_aout;
	assign prg_aout_b = (enable ? prg_aout : 22'hzzzzzz);
	reg [7:0] prg_dout;
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
	reg prg_bus_write;
	wire [15:0] flags_out = {14'd0, prg_bus_write, 1'b0};
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	reg [7:0] prg_bank;
	reg chr_bank;
	reg chr_switch;
	reg trigger;
	reg trig_comp;
	reg [31:0] security;
	wire [8:0] scanline = ppuflags[19:11];
	wire [8:0] cycle = ppuflags[10:2];
	always @(posedge clk) begin
		if (~enable) begin
			prg_bank <= 8'h0f;
			trigger <= 0;
			security <= 32'h00000000;
			chr_switch <= 0;
			trig_comp <= 1;
		end
		else if (ce) begin
			prg_dout <= prg_din;
			prg_bus_write <= 0;
			if (prg_write) begin
				if (prg_ain == 16'h5101) begin
					if (trig_comp && ~|prg_din)
						trigger <= ~trigger;
					trig_comp <= |prg_din;
				end
				else
					case (prg_ain & 16'h7300)
						'h5000: begin
							prg_bank[3:0] <= prg_din[3:0];
							chr_switch <= prg_din[7];
							security[24+:8] <= prg_din;
						end
						'h5100: begin
							security[16+:8] <= prg_din;
							if (prg_din == 6)
								prg_bank <= 8'h03;
						end
						'h5200: begin
							prg_bank[7:4] <= prg_din[3:0];
							security[8+:8] <= prg_din;
						end
						'h5300: security[0+:8] <= prg_din;
					endcase
			end
			else if (prg_read) begin
				prg_bus_write <= 1'b1;
				case (prg_ain & 16'h7700)
					'h5100: prg_dout <= ((security[24+:8] | security[16+:8]) | security[0+:8]) | (security[8+:8] ^ 8'hff);
					'h5500: prg_dout <= (trigger ? security[0+:8] | security[24+:8] : 8'h00);
					default: begin
						prg_dout <= 8'hff;
						prg_bus_write <= 0;
					end
				endcase
			end
		end
		if (~enable)
			chr_bank <= 0;
		else if (ppu_ce) begin
			if (cycle > 254) begin
				if (scanline == 239)
					chr_bank <= 0;
				else if (scanline == 127)
					chr_bank <= 1;
			end
		end
	end
	wire prg_is_ram = (prg_ain >= 'h6000) && (prg_ain < 'h8000);
	wire [21:0] prg_ram = {9'b111100000, prg_ain[12:0]};
	assign prg_aout = (prg_is_ram ? prg_ram : {prg_bank[5:0], prg_ain[14:0]});
	assign prg_allow = (prg_ain[15] && !prg_write) || prg_is_ram;
	assign chr_allow = flags[15];
	assign chr_aout = {9'b100000000, (chr_switch ? chr_bank : chr_ain[12]), chr_ain[11:0]};
	assign vram_ce = chr_ain[13];
	assign vram_a10 = (flags[14] ? chr_ain[10] : chr_ain[11]);
endmodule
module Mapper156 (
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
	wire [7:0] prg_dout = 0;
	assign prg_dout_b = (enable ? prg_dout : 8'hzz);
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
	reg [7:0] prg_bank;
	reg [7:0] chr_bank_lo [7:0];
	reg [7:0] chr_bank_hi [7:0];
	reg [1:0] mirroring;
	always @(posedge clk)
		if (~enable) begin
			chr_bank_lo[0] <= 0;
			chr_bank_lo[1] <= 0;
			chr_bank_lo[2] <= 0;
			chr_bank_lo[3] <= 0;
			chr_bank_lo[4] <= 0;
			chr_bank_lo[5] <= 0;
			chr_bank_lo[6] <= 0;
			chr_bank_lo[7] <= 0;
			chr_bank_hi[0] <= 0;
			chr_bank_hi[1] <= 0;
			chr_bank_hi[2] <= 0;
			chr_bank_hi[3] <= 0;
			chr_bank_hi[4] <= 0;
			chr_bank_hi[5] <= 0;
			chr_bank_hi[6] <= 0;
			chr_bank_hi[7] <= 0;
			prg_bank = 0;
			mirroring <= 2'b00;
		end
		else if (ce && prg_write) begin
			if ((prg_ain[15:4] == 12'hc00) && (prg_ain[2] == 1'b0))
				chr_bank_lo[{prg_ain[3], prg_ain[1:0]}] <= prg_din;
			else if ((prg_ain[15:4] == 12'hc00) && (prg_ain[2] == 1'b1))
				chr_bank_hi[{prg_ain[3], prg_ain[1:0]}] <= prg_din;
			else if (prg_ain[15:0] == 16'hc010)
				prg_bank <= prg_din;
			else if (prg_ain[15:0] == 16'hc014)
				mirroring <= {1'b1, !prg_din[0]};
		end
	wire [7:0] chr_lo = chr_bank_lo[chr_ain[12:10]];
	wire [7:0] chr_hi = chr_bank_hi[chr_ain[12:10]];
	reg [9:0] chrsel;
	always @(*) chrsel = {chr_hi[1:0], chr_lo[7:0]};
	wire [7:0] prg_aout_tmp = (prg_ain[14] == 1'b1 ? 8'hff : prg_bank);
	wire prg_is_ram = prg_ain[15:13] == 3'b011;
	assign prg_allow = (prg_ain[15] && !prg_write) || prg_is_ram;
	wire [21:0] prg_ram = {9'b111100000, prg_ain[12:0]};
	assign prg_aout = (prg_is_ram ? prg_ram : {1'b0, prg_aout_tmp[6:0], prg_ain[13:0]});
	assign chr_allow = flags[15];
	assign chr_aout = {2'b10, chrsel, chr_ain[9:0]};
	assign vram_ce = chr_ain[13];
	wire [1:1] sv2v_tmp_E9996;
	assign sv2v_tmp_E9996 = (mirroring[1] ? (mirroring[0] ? chr_ain[10] : chr_ain[11]) : 1'b0);
	always @(*) vram_a10 = sv2v_tmp_E9996;
endmodule
module Mapper200 (
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
	wire [15:0] flags_out = 0;
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	reg [3:0] bank;
	always @(posedge clk)
		if (~enable)
			bank <= 0;
		else if ((ce && prg_write) && prg_ain[15])
			bank <= prg_ain[3:0];
	assign prg_aout = {4'b0000, bank, prg_ain[13:0]};
	assign prg_allow = prg_ain[15] && !prg_write;
	assign chr_aout = {5'b10000, bank, chr_ain[12:0]};
	assign chr_allow = flags[15];
	assign vram_ce = chr_ain[13];
	wire [1:1] sv2v_tmp_33EB9;
	assign sv2v_tmp_33EB9 = (bank[3] ? chr_ain[11] : chr_ain[10]);
	always @(*) vram_a10 = sv2v_tmp_33EB9;
endmodule
module Mapper225 (
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
	reg [7:0] prg_dout;
	assign prg_dout_b = (enable ? prg_dout : 8'hzz);
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
	wire [7:0] mapper = flags[7:0];
	wire mapper255 = mapper == 8'd255;
	wire prg_ram = prg_ain[15:11] == 5'b01011;
	wire prg_bus_write = ~mapper255 & prg_ram;
	wire [15:0] flags_out = {14'h0000, prg_bus_write, 1'b0};
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	reg [14:0] bank_mode;
	wire mirroring = bank_mode[13];
	wire prg_mode = bank_mode[12];
	reg [3:0] ram [3:0];
	always @(posedge clk)
		if (~enable)
			;
		else if (ce) begin
			if (prg_ain[15] && prg_write)
				bank_mode <= prg_ain[14:0];
			if (prg_ram && prg_write)
				ram[prg_ain[1:0]] <= prg_din[3:0];
		end
	wire [8:1] sv2v_tmp_489D4;
	assign sv2v_tmp_489D4 = {4'h0, ram[prg_ain[1:0]]};
	always @(*) prg_dout = sv2v_tmp_489D4;
	assign prg_aout = {1'b0, bank_mode[14], bank_mode[11:7], (prg_mode ? bank_mode[6] : prg_ain[14]), prg_ain[13:0]};
	assign prg_allow = prg_ain[15] && !prg_write;
	assign chr_allow = flags[15];
	assign chr_aout = {2'b10, bank_mode[14], bank_mode[5:0], chr_ain[12:0]};
	assign vram_ce = chr_ain[13];
	wire [1:1] sv2v_tmp_C3571;
	assign sv2v_tmp_C3571 = (mirroring ? chr_ain[11] : chr_ain[10]);
	always @(*) vram_a10 = sv2v_tmp_C3571;
endmodule
module Mapper227 (
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
	wire [15:0] flags_out = 16'd0;
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	reg [10:0] bank_reg;
	wire menu = bank_reg[10];
	wire last_bank = bank_reg[9];
	wire prg_mode = bank_reg[7];
	wire [5:0] prg_bank_t = {bank_reg[8], bank_reg[6:2]};
	wire mirroring = bank_reg[1];
	wire prg_size = bank_reg[0];
	wire battery = flags[25];
	wire [3:0] submapper = flags[24:21];
	wire chr_ram_wr_en = ~prg_mode | battery;
	reg [5:0] prg_bank;
	wire prg_bank_a0 = (prg_size ? prg_ain[14] : prg_bank_t[0]);
	wire [3:1] sv2v_tmp_A318C;
	assign sv2v_tmp_A318C = prg_bank_t[5:3];
	always @(*) prg_bank[5:3] = sv2v_tmp_A318C;
	wire [3:1] sv2v_tmp_EA926;
	assign sv2v_tmp_EA926 = (prg_mode | ~prg_ain[14] ? {prg_bank_t[2:1], prg_bank_a0} : {3 {last_bank}});
	always @(*) prg_bank[2:0] = sv2v_tmp_EA926;
	always @(posedge clk)
		if (~enable)
			bank_reg <= 0;
		else if (ce) begin
			if (prg_ain[15] && prg_write)
				bank_reg <= prg_ain[10:0];
		end
	wire [3:0] prg_a3_0 = (menu ? submapper : prg_ain[3:0]);
	assign prg_aout = {2'b00, prg_bank, prg_ain[13:4], prg_a3_0};
	assign prg_allow = prg_ain[15] && !prg_write;
	assign chr_allow = flags[15] & chr_ram_wr_en;
	assign chr_aout = {9'b100000000, chr_ain[12:0]};
	assign vram_ce = chr_ain[13];
	wire [1:1] sv2v_tmp_C3571;
	assign sv2v_tmp_C3571 = (mirroring ? chr_ain[11] : chr_ain[10]);
	always @(*) vram_a10 = sv2v_tmp_C3571;
endmodule
module NSF (
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
	chr_dout_b,
	chr_allow_b,
	vram_a10_b,
	vram_ce_b,
	irq_b,
	audio_in,
	audio_b,
	exp_audioe,
	flags_out_b,
	chr_write,
	fds_din
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
	inout [7:0] chr_dout_b;
	inout chr_allow_b;
	inout vram_a10_b;
	inout vram_ce_b;
	inout irq_b;
	input [15:0] audio_in;
	inout [15:0] audio_b;
	output wire [5:0] exp_audioe;
	inout [15:0] flags_out_b;
	input chr_write;
	input [7:0] fds_din;
	wire [21:0] prg_aout;
	assign prg_aout_b = (enable ? prg_aout : 22'hzzzzzz);
	reg [7:0] prg_dout;
	assign prg_dout_b = (enable ? prg_dout : 8'hzz);
	wire prg_allow;
	assign prg_allow_b = (enable ? prg_allow : 1'hz);
	wire [21:0] chr_aout;
	assign chr_aout_b = (enable ? chr_aout : 22'hzzzzzz);
	wire [7:0] chr_dout;
	assign chr_dout_b = (enable ? chr_dout : 8'hzz);
	wire chr_allow;
	assign chr_allow_b = (enable ? chr_allow : 1'hz);
	reg vram_a10;
	assign vram_a10_b = (enable ? vram_a10 : 1'hz);
	wire vram_ce;
	assign vram_ce_b = (enable ? vram_ce : 1'hz);
	assign irq_b = (enable ? 1'b0 : 1'hz);
	wire has_chr_dout;
	reg prg_bus_write;
	wire [15:0] flags_out = {14'd0, prg_bus_write, has_chr_dout};
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {audio_in[15:0]} : 16'hzzzz);
	reg [7:0] midi_reg [31:0];
	reg [7:0] nsf_reg [15:0];
	assign exp_audioe = (enable ? (nsf_reg[3][5:0] == 6'd0 ? {2'b00, midi_reg[5'd7][3], 3'b000} : nsf_reg[3][5:0]) : 6'h00);
	wire [3:0] submapper = flags[24:21];
	wire IsNSF = submapper == 4'hf;
	reg [15:0] counter;
	reg [5:0] clk1MHz;
	reg [7:0] multiplier_1;
	reg [7:0] multiplier_2;
	wire [15:0] multiply_result = multiplier_1 * multiplier_2;
	reg [7:0] apu_reg [31:0];
	reg [7:0] mmc5_reg [15:0];
	reg [7:0] vrc6_reg [15:0];
	reg [7:0] ssb5_reg [15:0];
	reg [3:0] ssb5_add;
	reg [7:0] fds_reg [15:0];
	reg [7:0] n163_reg [63:0];
	reg autoinc;
	reg [6:0] ram_ain;
	reg do_inc;
	reg [7:0] vrc7_reg [31:0];
	reg [4:0] vrc7_add;
	integer i;
	always @(posedge clk) begin
		clk1MHz <= clk1MHz + 1'b1;
		if (clk1MHz == 6'd42)
			clk1MHz <= 6'd0;
		if ((clk1MHz == 6'd21) || (clk1MHz == 6'd42)) begin
			counter <= counter - 1'b1;
			if (counter == 16'h0000) begin
				counter <= {nsf_reg[1], nsf_reg[0]};
				nsf_reg[2] <= 8'h80;
			end
		end
		if (~enable) begin
			nsf_reg[4'h3] <= 8'h00;
			nsf_reg[4'h6] <= 8'h06;
			nsf_reg[4'h7] <= 8'h07;
			nsf_reg[4'h8] <= 8'h00;
			nsf_reg[4'h9] <= 8'h01;
			nsf_reg[4'ha] <= 8'h02;
			nsf_reg[4'hb] <= 8'h03;
			nsf_reg[4'hc] <= 8'h04;
			nsf_reg[4'hd] <= 8'h05;
			nsf_reg[4'he] <= 8'h06;
			nsf_reg[4'hf] <= 8'hff;
			for (i = 0; i < 32; i = i + 1)
				apu_reg[i] <= i[7:0];
			for (i = 0; i < 32; i = i + 1)
				midi_reg[i] <= 8'h00;
			for (i = 0; i < 16; i = i + 1)
				vrc6_reg[i] <= 8'h00;
			for (i = 0; i < 16; i = i + 1)
				ssb5_reg[i] <= 8'h00;
			for (i = 0; i < 16; i = i + 1)
				fds_reg[i] <= 8'h00;
		end
		else if (ce) begin
			if ((prg_ain[15:4] == 12'h5ff) && prg_write)
				nsf_reg[prg_ain[3:0]] <= prg_din;
			if ((prg_ain == 16'h5ff2) && prg_write)
				nsf_reg[2] <= 8'h00;
			if ((prg_ain == 16'h5205) && prg_write)
				multiplier_1 <= prg_din;
			if ((prg_ain == 16'h5206) && prg_write)
				multiplier_2 <= prg_din;
			if ((prg_ain[15:5] == 11'b01000000000) && prg_write)
				apu_reg[prg_ain[4:0]] <= prg_din;
			if ((prg_ain[15:5] == 11'b01000000001) && prg_write)
				midi_reg[prg_ain[4:0]] <= prg_din;
			if (((prg_ain[15:5] == 11'b01010000000) && (prg_ain[3] == 1'b0)) && prg_write)
				mmc5_reg[{prg_ain[4], prg_ain[2:0]}] <= prg_din;
			if ((((prg_ain[15:14] == 2'b10) && (prg_ain[13:12] != 2'b00)) && (prg_ain[11:2] == 10'b0000000000)) && prg_write)
				vrc6_reg[{prg_ain[13:12], prg_ain[1:0]}] <= prg_din;
			if ((prg_ain[15:0] == 16'hc000) && prg_write)
				ssb5_add <= prg_din[3:0];
			if ((prg_ain[15:0] == 16'he000) && prg_write)
				ssb5_reg[ssb5_add] <= prg_din;
			if ((prg_ain[15:4] == 12'h408) && prg_write)
				fds_reg[prg_ain[3:0]] <= prg_din;
			do_inc <= 0;
			if (do_inc)
				ram_ain <= ram_ain + 1'd1;
			if ((prg_ain == 16'hf800) && prg_write)
				{autoinc, ram_ain} <= prg_din;
			else if ((prg_ain == 16'h4800) & autoinc)
				do_inc <= 1;
			if (((prg_ain == 16'h4800) && prg_write) && ram_ain[6])
				n163_reg[ram_ain[5:0]] <= prg_din;
			if ((prg_ain[15:0] == 16'h9010) && prg_write)
				vrc7_add <= {prg_din[5:4], prg_din[2:0]};
			if ((prg_ain[15:0] == 16'h9030) && prg_write)
				vrc7_reg[vrc7_add] <= prg_din;
		end
	end
	reg [9:0] prg_bank;
	always casez ({prg_ain[15:12], exp_audioe[2]})
		5'b00zzz: prg_bank = 10'h000;
		5'b0100z: prg_bank = 10'h000;
		5'b0101z: prg_bank = 10'b1111100000;
		5'b011z0: prg_bank = {9'b111100000, prg_ain[12]};
		5'b011z1: prg_bank = {2'b01, nsf_reg[{3'b011, prg_ain[12]}]};
		5'b1zzzz: prg_bank = {2'b01, nsf_reg[{1'b1, prg_ain[14:12]}]};
	endcase
	reg [4:0] ppu_line;
	always @(posedge clk)
		if (((chr_ain[13:11] == 3'b100) && (chr_ain[9:6] != 4'b1111)) && chr_read)
			ppu_line <= chr_ain[9:5];
	wire pul0 = ppu_line[4:1] == 4'd2;
	wire pul1 = ppu_line[4:1] == 4'd3;
	wire tria = ppu_line[4:1] == 4'd4;
	wire nois = ppu_line[4:1] == 4'd5;
	wire samp = ppu_line[4:1] == 4'd6;
	wire n163_max = n163_reg[6'h3f][6];
	wire m5pul0 = ((ppu_line[4:1] == 4'd7) && !(exp_audioe[4] && n163_max)) && !exp_audioe[1];
	wire m5pul1 = ((ppu_line[4:1] == 4'd8) && !(exp_audioe[4] && n163_max)) && !exp_audioe[1];
	wire m5samp = (((ppu_line[4:1] == 4'd9) && !exp_audioe[4]) && !exp_audioe[2]) && !exp_audioe[1];
	wire v6pul0 = (((ppu_line[4:1] == 4'd10) && !exp_audioe[5]) && !exp_audioe[4]) && !exp_audioe[1];
	wire v6pul1 = (((ppu_line[4:1] == 4'd11) && !exp_audioe[5]) && !exp_audioe[4]) && !exp_audioe[1];
	wire v6saw = (((ppu_line[4:1] == 4'd12) && !exp_audioe[5]) && !exp_audioe[4]) && !exp_audioe[1];
	wire s5pul0 = (ppu_line[4:1] == 4'd10) && exp_audioe[5];
	wire s5pul1 = (ppu_line[4:1] == 4'd11) && exp_audioe[5];
	wire s5pul2 = (ppu_line[4:1] == 4'd12) && exp_audioe[5];
	wire fds = ((ppu_line[4:1] == 4'd9) && exp_audioe[2]) && !exp_audioe[4];
	wire n163_0 = (ppu_line[4:1] == 4'd9) && exp_audioe[4];
	wire n163_1 = ((ppu_line[4:1] == 4'd10) && !exp_audioe[5]) && exp_audioe[4];
	wire n163_2 = ((ppu_line[4:1] == 4'd11) && !exp_audioe[5]) && exp_audioe[4];
	wire n163_3 = ((ppu_line[4:1] == 4'd12) && !exp_audioe[5]) && exp_audioe[4];
	wire n163_4 = ((ppu_line[4:1] == 4'd13) && exp_audioe[4]) && n163_max;
	wire n163_5 = ((ppu_line[4:1] == 4'd14) && exp_audioe[4]) && n163_max;
	wire n163_6 = ((ppu_line[4:1] == 4'd7) && exp_audioe[4]) && n163_max;
	wire n163_7 = ((ppu_line[4:1] == 4'd8) && exp_audioe[4]) && n163_max;
	wire vrc7_0 = ((ppu_line[4:1] == 4'd7) && !(exp_audioe[4] && n163_max)) && exp_audioe[1];
	wire vrc7_1 = ((ppu_line[4:1] == 4'd8) && !(exp_audioe[4] && n163_max)) && exp_audioe[1];
	wire vrc7_2 = ((ppu_line[4:1] == 4'd9) && !exp_audioe[4]) && exp_audioe[1];
	wire vrc7_3 = ((ppu_line[4:1] == 4'd10) && !exp_audioe[4]) && exp_audioe[1];
	wire vrc7_4 = ((ppu_line[4:1] == 4'd11) && !exp_audioe[4]) && exp_audioe[1];
	wire vrc7_5 = ((ppu_line[4:1] == 4'd12) && !exp_audioe[4]) && exp_audioe[1];
	wire apu_type = (((pul0 | pul1) | tria) | nois) | samp;
	wire mmc5_type = (m5samp | m5pul0) | m5pul1;
	wire vrc6_type = (v6pul0 | v6pul1) | v6saw;
	wire ssb5_type = (s5pul0 | s5pul1) | s5pul2;
	wire fds_type = fds;
	wire n163_type = ((((((n163_0 | n163_1) | n163_2) | n163_3) | n163_4) | n163_5) | n163_6) | n163_7;
	wire vrc7_type = ((((vrc7_0 | vrc7_1) | vrc7_2) | vrc7_3) | vrc7_4) | vrc7_5;
	wire [2:0] n163_idx = ~(n163_7 ? 3'd7 : (n163_6 ? 3'd6 : (n163_5 ? 3'd5 : (n163_4 ? 3'd4 : (n163_3 ? 3'd3 : (n163_2 ? 3'd2 : (n163_1 ? 3'd1 : 3'd0)))))));
	wire [2:0] vrc7_idx = (vrc7_5 ? 3'd5 : (vrc7_4 ? 3'd4 : (vrc7_3 ? 3'd3 : (vrc7_2 ? 3'd2 : (vrc7_1 ? 3'd1 : 3'd0)))));
	wire apu_off = !midi_reg[5'h0b][{1'b0, samp, tria | nois, pul1 | nois}];
	wire vrc6_off = !vrc6_reg[{!v6pul0, !v6pul1, 2'b10}][7];
	wire fds_off = fds_reg[9][7];
	wire [1:0] ssb5_idx = {s5pul2, s5pul1};
	wire ssb5_off = ssb5_reg[7][ssb5_idx] & ssb5_reg[7][ssb5_idx + 3'd3];
	wire mmc5_off = (m5samp ? (mmc5_reg[4'h8] == 0) && (mmc5_reg[4'h9] == 0) : !mmc5_reg[4'hd][!m5pul0]);
	wire n163_off = n163_reg[6'h3f][6:4] < ~n163_idx;
	wire vrc7_off = 1'b0;
	wire voi_off = (ssb5_type ? ssb5_off : (n163_type ? n163_off : (vrc6_type ? vrc6_off : (vrc7_type ? vrc7_off : (mmc5_type ? mmc5_off : (fds_type ? fds_off : apu_off))))));
	wire [3:0] puls_vol = apu_reg[{2'b00, pul1, 2'b00}][3:0];
	wire [3:0] tria_vol = (|apu_reg[5'h08][6:0] ? 4'hf : 4'h0);
	wire [3:0] nois_vol = apu_reg[12][3:0];
	wire [3:0] samp_vol = 4'hf;
	wire [3:0] apu_vol = (samp ? samp_vol : (nois ? nois_vol : (tria ? tria_vol : puls_vol)));
	wire [3:0] vrc6_pul_vol = vrc6_reg[{!v6pul0, !v6pul1, 2'b00}][3:0];
	wire [3:0] vrc6_saw_vol = {vrc6_reg[4'b1100][5:3], |vrc6_reg[4'b1100][2:0]};
	wire [3:0] vrc6_vol = (v6saw ? vrc6_saw_vol : vrc6_pul_vol);
	wire [3:0] fds_vol = {fds_reg[0][5:3], |fds_reg[0][2:0]};
	wire [3:0] ssb5_vol = ssb5_reg[{2'b10, ssb5_idx}][3:0];
	wire [3:0] mmc5_samp_vol = 4'hf;
	wire [3:0] mmc5_pul_vol = mmc5_reg[{1'b0, m5pul1, 2'b00}][3:0];
	wire [3:0] mmc5_vol = (m5samp ? mmc5_samp_vol : mmc5_pul_vol);
	wire [3:0] n163_vol = n163_reg[{n163_idx, 3'b111}][3:0];
	wire [3:0] vrc7_vol = vrc7_reg[{2'b11, vrc7_idx}][3:0];
	wire [3:0] voi_vol = (ssb5_type ? ssb5_vol : (n163_type ? n163_vol : (vrc6_type ? vrc6_vol : (vrc7_type ? vrc7_vol : (mmc5_type ? mmc5_vol : (fds_type ? fds_vol : apu_vol))))));
	wire [4:0] n_freq = {1'b0, ~apu_reg[5'h0e][3:0]};
	wire [4:0] s_freq = {1'b0, apu_reg[5'h10][3:0]};
	wire [4:0] ms_freq = (mmc5_reg[4'h8][0] ? 5'h01 : 5'h00);
	wire [4:0] freq = (nois ? n_freq : (samp ? s_freq : ms_freq));
	wire use_freq = (nois | samp) | m5samp;
	reg [4:0] voi_tab_idx;
	always casez ({n163_max, exp_audioe, ppu_line})
		12'bzzzzzzz000zz: voi_tab_idx = 5'd0;
		12'bzzzzzzz001zz: voi_tab_idx = {4'd0, ppu_line[1]};
		12'bzzzzzzz010zz: voi_tab_idx = {4'd1, ppu_line[1]};
		12'bzzzzzzz0110z: voi_tab_idx = 5'd0;
		12'bzz0zz0z0111z: voi_tab_idx = 5'd3;
		12'bzz0zz0z1000z: voi_tab_idx = 5'd4;
		12'b0z1zzzz0111z: voi_tab_idx = 5'd3;
		12'b0z1zzzz1000z: voi_tab_idx = 5'd4;
		12'bzz0zz1z0111z: voi_tab_idx = 5'd20;
		12'bzz0zz1z1000z: voi_tab_idx = 5'd21;
		12'b1z1zzzz0111z: voi_tab_idx = 5'd18;
		12'b1z1zzzz1000z: voi_tab_idx = 5'd19;
		12'bzz0z1zz1001z: voi_tab_idx = 5'd12;
		12'bzz0z00z1001z: voi_tab_idx = 5'd0;
		12'bzz0z01z1001z: voi_tab_idx = 5'd22;
		12'bzz1zzzz1001z: voi_tab_idx = 5'd8;
		12'bz00zz0z101zz: voi_tab_idx = {(!ppu_line[1] ? 5'd5 : 5'd6)};
		12'bz00zz0z1100z: voi_tab_idx = 5'd7;
		12'bz1zzzzz101zz: voi_tab_idx = {(!ppu_line[1] ? 5'd13 : 5'd14)};
		12'bz1zzzzz1100z: voi_tab_idx = 5'd15;
		12'bz00zz1z1010z: voi_tab_idx = 5'd23;
		12'bz00zz1z1011z: voi_tab_idx = 5'd24;
		12'bz00zz1z1100z: voi_tab_idx = 5'd25;
		12'bz01zzzz1010z: voi_tab_idx = 5'd9;
		12'bz01zzzz1011z: voi_tab_idx = 5'd10;
		12'bz01zzzz1100z: voi_tab_idx = 5'd11;
		12'b1z1zzzz1101z: voi_tab_idx = 5'd16;
		12'b1z1zzzz1110z: voi_tab_idx = 5'd17;
		12'b0zzzzzz1101z: voi_tab_idx = 5'd0;
		12'b0zzzzzz1110z: voi_tab_idx = 5'd0;
		12'b1z0zzzz1101z: voi_tab_idx = 5'd0;
		12'b1z0zzzz1110z: voi_tab_idx = 5'd0;
		12'bzzzzzzz1111z: voi_tab_idx = 5'd0;
	endcase
	reg [4:0] find_count;
	reg [4:0] find_idx;
	wire [11:0] period [25:0];
	assign period[0] = {1'b0, apu_reg[3][2:0], apu_reg[2][7:0]};
	assign period[1] = {1'b0, apu_reg[7][2:0], apu_reg[6][7:0]};
	assign period[2] = {apu_reg[11][2:0], apu_reg[10][7:0], 1'b0};
	assign period[3] = (exp_audioe[3] | 1 ? {1'b0, mmc5_reg[3][2:0], mmc5_reg[2][7:0]} : 12'hfff);
	assign period[4] = (exp_audioe[3] | 1 ? {1'b0, mmc5_reg[7][2:0], mmc5_reg[6][7:0]} : 12'hfff);
	assign period[5] = (exp_audioe[0] ? {vrc6_reg[6][3:0], vrc6_reg[5][7:0]} : 12'hfff);
	assign period[6] = (exp_audioe[0] ? {vrc6_reg[10][3:0], vrc6_reg[9][7:0]} : 12'hfff);
	assign period[7] = (exp_audioe[0] ? {vrc6_reg[14][3:0], vrc6_reg[13][7:0]} : 12'hfff);
	assign period[8] = (exp_audioe[4] ? {n163_reg[6'b111100][1:0], n163_reg[6'b111010][7:0], n163_reg[6'b111000][7:6]} : 12'hfff);
	assign period[9] = (exp_audioe[4] ? {n163_reg[6'b110100][1:0], n163_reg[6'b110010][7:0], n163_reg[6'b110000][7:6]} : 12'hfff);
	assign period[10] = (exp_audioe[4] ? {n163_reg[6'b101100][1:0], n163_reg[6'b101010][7:0], n163_reg[6'b101000][7:6]} : 12'hfff);
	assign period[11] = (exp_audioe[4] ? {n163_reg[6'b100100][1:0], n163_reg[6'b100010][7:0], n163_reg[6'b100000][7:6]} : 12'hfff);
	assign period[12] = (exp_audioe[2] ? {fds_reg[3][3:0], fds_reg[2][7:0]} : 12'hfff);
	assign period[13] = (exp_audioe[5] ? {ssb5_reg[1][2:0], ssb5_reg[0][7:0], 1'b1} : 12'hfff);
	assign period[14] = (exp_audioe[5] ? {ssb5_reg[3][2:0], ssb5_reg[2][7:0], 1'b1} : 12'hfff);
	assign period[15] = (exp_audioe[5] ? {ssb5_reg[5][2:0], ssb5_reg[4][7:0], 1'b1} : 12'hfff);
	assign period[16] = (exp_audioe[4] ? {n163_reg[6'b011100][1:0], n163_reg[6'b011010][7:0], n163_reg[6'b011000][7:6]} : 12'hfff);
	assign period[17] = (exp_audioe[4] ? {n163_reg[6'b010100][1:0], n163_reg[6'b010010][7:0], n163_reg[6'b010000][7:6]} : 12'hfff);
	assign period[18] = (exp_audioe[4] ? {n163_reg[6'b001100][1:0], n163_reg[6'b001010][7:0], n163_reg[6'b001000][7:6]} : 12'hfff);
	assign period[19] = (exp_audioe[4] ? {n163_reg[6'b000100][1:0], n163_reg[6'b000010][7:0], n163_reg[6'b000000][7:6]} : 12'hfff);
	assign period[20] = (exp_audioe[1] ? {vrc7_reg[5'b10000][0], vrc7_reg[5'b01000][7:0], 3'b111} : 12'hfff);
	assign period[21] = (exp_audioe[1] ? {vrc7_reg[5'b10001][0], vrc7_reg[5'b01001][7:0], 3'b111} : 12'hfff);
	assign period[22] = (exp_audioe[1] ? {vrc7_reg[5'b10010][0], vrc7_reg[5'b01010][7:0], 3'b111} : 12'hfff);
	assign period[23] = (exp_audioe[1] ? {vrc7_reg[5'b10011][0], vrc7_reg[5'b01011][7:0], 3'b111} : 12'hfff);
	assign period[24] = (exp_audioe[1] ? {vrc7_reg[5'b10100][0], vrc7_reg[5'b01100][7:0], 3'b111} : 12'hfff);
	assign period[25] = (exp_audioe[1] ? {vrc7_reg[5'b10101][0], vrc7_reg[5'b01101][7:0], 3'b111} : 12'hfff);
	wire [11:0] period78 = period[find_idx] - {3'b000, period[find_idx][11:3]};
	wire [11:0] period1615 = ({1'b0, period[find_idx][11:1]} + {5'b00000, period[find_idx][11:5]}) - {9'b000000000, period[find_idx][11:9]};
	wire use_n163 = (find_idx[4:2] == 3'b010) || (find_idx[4:2] == 3'b100);
	wire use_vrc7 = (find_idx[4:2] == 3'b101) || (find_idx[4:1] == 4'b1100);
	wire use_v6saw = find_idx == 5'd7;
	wire use_fds = find_idx == 5'd12;
	wire use78 = use_v6saw || use_vrc7;
	wire use1615 = use_n163;
	wire [11:0] period_use = (use1615 ? period1615 : (use78 ? period78 : period[find_idx]));
	reg [17:0] find_bits;
	wire [879:0] find_note_lut;
	assign find_note_lut = 880'hfe3dff89eadc9b7ceced4ca012e23a4347f0efdc4b5664cbe5672a65009711d21a3f677ce21ab3265f0b395227e4b48e10c1fa3bc708d51922f4598a913e258470860fc1dc3806a0c81782c85409e12c2304207e0ec1c0340620bc1602904e0941182103e0740d81a03005c0a814;
	wire [319:0] find_steps_lut;
	assign find_steps_lut = 320'hf539bd8f2ebe6c6a56658da09775b2625604e5133b8ca29c85190440940700000000000000000000;
	always casez (period_use[11:2])
		10'b1zzzzzzzzz: find_bits = {8'h80, period_use[10:1]};
		10'b01zzzzzzzz: find_bits = {8'h71, period_use[9:0]};
		10'b001zzzzzzz: find_bits = {8'h62, period_use[8:0], 1'b1};
		10'b0001zzzzzz: find_bits = {8'h53, period_use[7:0], 2'b10};
		10'b00001zzzzz: find_bits = {8'h44, period_use[6:0], 3'b100};
		10'b000001zzzz: find_bits = {8'h35, period_use[5:0], 4'b1000};
		10'b0000001zzz: find_bits = {8'h26, period_use[4:0], 5'b10000};
		10'b00000001zz: find_bits = {8'h17, period_use[3:0], 6'b100000};
		10'b000000001z: find_bits = {8'h08, period_use[2:0], 7'b1000000};
		10'b000000000z: find_bits = 18'h3e7ff;
	endcase
	reg [4:0] spot [25:0];
	reg [3:0] oct_no [25:0];
	always @(posedge clk) begin
		find_count <= find_count + 1'b1;
		if ((find_bits[9:0] > find_steps_lut[(31 - find_count[4:0]) * 10+:10]) || (find_count[4:3] == 2'b11)) begin
			spot[find_idx] <= ((use_fds || use_vrc7) || use_n163 ? (find_bits[17:14] == 4'hf ? 5'd0 : 5'd24 - find_count) : find_count);
			oct_no[find_idx] <= ((use_fds || use_vrc7) || use_n163 ? (find_bits[17:14] == 4'hf ? 4'd0 : find_bits[17:14]) : find_bits[13:10]) - (use_vrc7 ? 4'd8 - vrc7_reg[{2'b10, !find_idx[2], find_idx[1:0]}][3:1] : 4'd0);
			find_count <= 0;
			find_idx <= (find_idx == 5'd25 ? 5'd0 : find_idx + 1'b1);
		end
	end
	always @(*) begin
		prg_bus_write = 1'b1;
		if (prg_ain == 16'h5205)
			prg_dout = multiply_result[7:0];
		else if (prg_ain == 16'h5206)
			prg_dout = multiply_result[15:8];
		else if (prg_ain == 16'h4029)
			prg_dout = {5'h00, find_note_lut[((79 - {midi_reg[5'h09][2:0], midi_reg[5'h08]}) * 11) + 10-:3]};
		else if (prg_ain == 16'h4028)
			prg_dout = {find_note_lut[((79 - {midi_reg[5'h09][2:0], midi_reg[5'h08]}) * 11) + 7-:8]};
		else if (prg_ain[15:5] == 11'b01000000001)
			prg_dout = midi_reg[prg_ain[4:0]];
		else if (prg_ain[15:8] == 8'h40)
			prg_dout = fds_din;
		else if (prg_ain == 16'h5ff2)
			prg_dout = nsf_reg[4'h2];
		else begin
			prg_dout = prg_din;
			prg_bus_write = 0;
		end
	end
	wire [223:0] exp_strs;
	assign exp_strs = 224'h5643362056433720464453204d4335204e414d205335422041505520;
	assign prg_aout = (IsNSF && ({prg_ain[15:1], 1'b0} == 16'hfffc) ? {10'h000, prg_ain[11:0]} : {prg_bank, prg_ain[11:0]});
	assign prg_allow = ((((prg_ain[15] || ((prg_ain >= 16'h4080) && (prg_ain < 16'h4fff))) && !prg_write) || (prg_ain[15:13] == 3'b011)) || ((prg_ain[15:10] == 6'b010111) && (prg_ain[9:4] != 6'b111111))) || (((prg_ain >= 16'h8000) && (prg_ain < 16'hdfff)) && exp_audioe[2]);
	assign chr_allow = flags[15];
	assign chr_aout = {9'b100000000, chr_ain[12:0]};
	assign vram_ce = chr_ain[13] & !has_chr_dout;
	wire [1:1] sv2v_tmp_D3ED4;
	assign sv2v_tmp_D3ED4 = (flags[14] ? chr_ain[10] : chr_ain[11]);
	always @(*) vram_a10 = sv2v_tmp_D3ED4;
	wire nt0 = chr_ain[13:10] == 4'b1000;
	wire [4:0] line_no = chr_ain[9:5];
	wire reg_line = ((((line_no == 5'b11010) || (line_no == 5'b11011)) || (line_no == 5'b11100)) || (line_no == 5'b11101)) && (!n163_max || !exp_audioe[4]);
	wire alt4 = chr_ain[2] == 1'b1;
	wire midi_line = (line_no[4:1] == 4'b0101) || (line_no[4:1] == 4'b0110);
	wire last16 = chr_ain[4] == 1'b1;
	wire last1 = chr_ain[4:0] == 5'd31;
	wire last2 = chr_ain[4:0] == 5'd30;
	wire last3 = chr_ain[4:0] == 5'd29;
	wire first4 = chr_ain[4:2] == 3'b000;
	wire print_reg = (nt0 && alt4) && reg_line;
	wire print_exp = (nt0 && first4) && (((line_no == 5'b11010) && (!n163_max || !exp_audioe[4])) || ((line_no == 5'b11100) && (!exp_audioe[1] && !exp_audioe[4])));
	wire print_midi = (nt0 && midi_line) && last16;
	wire print_spot = (nt0 && !print_midi) && ((((((apu_type || mmc5_type) || fds_type) || vrc6_type) || vrc7_type) || n163_type) || ssb5_type);
	wire print_oct = (((nt0 && !midi_line) && !use_freq) && print_spot) && last1;
	wire print_let = (((nt0 && !midi_line) && !use_freq) && print_spot) && last2;
	wire [4:0] note_val = spot[voi_tab_idx][4:0];
	wire inc_note = (note_val == 5'd23) || (note_val == 5'd24);
	wire [4:0] note_no = (inc_note ? 5'd4 : note_val + (note_val > 5'd14 ? 5'd9 : (note_val > 5'd5 ? 5'd7 : 5'd5)));
	wire sharp = note_no[1];
	wire print_shp = ((((nt0 && !midi_line) && !use_freq) && print_spot) && last3) && sharp;
	wire [7:0] exp_letter = exp_strs[(27 - {(line_no[2] || !(|exp_audioe) ? 3'd6 : (exp_audioe[3] ? 3'd3 : (exp_audioe[4] ? 3'd4 : (exp_audioe[2] ? 3'd2 : (exp_audioe[1] ? 3'd1 : (exp_audioe[0] ? 3'd0 : (exp_audioe[5] ? 3'd5 : 3'd6))))))), chr_ain[1:0]}) * 8+:8];
	wire [4:0] reg_ind = {!chr_ain[6], chr_ain[5:3], !chr_ain[1]};
	wire [4:0] midi_ind = {!chr_ain[6], chr_ain[5], chr_ain[3:1]};
	wire inc_oct = note_val > 5'd5;
	wire [7:0] chr_num = (print_reg ? (exp_audioe[3] ? (!reg_ind[4] ? mmc5_reg[reg_ind] : apu_reg[{1'b0, reg_ind[3:0]}]) : (exp_audioe[4] ? n163_reg[{~reg_ind[4:2], ~reg_ind[1], reg_ind[0], reg_ind[1:0] == 2'b01}] : (exp_audioe[2] ? (!reg_ind[4] ? fds_reg[reg_ind] : apu_reg[{1'b0, reg_ind[3:0]}]) : (exp_audioe[1] ? vrc7_reg[reg_ind] : (exp_audioe[0] ? (!reg_ind[4] ? vrc6_reg[{reg_ind[3:2], reg_ind[1] ^ reg_ind[0], !reg_ind[0]}] : apu_reg[{1'b0, reg_ind[3:0]}]) : (exp_audioe[5] ? (!reg_ind[4] ? ssb5_reg[reg_ind] : apu_reg[{1'b0, reg_ind[3:0]}]) : apu_reg[reg_ind])))))) : (print_midi ? ((n163_max && exp_audioe[4]) && (midi_reg[5'd7] == 8'd0) ? n163_reg[{~midi_ind[4:2], ~midi_ind[1], midi_ind[0], midi_ind[1:0] == 2'b01}] : midi_reg[midi_ind]) : oct_no[voi_tab_idx] + (inc_oct ? 1'b1 : 1'b0)));
	wire [4:0] oct_idx = {1'b0, oct_no[voi_tab_idx]} + {oct_no[voi_tab_idx], 1'b0};
	wire [4:0] spot_chr = (use_freq ? freq : oct_idx + {3'b000, spot[voi_tab_idx][4:3]});
	wire [3:0] spot_vol = (voi_off ? 4'h0 : voi_vol);
	wire has_spot_chr = print_spot && (chr_ain[4:0] == spot_chr);
	wire spot_vol_row = !chr_ain[5];
	wire [7:0] letter = {5'b01000, note_no[4:2]};
	wire cpu_ppu_write = (prg_write && (prg_ain[15:12] == 4'h2)) || chr_write;
	assign has_chr_dout = (IsNSF && !cpu_ppu_write) && ((((((print_reg || print_exp) || print_spot) || print_midi) || print_oct) || print_let) || print_shp);
	assign chr_dout = (print_exp ? exp_letter : (print_let ? letter : (print_shp ? 8'h23 : (print_spot && !print_oct ? (has_spot_chr ? (!spot_vol_row ? (use_freq ? 8'h00 : {5'h00, spot[voi_tab_idx][2:0]}) : {(use_freq ? 4'b0001 : {1'b1, spot[voi_tab_idx][2:0]}), spot_vol}) : 8'h20) : {4'h0, (chr_ain[0] ? chr_num[3:0] : chr_num[7:4])}))));
endmodule
module Mapper111 (
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
	reg [7:0] prg_dout;
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
	wire irq;
	assign irq_b = (enable ? irq : 1'hz);
	wire [15:0] flags_out = 16'h0028;
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	wire [15:0] audio = audio_in;
	assign audio_b = (enable ? audio : 16'hzzzz);
	reg [3:0] prgbank_reg;
	reg chrbank_reg;
	reg namebank_reg;
	reg [1:0] write_state;
	localparam [1:0] STATE_IDLE = 2'b00;
	localparam [1:0] STATE_UNLOCK1 = 2'b01;
	localparam [1:0] STATE_UNLOCK2 = 2'b10;
	localparam [1:0] STATE_CMD = 2'b11;
	wire unlock1_match = prg_ain == 16'hd555;
	wire unlock2_match = prg_ain == 16'haaaa;
	wire flash_write = ((write_state == STATE_CMD) && prg_ain[15]) && prg_write;
	always @(posedge clk)
		if (~enable) begin
			{prgbank_reg, chrbank_reg, namebank_reg} <= 0;
			write_state <= STATE_IDLE;
		end
		else if (ce) begin
			if (((prg_write & prg_ain[12]) & prg_ain[14]) & !prg_ain[15]) begin
				prgbank_reg <= prg_din[3:0];
				chrbank_reg <= prg_din[4];
				namebank_reg <= prg_din[5];
			end
			else if (prg_ain[15] && prg_write)
				case (write_state)
					STATE_IDLE: write_state <= (unlock1_match && (prg_din == 8'haa) ? STATE_UNLOCK1 : STATE_IDLE);
					STATE_UNLOCK1: write_state <= (unlock2_match && (prg_din == 8'h55) ? STATE_UNLOCK2 : STATE_IDLE);
					STATE_UNLOCK2: write_state <= (unlock1_match && (prg_din == 8'ha0) ? STATE_CMD : STATE_IDLE);
					STATE_CMD: write_state <= STATE_IDLE;
				endcase
		end
	assign chr_aout[21:15] = 7'b1111000;
	assign chr_aout[14:13] = {chr_ain[13], (chr_ain[13] ? namebank_reg : chrbank_reg)};
	assign chr_aout[12:0] = chr_ain[12:0];
	assign vram_a10 = chr_aout[10];
	assign prg_aout[21:19] = 3'b000;
	assign prg_aout[18:15] = prgbank_reg;
	assign prg_aout[14:0] = prg_ain[14:0];
	assign prg_allow = prg_ain[15] && (!prg_write || flash_write);
	assign chr_allow = 1'b1;
	wire [8:1] sv2v_tmp_0E42F;
	assign sv2v_tmp_0E42F = 8'hff;
	always @(*) prg_dout = sv2v_tmp_0E42F;
	assign vram_ce = 1'b0;
	assign irq = 1'b0;
endmodule
module Mapper83 (
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
	reg _sv2v_0;
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
	reg [7:0] prg_dout;
	assign prg_dout_b = (enable ? prg_dout : 8'hzz);
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
	reg irq;
	assign irq_b = (enable ? irq : 1'hz);
	wire prg_bus_write;
	wire [15:0] flags_out = {14'h0000, prg_bus_write, 1'h0};
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	wire [15:0] audio = audio_in;
	assign audio_b = (enable ? audio : 16'hzzzz);
	wire submapper1 = flags[21];
	wire submapper2 = flags[22];
	reg [1:0] prgbank_mode;
	reg [1:0] mirroring;
	reg prg_reg3_enable;
	reg irq_mode;
	reg irq_latch;
	reg irq_enable;
	reg [15:0] irq_counter;
	reg [19:0] prgbank_reg;
	reg [3:0] prgbank_reg4;
	reg [63:0] chrbank_reg;
	reg [1:0] dipswitch;
	reg [31:0] scratch_ram;
	reg [1:0] outer_bank;
	reg [1:0] wrambank;
	always @(posedge clk)
		if (~enable) begin
			{irq, irq_mode, irq_latch, irq_enable, irq_counter} <= 0;
			{prg_reg3_enable, prgbank_mode, mirroring} <= 0;
			outer_bank <= 0;
			wrambank <= 0;
			dipswitch <= 0;
			chrbank_reg <= {8 {8'd0}};
			prgbank_reg <= {4 {5'd0}};
			prgbank_reg4 <= 0;
			scratch_ram <= {4 {8'd0}};
		end
		else if (ce) begin
			if (prg_write)
				casez (prg_ain[15:8])
					8'b1zzzzz00: begin
						{wrambank, outer_bank} <= prg_din[7:4];
						{prgbank_reg4} <= prg_din[3:0];
					end
					8'b1zzzzz01: begin
						{irq_latch, irq_mode, prg_reg3_enable, prgbank_mode} <= prg_din[7:3];
						mirroring <= prg_din[1:0];
					end
					8'b1zzzzz10:
						if (prg_ain[0]) begin
							irq_counter[15:8] <= prg_din;
							irq_enable <= irq_latch;
						end
						else begin
							irq_counter[7:0] <= prg_din;
							irq <= 1'b0;
						end
					8'b1zzzzz11:
						if (prg_ain[4]) begin
							if (!prg_ain[3])
								chrbank_reg[prg_ain[2:0] * 8+:8] <= prg_din;
						end
						else
							prgbank_reg[prg_ain[1:0] * 5+:5] <= prg_din[4:0];
					8'b0101zzzz:
						if (|prg_ain[11:8])
							scratch_ram[prg_ain[1:0] * 8+:8] <= prg_din;
				endcase
			if (irq_enable) begin
				if (irq_mode)
					irq_counter <= irq_counter - 16'd1;
				else
					irq_counter <= irq_counter + 16'd1;
			end
			if (irq_enable && (irq_counter == 16'h0000)) begin
				irq <= 1'b1;
				irq_enable <= 1'b0;
			end
		end
	always @(*) begin
		if (_sv2v_0)
			;
		casez (mirroring[1:0])
			2'b00: vram_a10 = {chr_ain[10]};
			2'b01: vram_a10 = {chr_ain[11]};
			2'b1z: vram_a10 = {mirroring[0]};
		endcase
	end
	reg [4:0] prgsel;
	always @(*) begin
		if (_sv2v_0)
			;
		casez ({prgbank_mode, prg_ain[15:13]})
			5'b0010z: prgsel = {prgbank_reg4, prg_ain[13]};
			5'b0011z: prgsel = {4'b1111, prg_ain[13]};
			5'b011zz: prgsel = {prgbank_reg4[3:1], prg_ain[14:13]};
			5'b1z100: prgsel = prgbank_reg[0+:5];
			5'b1z101: prgsel = prgbank_reg[5+:5];
			5'b1z110: prgsel = prgbank_reg[10+:5];
			5'b1z111: prgsel = 5'b11111;
			5'bzz011: prgsel = prgbank_reg[15+:5];
			default: prgsel = {2'd0, prg_ain[15:13]};
		endcase
	end
	reg [9:0] chrsel;
	always @(*) begin
		if (_sv2v_0)
			;
		chrsel = 0;
		casez ({submapper1, chr_ain[13:11]})
			4'b1000: chrsel = {1'b0, chrbank_reg[0+:8], chr_ain[10]};
			4'b1001: chrsel = {1'b0, chrbank_reg[8+:8], chr_ain[10]};
			4'b1010: chrsel = {1'b0, chrbank_reg[48+:8], chr_ain[10]};
			4'b1011: chrsel = {1'b0, chrbank_reg[56+:8], chr_ain[10]};
			4'b00zz: chrsel = {(submapper2 ? outer_bank : 2'b00), chrbank_reg[chr_ain[12:10] * 8+:8]};
			default: chrsel = {6'd0, chr_ain[13:10]};
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		casez (prg_ain[15:12])
			4'h5:
				if (|prg_ain[11:8])
					prg_dout = scratch_ram[prg_ain[1:0] * 8+:8];
				else
					prg_dout = {6'b111111, dipswitch};
			default: prg_dout = 8'hff;
		endcase
	end
	wire prg_read_blocked = ((prg_ain[15:13] == 3'b011) && !submapper2) && !prg_reg3_enable;
	assign prg_bus_write = (prg_ain[15:12] == 4'h5) || prg_read_blocked;
	wire is_wram = submapper2 && (prg_ain[15:13] == 3'b011);
	assign chr_aout[21:20] = 2'b10;
	assign chr_aout[19:10] = chrsel;
	assign chr_aout[9:0] = chr_ain[9:0];
	assign prg_aout[21:18] = (is_wram ? 4'b1111 : {2'b00, (submapper2 ? outer_bank : 2'b00)});
	assign prg_aout[17:13] = (is_wram ? {3'b000, wrambank} : prgsel);
	assign prg_aout[12:0] = prg_ain[12:0];
	assign prg_allow = (prg_ain[15] && !prg_write) || is_wram;
	assign chr_allow = flags[15];
	assign vram_ce = chr_ain[13];
	initial _sv2v_0 = 0;
endmodule
module Mapper91 (
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
	chr_ain_o
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
	reg irq;
	assign irq_b = (enable ? irq : 1'hz);
	wire [15:0] flags_out = 0;
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	reg [7:0] chr_bank_0;
	reg [7:0] chr_bank_1;
	reg [7:0] chr_bank_2;
	reg [7:0] chr_bank_3;
	reg [3:0] prg_bank_0;
	reg [3:0] prg_bank_1;
	reg outer_chr_bank;
	reg [1:0] outer_prg_bank;
	reg irq_enabled;
	reg [5:0] irq_count;
	reg [5:0] last_irq_count;
	reg last_a12;
	always @(posedge clk)
		if (~enable) begin
			irq_enabled <= 0;
			irq_count <= 0;
			irq <= 0;
			last_irq_count <= 0;
			outer_prg_bank <= 0;
			outer_chr_bank <= 0;
			last_a12 <= 0;
		end
		else if (ce) begin
			if (prg_write) begin
				if (prg_ain[15:13] == 3'b011)
					case ({prg_ain[12], prg_ain[1:0]})
						3'b000: chr_bank_0 <= prg_din;
						3'b001: chr_bank_1 <= prg_din;
						3'b010: chr_bank_2 <= prg_din;
						3'b011: chr_bank_3 <= prg_din;
						3'b100: prg_bank_0 <= prg_din[3:0];
						3'b101: prg_bank_1 <= prg_din[3:0];
						3'b110: begin
							irq_enabled <= 0;
							irq <= 0;
						end
						3'b111: begin
							irq_enabled <= 1'b1;
							irq_count <= 0;
							last_irq_count <= 0;
						end
					endcase
				else if (prg_ain[15:13] == 3'b100) begin
					outer_chr_bank <= prg_din[0];
					outer_prg_bank <= prg_din[2:1];
				end
			end
			last_a12 <= chr_ain_o[12];
			last_irq_count <= irq_count;
			if (irq_enabled) begin
				if (!last_a12 && chr_ain_o[12])
					irq_count <= irq_count + 1'b1;
				if (&last_irq_count && (irq_count == 6'd0))
					irq <= 1'b1;
			end
		end
	reg [3:0] prgsel;
	always @(*)
		case (prg_ain[14:13])
			2'b00: prgsel = prg_bank_0;
			2'b01: prgsel = prg_bank_1;
			2'b10: prgsel = 4'b1110;
			2'b11: prgsel = 4'b1111;
		endcase
	reg [7:0] chrsel;
	always @(*)
		case (chr_ain[12:11])
			2'b00: chrsel = chr_bank_0;
			2'b01: chrsel = chr_bank_1;
			2'b10: chrsel = chr_bank_2;
			2'b11: chrsel = chr_bank_3;
		endcase
	assign chr_aout = {2'b10, outer_chr_bank, chrsel, chr_ain[10:0]};
	assign chr_allow = flags[15];
	wire [1:1] sv2v_tmp_D3ED4;
	assign sv2v_tmp_D3ED4 = (flags[14] ? chr_ain[10] : chr_ain[11]);
	always @(*) vram_a10 = sv2v_tmp_D3ED4;
	assign vram_ce = chr_ain[13];
	assign prg_allow = prg_ain[15] && !prg_write;
	assign prg_aout = {3'b000, outer_prg_bank, prgsel, prg_ain[12:0]};
endmodule
