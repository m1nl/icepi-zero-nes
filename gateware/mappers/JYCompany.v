module multiplier (
	clk,
	ce,
	start,
	a,
	b,
	p,
	done
);
	input clk;
	input ce;
	input start;
	input [7:0] a;
	input [7:0] b;
	output wire [15:0] p;
	output wire done;
	reg [15:0] shift_a;
	reg [15:0] product;
	reg [8:0] bindex;
	assign p = product;
	assign done = bindex[8];
	always @(posedge clk)
		if (start && ce) begin
			bindex <= 9'd1 << 1;
			product <= {8'h00, (b[0] ? a : 8'h00)};
			shift_a <= a << 1;
		end
		else if (bindex < 9'h100) begin
			product <= product + (bindex[7:0] & b ? shift_a : 16'd0);
			bindex <= bindex << 1;
			shift_a <= shift_a << 1;
		end
endmodule
module JYCompany (
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
	paused,
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
	input paused;
	input [13:0] chr_ain_o;
	wire [21:0] prg_aout;
	assign prg_aout_b = (enable ? prg_aout : 22'hzzzzzz);
	reg [7:0] prg_dout;
	assign prg_dout_b = (enable ? prg_dout : 8'hzz);
	wire prg_allow;
	assign prg_allow_b = (enable ? prg_allow : 1'hz);
	reg [21:0] chr_aout;
	assign chr_aout_b = (enable ? chr_aout : 22'hzzzzzz);
	wire chr_allow;
	assign chr_allow_b = (enable ? chr_allow : 1'hz);
	reg vram_a10;
	assign vram_a10_b = (enable ? vram_a10 : 1'hz);
	wire vram_ce;
	assign vram_ce_b = (enable ? vram_ce : 1'hz);
	wire irq;
	assign irq_b = (enable ? irq : 1'hz);
	reg prg_bus_write;
	wire [15:0] flags_out = {14'h0002, prg_bus_write, 1'b0};
	assign flags_out_b = (enable ? flags_out : 16'hzzzz);
	assign audio_b = (enable ? {1'b0, audio_in[15:1]} : 16'hzzzz);
	reg [7:0] chr_dout;
	wire mapper90 = flags[7:0] == 90;
	wire mapper211 = flags[7:0] == 211;
	wire mapper35 = flags[7:0] == 35;
	wire ram_support = mapper35 || (flags[29:26] == 4'd7);
	reg [1:0] prg_mode;
	reg [1:0] chr_mode;
	reg prg_protect_1;
	reg prg_protect_2;
	reg [3:0] mirroring;
	wire xmirr = ~mapper90;
	wire fxmirr = mapper211;
	reg [2:0] prg_ram_bank;
	reg [7:0] prg_bank [3:0];
	reg [15:0] chr_bank [7:0];
	reg [15:0] name_bank [3:0];
	reg [7:0] outer_bank;
	reg [7:0] ppu_conf;
	reg [7:0] bank_mode;
	wire [1:0] dip = 2'b00;
	reg multiply_start;
	reg [7:0] multiplier_1;
	reg [7:0] multiplier_2;
	wire [15:0] multiply_result;
	reg [7:0] accum;
	reg [7:0] accumtest;
	reg old_a12;
	reg irq_enable;
	reg irq_source;
	reg irq_pending;
	assign irq = irq_pending && irq_enable;
	reg irq_en;
	reg irq_dis;
	reg [7:0] irq_prescalar;
	reg [7:0] irq_count;
	reg [7:0] irq_xor;
	reg [7:0] irq_mode;
	always @(posedge clk) begin
		if (!enable)
			bank_mode[2] = 1'b0;
		else if (ce && prg_write)
			casez ({prg_ain[15:11], prg_ain[2:0]})
				8'b01011z00: multiplier_1 <= prg_din;
				8'b01011z01: begin
					multiplier_2 <= prg_din;
					multiply_start <= 1;
				end
				8'b01011z10: accum <= accum + prg_din;
				8'b01011z11: begin
					accum <= 0;
					accumtest <= prg_din;
				end
				8'b10000zzz: prg_bank[prg_ain[1:0]] <= prg_din;
				8'b10010zzz: chr_bank[prg_ain[2:0]][7:0] <= prg_din;
				8'b10100zzz: chr_bank[prg_ain[2:0]][15:8] <= prg_din;
				8'b101100zz: name_bank[prg_ain[1:0]][7:0] <= prg_din;
				8'b101101zz: name_bank[prg_ain[1:0]][15:8] <= prg_din;
				8'b11000000: begin
					irq_en <= prg_din[0];
					irq_dis <= !prg_din[0];
				end
				8'b11000001: irq_mode <= prg_din;
				8'b11000010: irq_dis <= 1;
				8'b11000011: irq_en <= 1;
				8'b11000100: irq_prescalar <= prg_din ^ irq_xor;
				8'b11000101: irq_count <= prg_din ^ irq_xor;
				8'b11000110: irq_xor <= prg_din;
				8'b11010z00: bank_mode <= prg_din;
				8'b11010z01: mirroring <= prg_din[3:0];
				8'b11010z10: ppu_conf <= prg_din;
				8'b11010z11: outer_bank <= prg_din;
			endcase
		if (~paused)
			old_a12 <= chr_ain_o[12];
		if ((irq_source && irq_enable) && (irq_mode[7] != irq_mode[6])) begin
			irq_prescalar <= (irq_mode[6] ? irq_prescalar + 8'd1 : irq_prescalar - 8'd1);
			if ((irq_mode[6] && ((irq_mode[2] && (irq_prescalar[2:0] == 3'h7)) || (!irq_mode[2] && (irq_prescalar == 8'hff)))) || (!irq_mode[6] && ((irq_mode[2] && (irq_prescalar[2:0] == 3'h0)) || (!irq_mode[2] && (irq_prescalar == 8'h00))))) begin
				irq_count <= (irq_mode[6] ? irq_count + 8'd1 : irq_count - 8'd1);
				if ((irq_mode[6] && (irq_count == 8'hff)) || (!irq_mode[6] && (irq_count == 8'h00)))
					irq_pending <= 1;
			end
		end
		if (irq_dis) begin
			irq_pending <= 0;
			irq_prescalar <= 0;
			irq_enable <= 0;
			irq_dis <= 0;
		end
		else if (irq_en) begin
			irq_en <= 0;
			irq_enable <= 1;
		end
	end
	always @(*)
		case (irq_mode[1:0])
			2'b00: irq_source = ce;
			2'b01: irq_source = (~paused && chr_ain_o[12]) && !old_a12;
			2'b10: irq_source = ~paused && chr_read;
			2'b11: irq_source = ce && prg_write;
		endcase
	multiplier mp(
		.clk(clk),
		.ce(ce),
		.start(multiply_start),
		.a(multiplier_1),
		.b(multiplier_2),
		.p(multiply_result),
		.done()
	);
	wire prg_6xxx = prg_ain[15:13] == 2'b11;
	wire prg_ram = prg_6xxx && !bank_mode[7];
	always @(*) begin
		prg_bus_write = 1'b1;
		if ((prg_ain == 16'h5000) || (prg_ain == 16'h5400))
			prg_dout = {dip, 6'h00};
		else if (prg_ain == 16'h5800)
			prg_dout = multiply_result[7:0];
		else if (prg_ain == 16'h5801)
			prg_dout = multiply_result[15:8];
		else if (prg_ain == 16'h5802)
			prg_dout = accum;
		else if (prg_ain == 16'h5803)
			prg_dout = accumtest;
		else begin
			prg_dout = 8'hff;
			prg_bus_write = 0;
		end
	end
	reg [1:0] prg_reg;
	always @(*)
		casez ({prg_6xxx, bank_mode[1:0]})
			3'b000: prg_reg = 2'b11;
			3'b001: prg_reg = {prg_ain[14], 1'b1};
			3'b01z: prg_reg = {prg_ain[14:13]};
			3'b1zz: prg_reg = 2'b11;
		endcase
	wire [7:0] bank_val = (!bank_mode[2] && (prg_reg == 2'b11) ? 8'hff : prg_bank[prg_reg]);
	wire [6:0] bank_order = (bank_mode[1:0] == 2'b11 ? {bank_val[0], bank_val[1], bank_val[2], bank_val[3], bank_val[4], bank_val[5], bank_val[6]} : bank_val[6:0]);
	reg [5:0] prg_sel;
	always @(*)
		casez ({prg_6xxx, bank_mode[1:0]})
			3'b000: prg_sel = {bank_order[3:0], prg_ain[14:13]};
			3'b001: prg_sel = {bank_order[4:0], prg_ain[13]};
			3'bz1z: prg_sel = {bank_order[5:0]};
			3'b100: prg_sel = {bank_order[3:0], 2'b11};
			3'b101: prg_sel = {bank_order[4:0], 1'b1};
		endcase
	assign prg_aout = (prg_ram && ram_support ? {9'b111100000, prg_ain[12:0]} : {1'b0, outer_bank[2:1], prg_sel, prg_ain[12:0]});
	assign prg_allow = (prg_ain >= 16'h6000) && (prg_ram ? ram_support : !prg_write);
	reg [1:0] chr_latch;
	always @(posedge clk)
		if (~enable)
			chr_latch <= 2'b00;
		else if (~paused && chr_read)
			chr_latch[chr_ain_o[12]] <= outer_bank[7] && ((chr_ain_o & 14'h2ff8) == 14'h0fd8 ? 1'd0 : ((chr_ain_o & 14'h2ff8) == 14'h0fe8 ? 1'd1 : chr_latch[chr_ain_o[12]]));
	reg [2:0] chr_reg;
	always @(*)
		casez (bank_mode[4:3])
			2'b00: chr_reg = 3'b000;
			2'b01: chr_reg = {chr_ain[12], chr_latch[chr_ain[12]], 1'b0};
			2'b10: chr_reg = {chr_ain[12:11], 1'b0};
			2'b11: chr_reg = {chr_ain[12:10]};
		endcase
	wire [12:0] chr_val = chr_bank[chr_reg][12:0];
	reg [12:0] chr_sel;
	wire xtend = ((mirroring[3] || bank_mode[5]) && xmirr) || fxmirr;
	wire romtables = ((chr_ain[13] && xtend) && bank_mode[5]) && (bank_mode[6] || (ppu_conf[7] ^ name_bank[chr_ain[11:10]][7]));
	always @(*)
		casez ({romtables, bank_mode[4:3]})
			3'b000: chr_sel = {chr_val[9:0], chr_ain[12:10]};
			3'b001: chr_sel = {chr_val[10:0], chr_ain[11:10]};
			3'b010: chr_sel = {chr_val[11:0], chr_ain[10]};
			3'b011: chr_sel = {chr_val[12:0]};
			3'b1zz: chr_sel = {name_bank[chr_ain[11:10]][12:0]};
		endcase
	wire [22:1] sv2v_tmp_93888;
	assign sv2v_tmp_93888 = {2'b10, outer_bank[3], (!outer_bank[5] ? outer_bank[0] : chr_sel[8]), chr_sel[7:0], chr_ain[9:0]};
	always @(*) chr_aout = sv2v_tmp_93888;
	assign chr_allow = flags[15] && ppu_conf[6];
	always @(*)
		casez ({xtend, mirroring[1:0]})
			3'b1zz: vram_a10 = name_bank[chr_ain[11:10]][0];
			3'b000: vram_a10 = chr_ain[10];
			3'b001: vram_a10 = chr_ain[11];
			3'b010: vram_a10 = 1'b0;
			3'b011: vram_a10 = 1'b1;
		endcase
	assign vram_ce = chr_ain[13] && ((!chr_read || !xtend) || !romtables);
endmodule
