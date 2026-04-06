module MMC5 (
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
	audio_dout,
	chr_din,
	chr_write,
	chr_dout_b,
	ppu_ce,
	ppuflags
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
	input [7:0] audio_dout;
	input [7:0] chr_din;
	input chr_write;
	inout [7:0] chr_dout_b;
	input ppu_ce;
	input [19:0] ppuflags;
	wire [21:0] prg_aout;
	assign prg_aout_b = (enable ? prg_aout : 22'hzzzzzz);
	reg [7:0] prg_dout;
	assign prg_dout_b = (enable ? prg_dout : 8'hzz);
	wire prg_allow;
	assign prg_allow_b = (enable ? prg_allow : 1'hz);
	reg [21:0] chr_aout;
	assign chr_aout_b = (enable ? chr_aout : 22'hzzzzzz);
	reg [7:0] chr_dout;
	assign chr_dout_b = (enable ? chr_dout : 8'hzz);
	wire chr_allow;
	assign chr_allow_b = (enable ? chr_allow : 1'hz);
	wire vram_a10;
	assign vram_a10_b = (enable ? vram_a10 : 1'hz);
	wire vram_ce;
	assign vram_ce_b = (enable ? vram_ce : 1'hz);
	wire irq;
	assign irq_b = (enable ? irq : 1'hz);
	wire has_chr_dout;
	reg prg_bus_write;
	wire [15:0] flags_out = {14'h0000, prg_bus_write, has_chr_dout};
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	wire [15:0] audio = audio_in;
	assign audio_b = (enable ? audio : 16'hzzzz);
	reg [1:0] prg_mode;
	reg [1:0] chr_mode;
	reg prg_protect_1;
	reg prg_protect_2;
	reg [1:0] extended_ram_mode;
	reg [7:0] mirroring;
	reg [7:0] fill_tile;
	reg [1:0] fill_attr;
	reg [2:0] prg_ram_bank;
	reg [7:0] prg_bank_0;
	reg [7:0] prg_bank_1;
	reg [7:0] prg_bank_2;
	reg [6:0] prg_bank_3;
	reg [9:0] chr_bank_0;
	reg [9:0] chr_bank_1;
	reg [9:0] chr_bank_2;
	reg [9:0] chr_bank_3;
	reg [9:0] chr_bank_4;
	reg [9:0] chr_bank_5;
	reg [9:0] chr_bank_6;
	reg [9:0] chr_bank_7;
	reg [9:0] chr_bank_8;
	reg [9:0] chr_bank_9;
	reg [9:0] chr_bank_a;
	reg [9:0] chr_bank_b;
	reg [1:0] upper_chr_bank_bits;
	reg chr_last;
	reg [4:0] vsplit_startstop;
	reg vsplit_enable;
	reg vsplit_side;
	reg [7:0] vsplit_scroll;
	reg [7:0] vsplit_bank;
	reg [7:0] irq_scanline;
	reg irq_enable;
	reg irq_pending;
	reg [7:0] multiplier_1;
	reg [7:0] multiplier_2;
	wire [15:0] multiply_result = multiplier_1 * multiplier_2;
	reg [9:0] ram_addrA;
	reg ram_wrenA;
	reg [7:0] ram_dataA;
	reg in_split_area;
	wire insplit = in_split_area && vsplit_enable;
	reg [5:0] cur_tile;
	reg [7:0] vscroll;
	wire [9:0] loopy = {vscroll[7:3], cur_tile[4:0]};
	wire [8:0] ppu_cycle = ppuflags[10:2];
	wire [9:0] split_addr = (ppu_cycle[1] == 0 ? loopy : {4'b1111, loopy[9:7], loopy[4:2]});
	wire [9:0] exram_read_addr = (extended_ram_mode[1] ? prg_ain[9:0] : (insplit ? split_addr : chr_ain[9:0]));
	wire [9:0] ram_addrB = exram_read_addr;
	reg [7:0] expansion_ram [0:1023];
	reg [7:0] last_read_ram;
	reg [7:0] last_read_exattr;
	reg [7:0] last_read_vram;
	reg last_chr_read;
	wire ppu_in_frame = ppuflags[0];
	reg old_ppu_sprite16;
	wire ppu_sprite16 = ppuflags[1];
	wire [8:0] ppu_scanline = ppuflags[19:11];
	wire [1:0] mirrbits = (chr_ain[11:10] == 0 ? mirroring[1:0] : (chr_ain[11:10] == 1 ? mirroring[3:2] : (chr_ain[11:10] == 2 ? mirroring[5:4] : mirroring[7:6])));
	always @(posedge clk)
		if (!enable) begin
			prg_bank_3 <= 7'h7f;
			prg_mode <= 3;
		end
		else if (ce) begin
			if (prg_write && (prg_ain[15:10] == 6'b010100)) begin
				casez (prg_ain[9:0])
					10'h100: prg_mode <= prg_din[1:0];
					10'h101: chr_mode <= prg_din[1:0];
					10'h102: prg_protect_1 <= prg_din[1:0] == 2'b10;
					10'h103: prg_protect_2 <= prg_din[1:0] == 2'b01;
					10'h104: extended_ram_mode <= prg_din[1:0];
					10'h105: mirroring <= prg_din;
					10'h106: fill_tile <= prg_din;
					10'h107: fill_attr <= prg_din[1:0];
					10'h113: prg_ram_bank <= prg_din[2:0];
					10'h114: prg_bank_0 <= prg_din;
					10'h115: prg_bank_1 <= prg_din;
					10'h116: prg_bank_2 <= prg_din;
					10'h117: prg_bank_3 <= prg_din[6:0];
					10'h120: chr_bank_0 <= {upper_chr_bank_bits, prg_din};
					10'h121: chr_bank_1 <= {upper_chr_bank_bits, prg_din};
					10'h122: chr_bank_2 <= {upper_chr_bank_bits, prg_din};
					10'h123: chr_bank_3 <= {upper_chr_bank_bits, prg_din};
					10'h124: chr_bank_4 <= {upper_chr_bank_bits, prg_din};
					10'h125: chr_bank_5 <= {upper_chr_bank_bits, prg_din};
					10'h126: chr_bank_6 <= {upper_chr_bank_bits, prg_din};
					10'h127: chr_bank_7 <= {upper_chr_bank_bits, prg_din};
					10'h128: chr_bank_8 <= {upper_chr_bank_bits, prg_din};
					10'h129: chr_bank_9 <= {upper_chr_bank_bits, prg_din};
					10'h12a: chr_bank_a <= {upper_chr_bank_bits, prg_din};
					10'h12b: chr_bank_b <= {upper_chr_bank_bits, prg_din};
					10'h130: upper_chr_bank_bits <= prg_din[1:0];
					10'h200: {vsplit_enable, vsplit_side, vsplit_startstop} <= {prg_din[7:6], prg_din[4:0]};
					10'h201: vsplit_scroll <= prg_din;
					10'h202: vsplit_bank <= prg_din;
					10'h203: irq_scanline <= prg_din;
					10'h204: irq_enable <= prg_din[7];
					10'h205: multiplier_1 <= prg_din;
					10'h206: multiplier_2 <= prg_din;
					default:
						;
				endcase
				if (prg_ain[9:4] == 6'b010010)
					chr_last <= prg_ain[3] & ppu_sprite16;
			end
			old_ppu_sprite16 <= ppu_sprite16;
			if ((old_ppu_sprite16 != ppu_sprite16) && ~ppu_sprite16)
				chr_last <= 0;
			if (extended_ram_mode != 3) begin
				if (((((ppu_ce && !ppu_in_frame) && !extended_ram_mode[1]) && chr_write) && (mirrbits == 2)) && chr_ain[13])
					expansion_ram[chr_ain[9:0]] <= chr_din;
				else if ((ce && prg_write) && (prg_ain[15:10] == 6'b010111))
					expansion_ram[prg_ain[9:0]] <= (extended_ram_mode[1] || ppu_in_frame ? prg_din : 8'd0);
			end
		end
	always @(*) begin
		prg_bus_write = 1'b1;
		if ((prg_ain[15:10] == 6'b010111) && extended_ram_mode[1])
			prg_dout = last_read_ram;
		else if (prg_ain == 16'h5204)
			prg_dout = {irq_pending, ppu_in_frame, 6'b111111};
		else if (prg_ain == 16'h5205)
			prg_dout = multiply_result[7:0];
		else if (prg_ain == 16'h5206)
			prg_dout = multiply_result[15:8];
		else if (prg_ain == 16'h5015)
			prg_dout = {6'h00, audio_dout[1:0]};
		else begin
			prg_dout = 8'hff;
			prg_bus_write = 0;
		end
	end
	reg last_scanline;
	wire irq_trig = ((irq_scanline != 0) && (irq_scanline < 240)) && (ppu_scanline == {1'b0, irq_scanline});
	always @(posedge clk)
		if (!enable)
			irq_pending <= 0;
		else if (ce || ppu_ce) begin
			last_scanline <= ppu_scanline[0];
			if (((ce && prg_read) && (prg_ain == 16'h5204)) || ~ppu_in_frame)
				irq_pending <= 0;
			else if ((ppu_scanline[0] != last_scanline) && irq_trig)
				irq_pending <= 1;
		end
	assign irq = irq_pending && irq_enable;
	reg [5:0] new_cur_tile;
	reg last_in_split_area;
	always @(*) begin
		new_cur_tile = (ppu_cycle[8:3] == 40 ? 6'd0 : cur_tile + 6'b000001);
		in_split_area = last_in_split_area;
		if ((ppu_cycle[2:0] == 0) && (ppu_cycle < 336)) begin
			if (new_cur_tile == 0)
				in_split_area = !vsplit_side;
			else if (new_cur_tile == {1'b0, vsplit_startstop})
				in_split_area = vsplit_side;
			else if (new_cur_tile == 34)
				in_split_area = 0;
		end
	end
	always @(posedge clk) begin
		last_in_split_area <= in_split_area;
		if ((ppu_cycle[2:0] == 0) && (ppu_cycle < 336))
			cur_tile <= new_cur_tile;
	end
	always @(posedge clk)
		if (ppu_ce) begin
			if (ppu_cycle == 319)
				vscroll <= (ppu_scanline[8] ? vsplit_scroll : (vscroll == 239 ? 8'b00000000 : vscroll + 8'b00000001));
		end
	wire [1:0] split_attr = (!loopy[1] && !loopy[6] ? last_read_ram[1:0] : (loopy[1] && !loopy[6] ? last_read_ram[3:2] : (!loopy[1] && loopy[6] ? last_read_ram[5:4] : last_read_ram[7:6])));
	wire exattr_read = ((extended_ram_mode == 1) && (ppu_cycle[2:1] == 1)) && ppu_in_frame;
	assign has_chr_dout = chr_ain[13] && ((mirrbits[1] || insplit) || exattr_read);
	wire [1:0] override_attr = (insplit ? split_attr : (extended_ram_mode == 1 ? last_read_exattr[7:6] : fill_attr));
	always @(*)
		if (ppu_in_frame) begin
			if (ppu_cycle[1] == 0) begin
				if (insplit || (mirrbits[0] == 0))
					chr_dout = (extended_ram_mode[1] ? 8'b00000000 : last_read_ram);
				else
					chr_dout = fill_tile;
			end
			else if ((!insplit && !exattr_read) && (mirrbits[0] == 0))
				chr_dout = (extended_ram_mode[1] ? 8'b00000000 : last_read_ram);
			else
				chr_dout = {override_attr, override_attr, override_attr, override_attr};
		end
		else
			chr_dout = last_read_vram;
	always @(posedge clk)
		if (ce && enable) begin
			last_read_ram <= expansion_ram[exram_read_addr];
			if (((ppu_cycle[2] == 0) && (ppu_cycle[1] == 0)) && ppu_in_frame)
				last_read_exattr <= last_read_ram;
			last_chr_read <= chr_read;
			if (!chr_read && last_chr_read)
				last_read_vram <= (extended_ram_mode[1] ? 8'b00000000 : last_read_ram);
		end
	reg [7:0] prgsel;
	always @(*)
		casez ({prg_mode, prg_ain[15:13]})
			5'bzz0zz: prgsel = {5'b0xxxx, prg_ram_bank};
			5'b001zz: prgsel = {1'b1, prg_bank_3[6:2], prg_ain[14:13]};
			5'b0110z: prgsel = {prg_bank_1[7:1], prg_ain[13]};
			5'b0111z: prgsel = {1'b1, prg_bank_3[6:1], prg_ain[13]};
			5'b1010z: prgsel = {prg_bank_1[7:1], prg_ain[13]};
			5'b10110: prgsel = {prg_bank_2};
			5'b10111: prgsel = {1'b1, prg_bank_3};
			5'b11100: prgsel = {prg_bank_0};
			5'b11101: prgsel = {prg_bank_1};
			5'b11110: prgsel = {prg_bank_2};
			5'b11111: prgsel = {1'b1, prg_bank_3};
		endcase
	assign prg_aout = {(prgsel[7] ? {2'b00, prgsel[6:0]} : {6'b111100, prgsel[2:0]}), prg_ain[12:0]};
	wire is_bg_fetch = !(ppu_cycle[8] && !ppu_cycle[6]);
	wire chrset = (ppu_sprite16 && ppu_in_frame ? is_bg_fetch : chr_last);
	reg [9:0] chrsel;
	always @(*) begin
		casez ({chr_mode, chr_ain[12:10], chrset})
			6'b00zzz0: chrsel = {chr_bank_7[6:0], chr_ain[12:10]};
			6'b00zzz1: chrsel = {chr_bank_b[6:0], chr_ain[12:10]};
			6'b010zz0: chrsel = {chr_bank_3[7:0], chr_ain[11:10]};
			6'b011zz0: chrsel = {chr_bank_7[7:0], chr_ain[11:10]};
			6'b01zzz1: chrsel = {chr_bank_b[7:0], chr_ain[11:10]};
			6'b1000z0: chrsel = {chr_bank_1[8:0], chr_ain[10]};
			6'b1001z0: chrsel = {chr_bank_3[8:0], chr_ain[10]};
			6'b1010z0: chrsel = {chr_bank_5[8:0], chr_ain[10]};
			6'b1011z0: chrsel = {chr_bank_7[8:0], chr_ain[10]};
			6'b10z0z1: chrsel = {chr_bank_9[8:0], chr_ain[10]};
			6'b10z1z1: chrsel = {chr_bank_b[8:0], chr_ain[10]};
			6'b110000: chrsel = chr_bank_0;
			6'b110010: chrsel = chr_bank_1;
			6'b110100: chrsel = chr_bank_2;
			6'b110110: chrsel = chr_bank_3;
			6'b111000: chrsel = chr_bank_4;
			6'b111010: chrsel = chr_bank_5;
			6'b111100: chrsel = chr_bank_6;
			6'b111110: chrsel = chr_bank_7;
			6'b11z001: chrsel = chr_bank_8;
			6'b11z011: chrsel = chr_bank_9;
			6'b11z101: chrsel = chr_bank_a;
			6'b11z111: chrsel = chr_bank_b;
		endcase
		chr_aout = {2'b10, chrsel, chr_ain[9:0]};
		if (ppu_in_frame && insplit)
			chr_aout = {2'b10, vsplit_bank, chr_ain[11:3], chr_ain[2:0]};
		else if (((ppu_in_frame && (extended_ram_mode == 1)) && is_bg_fetch) && (ppu_cycle[2:1] != 0))
			chr_aout = {2'b10, upper_chr_bank_bits, last_read_exattr[5:0], chr_ain[11:0]};
	end
	assign vram_a10 = mirrbits[0];
	assign vram_ce = chr_ain[13] && !mirrbits[1];
	wire prg_ram_we = prg_protect_1 && prg_protect_2;
	assign prg_allow = (prg_ain >= 16'h6000) && (!prg_write || (!prgsel[7] && prg_ram_we));
	assign chr_allow = flags[15];
endmodule
module mmc5_mixed (
	clk,
	apu_ce,
	enable,
	phi2,
	odd_or_even,
	wren,
	rden,
	addr_in,
	data_in,
	data_out,
	audio_in,
	audio_out
);
	input clk;
	input apu_ce;
	input enable;
	input phi2;
	input odd_or_even;
	input wren;
	input rden;
	input [15:0] addr_in;
	input [7:0] data_in;
	output wire [7:0] data_out;
	input [15:0] audio_in;
	output wire [15:0] audio_out;
	wire [15:0] audio;
	wire apu_cs = (addr_in[15:5] == 11'b01010000000) && (addr_in[3] == 0);
	reg [16:0] audio_o;
	always @(posedge clk) audio_o <= audio + audio_in;
	assign audio_out = audio_o[16:1];
	APU mmc5apu(
		.MMC5(1'b1),
		.clk(clk),
		.ce(apu_ce),
		.PHI2(phi2),
		.CS(apu_cs),
		.reset(~enable),
		.cold_reset(~enable),
		.allow_us(1'b0),
		.PAL(1'b0),
		.ADDR(addr_in[4:0]),
		.DIN(data_in),
		.DOUT(data_out),
		.RW(~wren),
		.audio_channels(5'b10011),
		.Sample(audio),
		.DmaReq(),
		.DmaAck(1'b1),
		.DmaAddr(),
		.DmaData(8'b00000000),
		.odd_or_even(odd_or_even),
		.IRQ()
	);
endmodule
