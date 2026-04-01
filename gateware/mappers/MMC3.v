module Rambo1 (
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
	reg irq;
	assign irq_b = (enable ? irq : 1'hz);
	reg [15:0] flags_out = 16'h0008;
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	reg [3:0] bank_select;
	reg prg_rom_bank_mode;
	reg chr_K;
	reg chr_a12_invert;
	reg mirroring;
	reg irq_enable;
	reg irq_reload;
	reg [7:0] irq_latch;
	reg [7:0] counter;
	reg [1:0] irq_delay;
	reg [7:0] chr_bank_0;
	reg [7:0] chr_bank_1;
	reg [7:0] chr_bank_2;
	reg [7:0] chr_bank_3;
	reg [7:0] chr_bank_4;
	reg [7:0] chr_bank_5;
	reg [7:0] chr_bank_8;
	reg [7:0] chr_bank_9;
	reg [5:0] prg_bank_0;
	reg [5:0] prg_bank_1;
	reg [5:0] prg_bank_2;
	reg irq_cycle_mode;
	reg next_irq_cycle_mode;
	reg [1:0] cycle_counter;
	wire mapper158 = flags[7:0] == 158;
	reg old_a12_edge;
	reg a12_edge_delayed;
	reg [4:0] a12_ctr;
	wire a12_edge = (chr_ain_o[12] && (a12_ctr == 0)) || old_a12_edge;
	always @(posedge clk) begin
		old_a12_edge <= a12_edge && !ce;
		if (ce) begin
			if (chr_ain_o[12])
				a12_ctr <= 5'd16;
			else if (a12_ctr > 0)
				a12_ctr <= a12_ctr - 1'd1;
		end
	end
	always @(posedge clk)
		if (~enable) begin
			bank_select <= 0;
			prg_rom_bank_mode <= 0;
			chr_K <= 0;
			chr_a12_invert <= 0;
			mirroring <= 0;
			{irq_enable, irq_reload} <= 0;
			{irq_latch, counter} <= 0;
			{chr_bank_0, chr_bank_1} <= 0;
			{chr_bank_2, chr_bank_3, chr_bank_4, chr_bank_5} <= 0;
			{chr_bank_8, chr_bank_9} <= 0;
			{prg_bank_0, prg_bank_1, prg_bank_2} <= 6'b111111;
			irq_cycle_mode <= 0;
			next_irq_cycle_mode <= 0;
			cycle_counter <= 0;
			irq <= 0;
			irq_delay <= 0;
			a12_edge_delayed <= 0;
		end
		else if (ce) begin
			cycle_counter <= cycle_counter + 1'd1;
			irq_cycle_mode <= next_irq_cycle_mode;
			a12_edge_delayed <= a12_edge;
			if ((irq_cycle_mode ? cycle_counter == 3 : a12_edge_delayed)) begin
				if (irq_reload) begin
					if (|irq_latch)
						counter <= irq_latch | 8'h01;
					else
						counter <= 8'h00;
					if (~|irq_latch && irq_enable)
						irq_delay <= 1;
					irq_reload <= 0;
				end
				else if (counter == 8'h00) begin
					counter <= irq_latch;
					if (~|irq_latch && irq_enable)
						irq_delay <= 1;
				end
				else begin
					counter <= counter - 1'd1;
					if ((counter == 8'h01) && irq_enable)
						irq_delay <= 1;
				end
			end
			if (irq_delay) begin
				irq <= 1;
				irq_delay <= 0;
			end
			if (prg_write && prg_ain[15])
				case ({prg_ain[14:13], prg_ain[0]})
					3'b000: {chr_a12_invert, prg_rom_bank_mode, chr_K, bank_select} <= {prg_din[7:5], prg_din[3:0]};
					3'b001:
						case (bank_select)
							0: chr_bank_0 <= prg_din;
							1: chr_bank_1 <= prg_din;
							2: chr_bank_2 <= prg_din;
							3: chr_bank_3 <= prg_din;
							4: chr_bank_4 <= prg_din;
							5: chr_bank_5 <= prg_din;
							6: prg_bank_0 <= prg_din[5:0];
							7: prg_bank_1 <= prg_din[5:0];
							8: chr_bank_8 <= prg_din;
							9: chr_bank_9 <= prg_din;
							15: prg_bank_2 <= prg_din[5:0];
						endcase
					3'b010: mirroring <= prg_din[0];
					3'b011:
						;
					3'b100: irq_latch <= prg_din;
					3'b101: begin
						{irq_reload, next_irq_cycle_mode} <= {1'b1, prg_din[0]};
						cycle_counter <= 0;
					end
					3'b110: {irq_enable, irq} <= 2'b00;
					3'b111: {irq_enable, irq} <= 2'b10;
				endcase
		end
	reg [5:0] prgsel;
	always @(*)
		casez ({prg_ain[14:13], prg_rom_bank_mode})
			3'b000: prgsel = prg_bank_0;
			3'b010: prgsel = prg_bank_1;
			3'b100: prgsel = prg_bank_2;
			3'b110: prgsel = 6'b111111;
			3'b001: prgsel = prg_bank_2;
			3'b011: prgsel = prg_bank_0;
			3'b101: prgsel = prg_bank_1;
			3'b111: prgsel = 6'b111111;
		endcase
	reg [7:0] chrsel;
	always @(*)
		casez ({chr_ain[12] ^ chr_a12_invert, chr_ain[11], chr_ain[10], chr_K})
			4'b00z0: chrsel = {chr_bank_0[7:1], chr_ain[10]};
			4'b01z0: chrsel = {chr_bank_1[7:1], chr_ain[10]};
			4'b0001: chrsel = chr_bank_0;
			4'b0011: chrsel = chr_bank_8;
			4'b0101: chrsel = chr_bank_1;
			4'b0111: chrsel = chr_bank_9;
			4'b100z: chrsel = chr_bank_2;
			4'b101z: chrsel = chr_bank_3;
			4'b110z: chrsel = chr_bank_4;
			4'b111z: chrsel = chr_bank_5;
		endcase
	assign prg_aout = {3'b000, prgsel, prg_ain[12:0]};
	assign {chr_allow, chr_aout} = {flags[15], 4'b1000, chrsel, chr_ain[9:0]};
	assign prg_allow = prg_ain[15] && !prg_write;
	assign vram_a10 = (mapper158 ? chrsel[7] : (mirroring ? chr_ain[11] : chr_ain[10]));
	assign vram_ce = chr_ain[13];
endmodule
module MMC3 (
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
	m2_inv,
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
	input m2_inv;
	input paused;
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
	reg prg_bus_write;
	wire [15:0] flags_out = {14'h0002, prg_bus_write, 1'b0};
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	reg [2:0] bank_select;
	reg prg_rom_bank_mode;
	reg chr_a12_invert;
	reg mirroring;
	reg irq_enable;
	reg irq_reload;
	reg [7:0] irq_latch;
	reg [7:0] counter;
	reg [3:0] ram_enable;
	reg [3:0] ram_protect;
	reg ram6_enabled;
	reg ram6_enable;
	reg ram6_protect;
	reg [7:0] chr_bank_0;
	reg [7:0] chr_bank_1;
	reg chr_bank_0_0;
	reg chr_bank_1_0;
	reg [7:0] chr_bank_2;
	reg [7:0] chr_bank_3;
	reg [7:0] chr_bank_4;
	reg [7:0] chr_bank_5;
	reg [7:0] prg_bank_0;
	reg [7:0] prg_bank_1;
	reg [7:0] prg_bank_2;
	reg last_a12;
	wire prg_is_ram;
	reg [6:0] irq_reg;
	wire mapper48 = flags[7:0] == 48;
	assign irq = (mapper48 ? irq_reg[3] & irq_enable : irq_reg[0]);
	reg [7:0] m268_reg [5:0];
	reg [7:0] m45_reg [3:0];
	reg [2:0] m45_index;
	wire m45_locked = m45_reg[3][6];
	reg [7:0] m52_reg;
	wire m52_locked = m52_reg[7];
	wire acclaim = (flags[7:0] == 4) && (flags[24:21] == 3);
	wire mmc3_alt_behavior = acclaim;
	wire TQROM = flags[7:0] == 119;
	wire TxSROM = flags[7:0] == 118;
	wire mapper47 = flags[7:0] == 47;
	wire mapper37 = flags[7:0] == 37;
	wire DxROM = flags[7:0] == 206;
	wire mapper112 = flags[7:0] == 112;
	wire mapper33 = flags[7:0] == 33;
	wire mapper95 = flags[7:0] == 95;
	wire mapper88 = flags[7:0] == 88;
	wire mapper154 = flags[7:0] == 154;
	wire mapper76 = flags[7:0] == 76;
	wire mapper80 = flags[7:0] == 80;
	wire mapper82 = flags[7:0] == 82;
	wire mapper207 = flags[7:0] == 207;
	wire mapper74 = flags[7:0] == 74;
	wire mapper191 = flags[7:0] == 191;
	wire mapper192 = flags[7:0] == 192;
	wire mapper194 = flags[7:0] == 194;
	wire mapper195 = flags[7:0] == 195;
	wire mapper196 = flags[7:0] == 196;
	wire mapper189 = flags[7:0] == 189;
	wire mapper205 = flags[7:0] == 205;
	wire mapper208 = flags[7:0] == 208;
	wire MMC6 = (flags[7:0] == 4) && (flags[24:21] == 1);
	wire mapper268 = {flags[20:17], flags[7:0]} == 268;
	wire mapper268_5k = flags[24:21] == 1;
	wire mapper45 = flags[7:0] == 45;
	wire mapper52 = flags[7:0] == 52;
	wire oversized = ((mapper268 || mapper45) || mapper52) || (flags[10:9] == 3);
	wire gnrom;
	wire lockout;
	wire gnrom_lock;
	wire mega_unrom;
	wire weird_mode;
	wire four_screen_mirroring = flags[16];
	reg mapper47_multicart;
	reg [2:0] mapper37_multicart;
	reg [3:0] mapper189_prgsel;
	wire [7:0] new_counter = ((counter == 0) || irq_reload ? irq_latch : counter - 1'd1);
	reg [3:0] a12_ctr;
	wire irq_support = ((((((((!DxROM && !mapper33) && !mapper95) && !mapper88) && !mapper154) && !mapper76) && !mapper80) && !mapper82) && !mapper207) && !mapper112;
	wire prg_invert_support = irq_support && !mapper48;
	wire chr_invert_support = (irq_support && !mapper48) || mapper82;
	wire regs_7e = (mapper80 || mapper82) || mapper207;
	wire internal_128 = mapper80 || mapper207;
	wire prg_reg_odd = (~mapper196 ? prg_ain[0] : |prg_ain[3:2] | (prg_ain[1] & ~prg_ain[14]));
	wire [3:0] prota = (m268_reg[4][6] ^ m268_reg[4][3] ? {m268_reg[4][1:0], m268_reg[4][4], m268_reg[4][7]} : 4'hf);
	wire [3:0] prot = (m268_reg[4][3] ? ~prota : prota);
	always @(posedge clk)
		if (~enable) begin
			irq_reg <= 7'b0000000;
			bank_select <= 0;
			prg_rom_bank_mode <= 0;
			chr_a12_invert <= 0;
			mirroring <= flags[14];
			{irq_enable, irq_reload} <= 0;
			{irq_latch, counter} <= 0;
			ram_enable <= {4 {mapper112}};
			ram_protect <= 0;
			{chr_bank_0, chr_bank_1} <= 0;
			{chr_bank_2, chr_bank_3, chr_bank_4, chr_bank_5} <= 0;
			{prg_bank_0, prg_bank_1} <= 0;
			prg_bank_2 <= 8'b11111110;
			a12_ctr <= 0;
			last_a12 <= 0;
			mapper37_multicart <= 3'b000;
			mapper189_prgsel <= 4'b1011;
			{m268_reg[0], m268_reg[1], m268_reg[2], m268_reg[3], m268_reg[4], m268_reg[5]} <= 0;
			{m45_reg[0], m45_reg[1], m45_reg[2], m45_reg[3]} <= 32'h00000f00;
			m45_index <= 0;
			m52_reg <= 0;
		end
		else begin
			if (ce) begin
				if ((!regs_7e && prg_write) && prg_ain[15]) begin
					if ((!mapper33 && !mapper48) && !mapper112)
						casez ({prg_ain[14:13], prg_reg_odd})
							3'b000: {chr_a12_invert, prg_rom_bank_mode, ram6_enabled, bank_select} <= {prg_din[7:5], prg_din[2:0]};
							3'b001:
								case (bank_select)
									0: {chr_bank_0, chr_bank_0_0} <= {1'b0, prg_din};
									1: {chr_bank_1, chr_bank_1_0} <= {1'b0, prg_din};
									2: chr_bank_2 <= prg_din;
									3: chr_bank_3 <= prg_din;
									4: chr_bank_4 <= prg_din;
									5: chr_bank_5 <= prg_din;
									6: prg_bank_0 <= prg_din;
									7: prg_bank_1 <= prg_din;
								endcase
							3'b010:
								if (!mapper208)
									mirroring <= !prg_din[0];
							3'b011: {ram_enable, ram_protect, ram6_enable, ram6_protect} <= {{4 {prg_din[7]}}, {4 {prg_din[6]}}, prg_din[5:4]};
							3'b100: irq_latch <= prg_din;
							3'b101: irq_reload <= 1;
							3'b110: {irq_enable, irq_reg[0]} <= 2'b00;
							3'b111: irq_enable <= 1;
						endcase
					else if (!mapper112)
						casez ({prg_ain[14:13], prg_ain[1:0], mapper48})
							5'b00000: {mirroring, prg_bank_0[5:0]} <= prg_din[6:0] ^ 7'h40;
							5'b00001: prg_bank_0[5:0] <= prg_din[5:0];
							5'b0001z: prg_bank_1[5:0] <= prg_din[5:0];
							5'b0010z: chr_bank_0 <= prg_din;
							5'b0011z: chr_bank_1 <= prg_din;
							5'b0100z: chr_bank_2 <= prg_din;
							5'b0101z: chr_bank_3 <= prg_din;
							5'b0110z: chr_bank_4 <= prg_din;
							5'b0111z: chr_bank_5 <= prg_din;
							5'b10001: irq_latch <= prg_din ^ 8'hff;
							5'b10011: {irq_reload, irq_reg} <= 8'b10000000;
							5'b10101: irq_enable <= 1;
							5'b10111: irq_enable <= 0;
							5'b11001: mirroring <= !prg_din[6];
						endcase
					else
						casez ({prg_ain[14:13], prg_ain[0]})
							3'b000: {bank_select} <= {prg_din[2:0]};
							3'b010:
								case (bank_select)
									0: prg_bank_0 <= prg_din;
									1: prg_bank_1 <= prg_din;
									2: chr_bank_0 <= {1'b0, prg_din[7:1]};
									3: chr_bank_1 <= {1'b0, prg_din[7:1]};
									4: chr_bank_2 <= prg_din;
									5: chr_bank_3 <= prg_din;
									6: chr_bank_4 <= prg_din;
									7: chr_bank_5 <= prg_din;
								endcase
							3'b110: mirroring <= !prg_din[0];
						endcase
					if (mapper154)
						mirroring <= !prg_din[6];
					if ((DxROM || mapper76) || mapper88)
						mirroring <= flags[14];
				end
				else if ((regs_7e && prg_write) && (prg_ain[15:4] == 12'h7ef))
					casez ({prg_ain[3:0], mapper82})
						5'b0000z: chr_bank_0 <= {1'b0, prg_din[7:1]};
						5'b0001z: chr_bank_1 <= {1'b0, prg_din[7:1]};
						5'b0010z: chr_bank_2 <= prg_din;
						5'b0011z: chr_bank_3 <= prg_din;
						5'b0100z: chr_bank_4 <= prg_din;
						5'b0101z: chr_bank_5 <= prg_din;
						5'b011z0: {mirroring} <= prg_din[0];
						5'b100z0: {ram_enable[3], ram_protect[3]} <= {prg_din == 8'ha3, prg_din != 8'ha3};
						5'b01101: {chr_a12_invert, mirroring} <= prg_din[1:0];
						5'b01111: {ram_enable[0], ram_protect[0]} <= {prg_din == 8'hca, prg_din != 8'hca};
						5'b10001: {ram_enable[1], ram_protect[1]} <= {prg_din == 8'h69, prg_din != 8'h69};
						5'b10011: {ram_enable[2], ram_protect[2]} <= {prg_din == 8'h84, prg_din != 8'h84};
						5'b101z0: prg_bank_0[5:0] <= prg_din[5:0];
						5'b110z0: prg_bank_1[5:0] <= prg_din[5:0];
						5'b111z0: prg_bank_2[5:0] <= prg_din[5:0];
						5'b10101: prg_bank_0[5:0] <= prg_din[7:2];
						5'b10111: prg_bank_1[5:0] <= prg_din[7:2];
						5'b11001: prg_bank_2[5:0] <= prg_din[7:2];
					endcase
				if ((mapper268 && prg_write) && (({mapper268_5k, prg_ain[15:12]} == 5'h06) || ({mapper268_5k, prg_ain[15:12]} == 5'h15))) begin
					if (prg_ain[2:0] == 3'h2) begin
						m268_reg[2][3:0] <= prg_din[3:0];
						if (!gnrom_lock)
							m268_reg[2][7:4] <= prg_din[7:4];
					end
					else if ((prg_ain[2:1] != 2'b11) && !lockout)
						m268_reg[prg_ain[2:0]] <= prg_din;
				end
				if (prg_write && prg_is_ram)
					mapper47_multicart <= prg_din[0];
				if (prg_write && prg_is_ram)
					mapper37_multicart <= prg_din[2:0];
				if (((prg_write && (prg_ain[15:14] == 2'b01)) && prg_ain[8]) && mapper189)
					mapper189_prgsel <= prg_din[7:4] | prg_din[3:0];
				if ((((prg_write && (prg_ain[15:14] == 2'b01)) && !prg_ain[12]) && prg_ain[11]) && mapper208)
					{mirroring, mapper189_prgsel[1:0]} <= {!prg_din[5], prg_din[4], prg_din[0]};
				if ((prg_write && (prg_ain[15:11] == 5'b01010)) && mapper208)
					m268_reg[4] <= prg_din;
				if ((prg_write && (prg_ain[15:11] == 5'b01011)) && mapper208)
					m268_reg[{1'b0, prg_ain[1:0]}] <= prg_din ^ {1'b0, prot[3], 1'b0, prot[2:1], 2'b00, prot[0]};
				if (((prg_write && (prg_ain[15:13] == 3'b011)) && mapper45) && !m45_locked) begin
					m45_reg[m45_index[1:0]] <= prg_din;
					m45_index <= m45_index + 1'd1;
				end
				if (((prg_write && (prg_ain[15:13] == 3'b011)) && mapper52) && !m52_locked)
					m52_reg <= prg_din;
			end
			if (m2_inv) begin
				irq_reg[6:1] <= irq_reg[5:0];
				if (!acclaim)
					a12_ctr <= (a12_ctr != 0 ? a12_ctr - 4'b0001 : a12_ctr);
			end
			if (~paused) begin
				last_a12 <= chr_ain_o[12];
				if (((acclaim && (!last_a12 && chr_ain_o[12])) && (a12_ctr == 6)) || ((~acclaim && (!last_a12 && chr_ain_o[12])) && (a12_ctr == 0))) begin
					counter <= new_counter;
					if (((((!mmc3_alt_behavior || (counter != 0)) || irq_reload) && (new_counter == 0)) && irq_enable) && irq_support)
						irq_reg[0] <= 1;
					irq_reload <= 0;
				end
				if (acclaim) begin
					if (!last_a12 && chr_ain_o[12])
						a12_ctr <= (a12_ctr != 0 ? a12_ctr - 4'b0001 : 4'b0111);
					if ((prg_ain == 16'hc001) && prg_write)
						a12_ctr <= 4'b0111;
				end
				else if (chr_ain_o[12])
					a12_ctr <= 4'b0011;
			end
		end
	reg [7:0] prgsel;
	always @(*) begin
		casez ({prg_ain[14:13], prg_rom_bank_mode && prg_invert_support})
			3'b000: prgsel = prg_bank_0;
			3'b001: prgsel = prg_bank_2;
			3'b01z: prgsel = prg_bank_1;
			3'b100: prgsel = prg_bank_2;
			3'b101: prgsel = prg_bank_0;
			3'b11z: prgsel = 8'b11111111;
		endcase
		if (mapper47)
			prgsel[7:4] = {3'b000, mapper47_multicart};
		if (mapper37) begin
			prgsel[7:4] = {3'b000, mapper37_multicart[2]};
			if (mapper37_multicart[1:0] == 3'd3)
				prgsel[3] = 1'b1;
			else if (mapper37_multicart[2] == 1'b0)
				prgsel[3] = 1'b0;
		end
		if (mapper205)
			prgsel[7:4] = {2'b00, mapper37_multicart[1], mapper37_multicart[0] | (prgsel[4] & !mapper37_multicart[1])};
		if (mapper189 || mapper208)
			prgsel = {2'b00, mapper189_prgsel, prg_ain[14:13]};
		if (!oversized)
			prgsel[7:6] = 2'b00;
	end
	reg [8:0] chrsel;
	wire use_chr_ain_12 = chr_ain[12] ^ (chr_a12_invert && chr_invert_support);
	always @(*)
		if (!mapper76) begin
			casez ({use_chr_ain_12, chr_ain[11], chr_ain[10]})
				3'b00z: chrsel = {chr_bank_0, chr_ain[10]};
				3'b01z: chrsel = {chr_bank_1, chr_ain[10]};
				3'b100: chrsel = {1'b0, chr_bank_2};
				3'b101: chrsel = {1'b0, chr_bank_3};
				3'b110: chrsel = {1'b0, chr_bank_4};
				3'b111: chrsel = {1'b0, chr_bank_5};
			endcase
			if (mapper47)
				chrsel[7] = mapper47_multicart;
			if (mapper37)
				chrsel[7] = mapper37_multicart[2];
			if (mapper205)
				chrsel[8:7] = {mapper37_multicart[1], mapper37_multicart[0] | (chrsel[7] & !mapper37_multicart[1])};
			if (mapper88 || mapper154)
				chrsel[6] = chr_ain[12];
		end
		else
			case (chr_ain[12:11])
				2'b00: chrsel = {chr_bank_2, chr_ain[10]};
				2'b01: chrsel = {chr_bank_3, chr_ain[10]};
				2'b10: chrsel = {chr_bank_4, chr_ain[10]};
				2'b11: chrsel = {chr_bank_5, chr_ain[10]};
			endcase
	always @(*) begin
		prg_bus_write = 1'b1;
		if ((!prg_write && mapper208) && (prg_ain[15:11] == 5'b01011))
			prg_dout = m268_reg[{1'b0, prg_ain[1:0]}];
		else begin
			prg_dout = 8'hff;
			prg_bus_write = 0;
		end
	end
	assign gnrom = m268_reg[3][4];
	assign lockout = m268_reg[3][7] && !gnrom;
	assign gnrom_lock = m268_reg[2][7];
	assign mega_unrom = m268_reg[5][4];
	assign weird_mode = m268_reg[3][6];
	wire [24:13] map268p;
	wire [17:10] map268c;
	assign map268p[24:21] = {m268_reg[0][5:4], m268_reg[1][3:2]};
	assign map268p[20] = (m268_reg[1][5] ? prgsel[7] : m268_reg[1][4]);
	assign map268p[19] = (mega_unrom ? prg_ain[14] | map268c[17] : (m268_reg[1][6] ? prgsel[6] : m268_reg[0][2]));
	assign map268p[18] = (mega_unrom ? prg_ain[14] | map268c[16] : (!m268_reg[1][7] ? prgsel[5] : m268_reg[0][1]));
	assign map268p[17] = (!m268_reg[0][6] ? prgsel[4] : m268_reg[0][0]);
	assign map268p[16:15] = (gnrom ? m268_reg[3][3:2] : ((weird_mode && !prg_rom_bank_mode) && prg_ain[14] ? 2'b00 : prgsel[3:2]));
	assign map268p[14] = (gnrom ? (m268_reg[1][1] ? prg_ain[14] : m268_reg[3][1]) : ((weird_mode && !prg_rom_bank_mode) && prg_ain[14] ? 1'b0 : prgsel[1]));
	assign map268p[13] = (gnrom ? prg_ain[13] : ((weird_mode && !prg_rom_bank_mode) && prg_ain[14] ? 1'b0 : prgsel[0]));
	assign map268c[17] = (!m268_reg[0][7] ? chrsel[7] : m268_reg[0][3]);
	assign map268c[16:13] = (gnrom ? {~m268_reg[2][6:4], 1'b1} & m268_reg[2][3:0] : (weird_mode && chr_ain[10] ? 4'h0 : chrsel[6:3]));
	assign map268c[12:11] = (weird_mode && chr_ain[10] ? 2'h0 : chrsel[2:1]);
	assign map268c[10] = (weird_mode && chr_ain[10] ? 1'b0 : (use_chr_ain_12 || !weird_mode ? chrsel[0] : (chr_ain[12] ? chr_bank_1_0 : chr_bank_0_0)));
	wire m268_chr_ram = {map268c[17:11], 1'b1} == m268_reg[4];
	wire [5:0] m45_prg_and = ~m45_reg[3][5:0];
	wire [7:0] m45_chr_and = 8'hff >> (4'hf - m45_reg[2][3:0]);
	wire [7:0] m45_chr_or = m45_reg[0];
	wire [7:0] m45_prg_final = {m45_reg[1][7:6], (prgsel[5:0] & m45_prg_and) | m45_reg[1][5:0]};
	wire [7:0] m45_chr_final = (chrsel[7:0] & m45_chr_and) | m45_chr_or;
	wire [4:0] m52_prg_and = (m52_reg[3] ? 5'b01111 : 5'b11111);
	wire [7:0] m52_prg_or = (m52_reg[3] ? {1'b0, m52_reg[2:0], 4'b0000} : {1'b0, m52_reg[2:1], 5'b00000});
	wire [7:0] m52_chr_and = (m52_reg[6] ? 8'b01111111 : 8'b11111111);
	wire [9:0] m52_chr_or = (m52_reg[6] ? {m52_reg[5], m52_reg[2], m52_reg[4], 7'b0000000} : {m52_reg[5], m52_reg[2], 8'b00000000});
	wire [7:0] m52_prg_final = (prgsel[4:0] & m52_prg_and) | m52_prg_or;
	wire [9:0] m52_chr_final = (chrsel[7:0] & m52_chr_and) | m52_chr_or;
	wire [21:0] prg_aout_tmp = {1'b0, (mapper268 ? map268p[20:13] : (mapper45 ? m45_prg_final : (mapper52 ? m52_prg_final : prgsel))), prg_ain[12:0]};
	wire ram_enable_a = (!MMC6 ? ram_enable[prg_ain[12:11]] : (((ram6_enabled && ram6_enable) && (prg_ain[12] == 1'b1)) && (prg_ain[9] == 1'b0)) || (((ram6_enabled && ram_enable[3]) && (prg_ain[12] == 1'b1)) && (prg_ain[9] == 1'b1)));
	wire ram_protect_a = (!MMC6 ? ram_protect[prg_ain[12:11]] : !((((ram6_enabled && ram6_enable) && ram6_protect) && (prg_ain[12] == 1'b1)) && (prg_ain[9] == 1'b0)) && !((((ram6_enabled && ram_enable[3]) && ram_protect[3]) && (prg_ain[12] == 1'b1)) && (prg_ain[9] == 1'b1)));
	wire chr_ram_cs = (TQROM ? chrsel[6] : (mapper74 ? chrsel[7:1] == 7'b0000100 : (mapper191 ? chrsel[7] : (mapper192 ? chrsel[7:2] == 6'b000010 : (mapper194 ? chrsel[7:1] == 7'b0000000 : (mapper195 ? chrsel[7:2] == 6'b000000 : flags[15]))))));
	assign chr_allow = chr_ram_cs | (four_screen_mirroring & chr_ain[13]);
	assign chr_aout = (four_screen_mirroring & chr_ain[13] ? {10'b1111111100, chr_ain[11:0]} : (TQROM & chr_ram_cs ? {9'b111111111, chrsel[2:0], chr_ain[9:0]} : (mapper74 & chr_ram_cs ? {11'b11111111111, chrsel[0], chr_ain[9:0]} : (mapper191 & chr_ram_cs ? {11'b11111111111, chrsel[0], chr_ain[9:0]} : (mapper192 & chr_ram_cs ? {10'b1111111111, chrsel[1:0], chr_ain[9:0]} : (mapper194 & chr_ram_cs ? {11'b11111111111, chrsel[0], chr_ain[9:0]} : (mapper195 & chr_ram_cs ? {10'b1111111111, chrsel[1:0], chr_ain[9:0]} : (m268_chr_ram ? {11'b11111111111, chr_ain[10:0]} : (mapper268 ? {4'b1000, map268c, chr_ain[9:0]} : (mapper45 & flags[15] ? {9'b111111111, chr_ain[12:0]} : (mapper45 ? {2'b10, m45_reg[2][5:4], m45_chr_final, chr_ain[9:0]} : (mapper52 ? {2'b10, m52_chr_final, chr_ain[9:0]} : {3'b100, chrsel, chr_ain[9:0]}))))))))))));
	wire ram_a13 = (mapper268 && m268_reg[3][5]) && (prg_ain[15:12] == 4'h5);
	assign prg_is_ram = ((ram_a13 || ((prg_ain[15:13] == 3'b011) && ((prg_ain[12:8] == 5'b11111) | ~internal_128))) && ram_enable_a) && !(ram_protect_a && prg_write);
	assign prg_allow = (prg_ain[15] && !prg_write) || ((prg_is_ram && !mapper47) && !mapper208);
	wire [21:0] prg_ram = {8'b11110000, ram_a13, (internal_128 ? 6'b000000 : (MMC6 ? {3'b000, prg_ain[9:7]} : prg_ain[12:7])), prg_ain[6:0]};
	assign prg_aout = (((((prg_is_ram && !mapper47) && !mapper208) && !DxROM) && !mapper95) && !mapper88 ? prg_ram : prg_aout_tmp);
	assign vram_a10 = (TxSROM ? chrsel[7] : (mapper95 ? chrsel[5] : (mapper154 ? mirroring : (mapper207 ? chrsel[7] : (mirroring ? chr_ain[10] : chr_ain[11])))));
	assign vram_ce = chr_ain[13] && !four_screen_mirroring;
endmodule
module Mapper165 (
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
	m2_inv,
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
	input m2_inv;
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
	reg irq;
	assign irq_b = (enable ? irq : 1'hz);
	reg [15:0] flags_out = 0;
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	reg [2:0] bank_select;
	reg prg_rom_bank_mode;
	reg chr_a12_invert;
	reg mirroring;
	reg irq_enable;
	reg irq_reload;
	reg [7:0] irq_latch;
	reg [7:0] counter;
	reg ram_enable;
	reg ram_protect;
	reg [5:0] prg_bank_0;
	reg [5:0] prg_bank_1;
	wire prg_is_ram;
	reg [7:0] chr_bank_0;
	reg [7:0] chr_bank_1;
	reg [7:0] chr_bank_2;
	reg [7:0] chr_bank_4;
	reg latch_0;
	reg latch_1;
	wire [7:0] new_counter = ((counter == 0) || irq_reload ? irq_latch : counter - 1'd1);
	reg [3:0] a12_ctr;
	reg last_a12 = 0;
	always @(posedge clk)
		if (~enable) begin
			irq <= 0;
			bank_select <= 0;
			prg_rom_bank_mode <= 0;
			chr_a12_invert <= 0;
			mirroring <= flags[14];
			{irq_enable, irq_reload} <= 0;
			{irq_latch, counter} <= 0;
			{ram_enable, ram_protect} <= 0;
			{chr_bank_0, chr_bank_1, chr_bank_2, chr_bank_4} <= 0;
			{prg_bank_0, prg_bank_1} <= 0;
			a12_ctr <= 0;
			last_a12 <= 0;
		end
		else begin
			if (ce) begin
				if (prg_write && prg_ain[15])
					case ({prg_ain[14], prg_ain[13], prg_ain[0]})
						3'b000: {chr_a12_invert, prg_rom_bank_mode, bank_select} <= {prg_din[7], prg_din[6], prg_din[2:0]};
						3'b001:
							case (bank_select)
								0: chr_bank_0 <= {prg_din[7:1], 1'b0};
								1: chr_bank_1 <= {prg_din[7:1], 1'b0};
								2: chr_bank_2 <= prg_din;
								3:
									;
								4: chr_bank_4 <= prg_din;
								5:
									;
								6: prg_bank_0 <= prg_din[5:0];
								7: prg_bank_1 <= prg_din[5:0];
							endcase
						3'b010: mirroring <= prg_din[0];
						3'b011: {ram_enable, ram_protect} <= prg_din[7:6];
						3'b100: irq_latch <= prg_din;
						3'b101: irq_reload <= 1;
						3'b110: begin
							irq_enable <= 0;
							irq <= 0;
						end
						3'b111: irq_enable <= 1;
					endcase
			end
			if (m2_inv)
				a12_ctr <= (a12_ctr != 0 ? a12_ctr - 4'b0001 : a12_ctr);
			if (~paused) begin
				last_a12 <= chr_ain_o[12];
				if ((!last_a12 && chr_ain_o[12]) && (a12_ctr == 0)) begin
					counter <= new_counter;
					if ((((counter != 0) || irq_reload) && (new_counter == 0)) && irq_enable)
						irq <= 1;
					irq_reload <= 0;
				end
				if (chr_ain_o[12])
					a12_ctr <= 4'b0011;
			end
		end
	reg [5:0] prgsel;
	always @(*)
		casez ({prg_ain[14:13], prg_rom_bank_mode})
			3'b000: prgsel = prg_bank_0;
			3'b001: prgsel = 6'b111110;
			3'b01z: prgsel = prg_bank_1;
			3'b100: prgsel = 6'b111110;
			3'b101: prgsel = prg_bank_0;
			3'b11z: prgsel = 6'b111111;
		endcase
	wire [21:0] prg_aout_tmp = {3'b000, prgsel, prg_ain[12:0]};
	always @(posedge clk)
		if (ce && chr_read) begin
			latch_0 <= (chr_ain_o == 14'h0fd0 ? 1'd0 : (chr_ain_o == 14'h0fe0 ? 1'd1 : latch_0));
			latch_1 <= (chr_ain_o[13:4] == 10'h1fd ? 1'd0 : (chr_ain_o[13:4] == 10'h1fe ? 1'd1 : latch_1));
		end
	reg [7:0] chrsel;
	always @(*)
		casez ({chr_ain[12] ^ chr_a12_invert, latch_0, latch_1})
			3'b00z: chrsel = chr_bank_0;
			3'b01z: chrsel = chr_bank_1;
			3'b1z0: chrsel = chr_bank_2;
			3'b1z1: chrsel = chr_bank_4;
		endcase
	assign chr_allow = !chrsel;
	assign chr_aout = (!chrsel ? {10'b1111111111, chr_ain[11:0]} : {4'b1000, chrsel[7:2], chr_ain[11:0]});
	assign prg_is_ram = (((prg_ain >= 'h6000) && (prg_ain < 'h8000)) && ram_enable) && !(ram_protect && prg_write);
	assign prg_allow = (prg_ain[15] && !prg_write) || prg_is_ram;
	wire [21:0] prg_ram = {9'b111100000, prg_ain[12:0]};
	assign prg_aout = (prg_is_ram ? prg_ram : prg_aout_tmp);
	assign vram_a10 = (mirroring ? chr_ain[11] : chr_ain[10]);
	assign vram_ce = chr_ain[13];
endmodule
module Mapper413 (
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
	m2_inv,
	paused,
	prg_aoute
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
	input m2_inv;
	input paused;
	output wire [2:0] prg_aoute;
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
	wire irq;
	assign irq_b = (enable ? irq : 1'hz);
	reg [15:0] flags_out = 0;
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	reg irq_enable;
	reg irq_reload;
	reg [7:0] irq_latch;
	reg [7:0] counter;
	reg [4:0] irq_reg;
	assign irq = irq_reg[0];
	wire [7:0] new_counter = ((counter == 0) || irq_reload ? irq_latch : counter - 1'd1);
	reg [3:0] a12_ctr;
	reg last_a12 = 0;
	reg misc_inc;
	reg old_misc_inc;
	reg misc_ctrl;
	reg [22:0] prg_amisc;
	wire prg_is_misc = (prg_ain[15:11] == 5'b01001) | (prg_ain[15:12] == 4'b1100);
	assign prg_aoute = (prg_is_misc ? {2'b10, prg_amisc[22]} : 3'd0);
	reg [5:0] bank_reg [0:3];
	always @(posedge clk)
		if (~enable) begin
			irq_reg <= 5'b00000;
			{irq_enable, irq_reload} <= 0;
			{irq_latch, counter} <= 0;
			bank_reg[0] <= 0;
			bank_reg[1] <= 0;
			bank_reg[2] <= 0;
			bank_reg[3] <= 0;
			prg_amisc <= 0;
			misc_ctrl <= 0;
			misc_inc <= 0;
			old_misc_inc <= 0;
			a12_ctr <= 0;
			last_a12 <= 0;
		end
		else begin
			if (ce) begin
				if (prg_write && prg_ain[15])
					casez (prg_ain[14:12])
						3'b000: irq_latch <= prg_din;
						3'b001: irq_reload <= 1;
						3'b010: begin
							irq_enable <= 0;
							irq_reg[0] <= 0;
						end
						3'b011: irq_enable <= 1;
						3'b100: prg_amisc <= {prg_amisc[21:0], prg_din[7]};
						3'b101: misc_ctrl <= prg_din[1];
						3'b11z: bank_reg[prg_din[7:6]] <= prg_din[5:0];
					endcase
				misc_inc <= 0;
				old_misc_inc <= misc_inc;
				if (prg_read && prg_is_misc)
					misc_inc <= 1;
				if ((old_misc_inc && !misc_inc) && misc_ctrl)
					prg_amisc <= prg_amisc + 23'd1;
			end
			if (m2_inv) begin
				a12_ctr <= (a12_ctr != 0 ? a12_ctr - 4'b0001 : a12_ctr);
				irq_reg[4:1] <= irq_reg[3:0];
			end
			if (~paused) begin
				last_a12 <= chr_ain_o[12];
				if ((!last_a12 && chr_ain_o[12]) && (a12_ctr == 0)) begin
					counter <= new_counter;
					if ((((counter != 0) || irq_reload) && (new_counter == 0)) && irq_enable)
						irq_reg[0] <= 1;
					irq_reload <= 0;
				end
				if (chr_ain_o[12])
					a12_ctr <= 4'b0011;
			end
		end
	reg [5:0] prgsel;
	always @(*)
		casez (prg_ain[15:11])
			5'b00zzz: prgsel = 6'b000000;
			5'b010zz: prgsel = 6'b000000;
			5'b011zz: prgsel = bank_reg[0];
			5'b100zz: prgsel = bank_reg[1];
			5'b101zz: prgsel = bank_reg[2];
			5'b110zz: prgsel = 6'b000011;
			5'b111zz: prgsel = 6'b000100;
		endcase
	reg [5:0] chrsel;
	always @(*)
		case (chr_ain[12])
			1'b0: chrsel = bank_reg[3];
			1'b1: chrsel = 6'b111101;
		endcase
	wire [21:0] prg_aout_tmp = {3'b000, prgsel, prg_ain[12:0]};
	assign chr_allow = flags[15];
	assign chr_aout = {4'b1000, chrsel, chr_ain[11:0]};
	assign prg_allow = (prg_ain[15] || (prg_ain[14] && (prg_ain[13:11] != 3'b000))) && !prg_write;
	assign prg_aout = (prg_is_misc ? prg_amisc[21:0] : prg_aout_tmp);
	assign vram_a10 = (flags[14] ? chr_ain[10] : chr_ain[11]);
	assign vram_ce = chr_ain[13];
endmodule
