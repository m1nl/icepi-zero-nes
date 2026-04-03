// this file is converted from sv to v with sv2v utility (https://github.com/zachjs/sv2v).
module LenCounterUnit (
	clk,
	reset,
	cold_reset,
	len_clk,
	aclk1,
	aclk1_d,
	load_value,
	halt_in,
	addr,
	is_triangle,
	write,
	enabled,
	lc_on
);
	input wire clk;
	input wire reset;
	input wire cold_reset;
	input wire len_clk;
	input wire aclk1;
	input wire aclk1_d;
	input wire [7:0] load_value;
	input wire halt_in;
	input wire addr;
	input wire is_triangle;
	input wire write;
	input wire enabled;
	output reg lc_on;
	always @(posedge clk) begin : lenunit
		reg [7:0] len_counter_int;
		reg halt;
		reg halt_next;
		reg [7:0] len_counter_next;
		reg lc_on_1;
		reg clear_next;
		if (aclk1_d) begin
			if (~enabled)
				lc_on <= 0;
		end
		if (aclk1) begin
			lc_on_1 <= lc_on;
			len_counter_next <= (halt || ~|len_counter_int ? len_counter_int : len_counter_int - 1'd1);
			clear_next <= ~halt && ~|len_counter_int;
		end
		if (write) begin
			if (~addr)
				halt <= halt_in;
			else begin
				lc_on <= 1;
				len_counter_int <= load_value;
			end
		end
		if (len_clk && lc_on_1) begin
			len_counter_int <= (halt ? len_counter_int : len_counter_next);
			if (clear_next)
				lc_on <= 0;
		end
		if (reset) begin
			if (~is_triangle || cold_reset)
				halt <= 0;
			lc_on <= 0;
			len_counter_int <= 0;
			len_counter_next <= 0;
		end
	end
endmodule
module EnvelopeUnit (
	clk,
	reset,
	env_clk,
	din,
	addr,
	write,
	envelope
);
	input wire clk;
	input wire reset;
	input wire env_clk;
	input wire [5:0] din;
	input wire addr;
	input wire write;
	output wire [3:0] envelope;
	reg [3:0] env_count;
	reg [3:0] env_vol;
	reg env_disabled;
	assign envelope = (env_disabled ? env_vol : env_count);
	always @(posedge clk) begin : envunit
		reg [3:0] env_div;
		reg env_reload;
		reg env_loop;
		reg env_reset;
		if (env_clk) begin
			if (~env_reload) begin
				env_div <= env_div - 1'd1;
				if (~|env_div) begin
					env_div <= env_vol;
					if (|env_count || env_loop)
						env_count <= env_count - 1'd1;
				end
			end
			else begin
				env_div <= env_vol;
				env_count <= 4'hf;
				env_reload <= 1'b0;
			end
		end
		if (write) begin
			if (~addr)
				{env_loop, env_disabled, env_vol} <= din;
			if (addr)
				env_reload <= 1;
		end
		if (reset) begin
			env_loop <= 0;
			env_div <= 0;
			env_vol <= 0;
			env_count <= 0;
			env_reload <= 0;
		end
	end
endmodule
module SquareChan (
	MMC5,
	clk,
	ce,
	aclk1,
	aclk1_d,
	reset,
	cold_reset,
	allow_us,
	sq2,
	Addr,
	DIN,
	write,
	lc_load,
	LenCtr_Clock,
	Env_Clock,
	odd_or_even,
	Enabled,
	Sample,
	IsNonZero
);
	reg _sv2v_0;
	input wire MMC5;
	input wire clk;
	input wire ce;
	input wire aclk1;
	input wire aclk1_d;
	input wire reset;
	input wire cold_reset;
	input wire allow_us;
	input wire sq2;
	input wire [1:0] Addr;
	input wire [7:0] DIN;
	input wire write;
	input wire [7:0] lc_load;
	input wire LenCtr_Clock;
	input wire Env_Clock;
	input wire odd_or_even;
	input wire Enabled;
	output wire [3:0] Sample;
	output wire IsNonZero;
	reg [1:0] Duty;
	reg SweepEnable;
	reg SweepNegate;
	reg SweepReset;
	reg [2:0] SweepPeriod;
	reg [2:0] SweepDivider;
	reg [2:0] SweepShift;
	reg [10:0] Period;
	reg [11:0] TimerCtr;
	reg [2:0] SeqPos;
	wire [10:0] ShiftedPeriod;
	wire [10:0] PeriodRhs;
	wire [11:0] NewSweepPeriod;
	wire ValidFreq;
	wire subunit_write;
	wire [3:0] Envelope;
	wire lc;
	wire DutyEnabledUsed;
	reg DutyEnabled;
	assign DutyEnabledUsed = MMC5 ^ DutyEnabled;
	assign ShiftedPeriod = Period >> SweepShift;
	assign PeriodRhs = (SweepNegate ? ~ShiftedPeriod + {10'b0000000000, sq2} : ShiftedPeriod);
	assign NewSweepPeriod = Period + PeriodRhs;
	assign subunit_write = ((Addr == 0) || (Addr == 3)) & write;
	assign IsNonZero = lc;
	assign ValidFreq = (MMC5 && allow_us) || (|Period[10:3] && (SweepNegate || ~NewSweepPeriod[11]));
	assign Sample = ((~lc | ~ValidFreq) | ~DutyEnabledUsed ? 4'd0 : Envelope);
	LenCounterUnit LenSq(
		.clk(clk),
		.reset(reset),
		.cold_reset(cold_reset),
		.aclk1(aclk1),
		.aclk1_d(aclk1_d),
		.len_clk((MMC5 ? Env_Clock : LenCtr_Clock)),
		.load_value(lc_load),
		.halt_in(DIN[5]),
		.addr(Addr[0]),
		.is_triangle(1'b0),
		.write(subunit_write),
		.enabled(Enabled),
		.lc_on(lc)
	);
	EnvelopeUnit EnvSq(
		.clk(clk),
		.reset(reset),
		.env_clk(Env_Clock),
		.din(DIN[5:0]),
		.addr(Addr[0]),
		.write(subunit_write),
		.envelope(Envelope)
	);
	always @(*) begin
		if (_sv2v_0)
			;
		case (Duty)
			0: DutyEnabled = SeqPos == 7;
			1: DutyEnabled = SeqPos >= 6;
			2: DutyEnabled = SeqPos >= 4;
			3: DutyEnabled = SeqPos < 6;
		endcase
	end
	always @(posedge clk) begin : sqblock
		if (aclk1_d) begin
			if (TimerCtr == 0) begin
				TimerCtr <= {1'b0, Period};
				SeqPos <= SeqPos - 1'd1;
			end
			else
				TimerCtr <= TimerCtr - 1'd1;
		end
		if (LenCtr_Clock) begin
			if (SweepDivider == 0) begin
				SweepDivider <= SweepPeriod;
				if ((SweepEnable && (SweepShift != 0)) && ValidFreq)
					Period <= NewSweepPeriod[10:0];
			end
			else
				SweepDivider <= SweepDivider - 1'd1;
			if (SweepReset)
				SweepDivider <= SweepPeriod;
			SweepReset <= 0;
		end
		if (write)
			case (Addr)
				0: Duty <= DIN[7:6];
				1:
					if (~MMC5) begin
						{SweepEnable, SweepPeriod, SweepNegate, SweepShift} <= DIN;
						SweepReset <= 1;
					end
				2: Period[7:0] <= DIN;
				3: begin
					Period[10:8] <= DIN[2:0];
					SeqPos <= 0;
				end
			endcase
		if (reset) begin
			Duty <= 0;
			SweepEnable <= 0;
			SweepNegate <= 0;
			SweepReset <= 0;
			SweepPeriod <= 0;
			SweepDivider <= 0;
			SweepShift <= 0;
			Period <= 0;
			TimerCtr <= 0;
			SeqPos <= 0;
		end
	end
	initial _sv2v_0 = 0;
endmodule
module TriangleChan (
	clk,
	phi1,
	aclk1,
	aclk1_d,
	reset,
	cold_reset,
	allow_us,
	Addr,
	DIN,
	write,
	lc_load,
	LenCtr_Clock,
	LinCtr_Clock,
	Enabled,
	Sample,
	IsNonZero
);
	input wire clk;
	input wire phi1;
	input wire aclk1;
	input wire aclk1_d;
	input wire reset;
	input wire cold_reset;
	input wire allow_us;
	input wire [1:0] Addr;
	input wire [7:0] DIN;
	input wire write;
	input wire [7:0] lc_load;
	input wire LenCtr_Clock;
	input wire LinCtr_Clock;
	input wire Enabled;
	output wire [3:0] Sample;
	output wire IsNonZero;
	reg [10:0] Period;
	reg [10:0] applied_period;
	reg [10:0] TimerCtr;
	reg [4:0] SeqPos;
	reg [6:0] LinCtrPeriod;
	reg [6:0] LinCtrPeriod_1;
	reg [6:0] LinCtr;
	reg LinCtrl;
	reg line_reload;
	wire LinCtrZero;
	wire lc;
	wire LenCtrZero;
	wire subunit_write;
	reg [3:0] sample_latch;
	assign LinCtrZero = ~|LinCtr;
	assign IsNonZero = lc;
	assign subunit_write = ((Addr == 0) || (Addr == 3)) & write;
	assign Sample = ((applied_period > 1) || allow_us ? SeqPos[3:0] ^ {4 {~SeqPos[4]}} : sample_latch);
	LenCounterUnit LenTri(
		.clk(clk),
		.reset(reset),
		.cold_reset(cold_reset),
		.aclk1(aclk1),
		.aclk1_d(aclk1_d),
		.len_clk(LenCtr_Clock),
		.load_value(lc_load),
		.halt_in(DIN[7]),
		.addr(Addr[0]),
		.is_triangle(1'b1),
		.write(subunit_write),
		.enabled(Enabled),
		.lc_on(lc)
	);
	always @(posedge clk) begin
		if (phi1) begin
			if (TimerCtr == 0) begin
				TimerCtr <= Period;
				applied_period <= Period;
				if (IsNonZero & ~LinCtrZero)
					SeqPos <= SeqPos + 1'd1;
			end
			else
				TimerCtr <= TimerCtr - 1'd1;
		end
		if (aclk1)
			LinCtrPeriod_1 <= LinCtrPeriod;
		if (LinCtr_Clock) begin
			if (line_reload)
				LinCtr <= LinCtrPeriod_1;
			else if (!LinCtrZero)
				LinCtr <= LinCtr - 1'd1;
			if (!LinCtrl)
				line_reload <= 0;
		end
		if (write)
			case (Addr)
				0: begin
					LinCtrl <= DIN[7];
					LinCtrPeriod <= DIN[6:0];
				end
				2: Period[7:0] <= DIN;
				3: begin
					Period[10:8] <= DIN[2:0];
					line_reload <= 1;
				end
			endcase
		if (reset) begin
			sample_latch <= 4'hf;
			Period <= 0;
			TimerCtr <= 0;
			SeqPos <= 0;
			LinCtrPeriod <= 0;
			LinCtr <= 0;
			LinCtrl <= 0;
			line_reload <= 0;
		end
		if (applied_period > 1)
			sample_latch <= Sample;
	end
endmodule
module NoiseChan (
	clk,
	ce,
	aclk1,
	aclk1_d,
	reset,
	cold_reset,
	Addr,
	DIN,
	PAL,
	write,
	lc_load,
	LenCtr_Clock,
	Env_Clock,
	Enabled,
	Sample,
	IsNonZero
);
	input wire clk;
	input wire ce;
	input wire aclk1;
	input wire aclk1_d;
	input wire reset;
	input wire cold_reset;
	input wire [1:0] Addr;
	input wire [7:0] DIN;
	input wire PAL;
	input wire write;
	input wire [7:0] lc_load;
	input wire LenCtr_Clock;
	input wire Env_Clock;
	input wire Enabled;
	output wire [3:0] Sample;
	output wire IsNonZero;
	reg ShortMode;
	reg [14:0] Shift;
	reg [3:0] Period;
	wire [11:0] NoisePeriod;
	wire [11:0] TimerCtr;
	wire [3:0] Envelope;
	wire subunit_write;
	wire lc;
	assign IsNonZero = lc;
	assign subunit_write = ((Addr == 0) || (Addr == 3)) & write;
	assign Sample = (~lc || Shift[14] ? 4'd0 : Envelope);
	LenCounterUnit LenNoi(
		.clk(clk),
		.reset(reset),
		.cold_reset(cold_reset),
		.aclk1(aclk1),
		.aclk1_d(aclk1_d),
		.len_clk(LenCtr_Clock),
		.load_value(lc_load),
		.halt_in(DIN[5]),
		.addr(Addr[0]),
		.is_triangle(1'b0),
		.write(subunit_write),
		.enabled(Enabled),
		.lc_on(lc)
	);
	EnvelopeUnit EnvNoi(
		.clk(clk),
		.reset(reset),
		.env_clk(Env_Clock),
		.din(DIN[5:0]),
		.addr(Addr[0]),
		.write(subunit_write),
		.envelope(Envelope)
	);
	wire [175:0] noise_pal_lut;
	assign noise_pal_lut = 176'h400a02a85d5727d3f0dc1fcc2717570939fc4b73cb92;
	wire [175:0] noise_ntsc_lut;
	assign noise_ntsc_lut = 176'h400a01546ea9c99d318730958c1391230427e0803014;
	reg [10:0] noise_timer;
	reg noise_clock;
	always @(posedge clk) begin
		if (aclk1_d) begin
			noise_timer <= {noise_timer[9:0], (noise_timer[10] ^ noise_timer[8]) | ~|noise_timer};
			if (noise_clock) begin
				noise_clock <= 0;
				noise_timer <= (PAL ? noise_pal_lut[(15 - Period) * 11+:11] : noise_ntsc_lut[(15 - Period) * 11+:11]);
				Shift <= {Shift[13:0], (Shift[14] ^ (ShortMode ? Shift[8] : Shift[13])) | ~|Shift};
			end
		end
		if (aclk1) begin
			if (noise_timer == 'h400)
				noise_clock <= 1;
		end
		if (write && (Addr == 2)) begin
			ShortMode <= DIN[7];
			Period <= DIN[3:0];
		end
		if (reset) begin
			if (|noise_timer)
				noise_timer <= (PAL ? noise_pal_lut[165+:11] : noise_ntsc_lut[165+:11]);
			ShortMode <= 0;
			Shift <= 0;
			Period <= 0;
		end
		if (cold_reset)
			noise_timer <= 0;
	end
endmodule
module DmcChan (
	MMC5,
	clk,
	aclk1,
	aclk1_d,
	reset,
	cold_reset,
	ain,
	DIN,
	write,
	dma_ack,
	dma_data,
	PAL,
	dma_address,
	irq,
	Sample,
	dma_req,
	enable
);
	input wire MMC5;
	input wire clk;
	input wire aclk1;
	input wire aclk1_d;
	input wire reset;
	input wire cold_reset;
	input wire [2:0] ain;
	input wire [7:0] DIN;
	input wire write;
	input wire dma_ack;
	input wire [7:0] dma_data;
	input wire PAL;
	output reg [15:0] dma_address;
	output reg irq;
	output wire [6:0] Sample;
	output wire dma_req;
	output reg enable;
	reg irq_enable;
	reg loop;
	reg [3:0] frequency;
	reg [7:0] sample_address;
	reg [7:0] sample_length;
	reg [11:0] bytes_remaining;
	reg [7:0] sample_buffer;
	reg [8:0] dmc_lsfr;
	reg [7:0] dmc_volume;
	reg [7:0] dmc_volume_next;
	reg dmc_silence;
	reg have_buffer;
	reg [7:0] sample_shift;
	reg [2:0] dmc_bits;
	reg enable_1;
	reg enable_2;
	reg enable_3;
	wire [143:0] pal_pitch_lut;
	assign pal_pitch_lut = 144'heb99db343f09ecb9322568f9fcd154723757;
	wire [143:0] ntsc_pitch_lut;
	assign ntsc_pitch_lut = 144'hcea8b0bb677fe2f917901da3d3eb148dc6d5;
	assign Sample = dmc_volume_next[6:0];
	assign dma_req = (~have_buffer & enable) & enable_3;
	reg dmc_clock;
	wire reload_next;
	always @(posedge clk) begin
		dma_address[15] <= 1;
		if (write)
			case (ain)
				0: begin
					irq_enable <= DIN[7];
					loop <= DIN[6];
					frequency <= DIN[3:0];
					if (~DIN[7])
						irq <= 0;
				end
				1: dmc_volume <= {MMC5 & DIN[7], DIN[6:0]};
				2: sample_address <= (MMC5 ? 8'h00 : DIN[7:0]);
				3: sample_length <= (MMC5 ? 8'h00 : DIN[7:0]);
				5: begin
					irq <= 0;
					enable <= DIN[4];
					if (DIN[4] && ~enable) begin
						dma_address[14:0] <= {1'b1, sample_address[7:0], 6'h00};
						bytes_remaining <= {sample_length, 4'h0};
					end
				end
			endcase
		if (aclk1_d) begin
			enable_1 <= enable;
			enable_2 <= enable_1;
			dmc_lsfr <= {dmc_lsfr[7:0], (dmc_lsfr[8] ^ dmc_lsfr[4]) | ~|dmc_lsfr};
			if (dmc_clock) begin
				dmc_clock <= 0;
				dmc_lsfr <= (PAL ? pal_pitch_lut[(15 - frequency) * 9+:9] : ntsc_pitch_lut[(15 - frequency) * 9+:9]);
				sample_shift <= {1'b0, sample_shift[7:1]};
				dmc_bits <= dmc_bits + 1'd1;
				if (&dmc_bits) begin
					dmc_silence <= ~have_buffer;
					sample_shift <= sample_buffer;
					have_buffer <= 0;
				end
				if (~dmc_silence) begin
					if (~sample_shift[0]) begin
						if (|dmc_volume_next[6:1])
							dmc_volume[6:1] <= dmc_volume_next[6:1] - 1'd1;
					end
					else if (~&dmc_volume_next[6:1])
						dmc_volume[6:1] <= dmc_volume_next[6:1] + 1'd1;
				end
			end
			if (dma_ack) begin
				dma_address[14:0] <= dma_address[14:0] + 1'd1;
				have_buffer <= 1;
				sample_buffer <= dma_data;
				if (|bytes_remaining)
					bytes_remaining <= bytes_remaining - 1'd1;
				else begin
					dma_address[14:0] <= {1'b1, sample_address[7:0], 6'h00};
					bytes_remaining <= {sample_length, 4'h0};
					enable <= loop;
					if (~loop & irq_enable)
						irq <= 1;
				end
			end
		end
		if (aclk1) begin
			enable_1 <= enable;
			enable_3 <= enable_2;
			dmc_volume_next <= dmc_volume;
			if (dmc_lsfr == 9'h100)
				dmc_clock <= 1;
		end
		if (reset) begin
			irq <= 0;
			dmc_volume <= {7'h00, dmc_volume[0]};
			dmc_volume_next <= {7'h00, dmc_volume[0]};
			sample_shift <= 8'h00;
			if (|dmc_lsfr)
				dmc_lsfr <= (PAL ? pal_pitch_lut[135+:9] : ntsc_pitch_lut[135+:9]);
			bytes_remaining <= 0;
			dmc_bits <= 0;
			sample_buffer <= 0;
			have_buffer <= 0;
			enable <= 0;
			enable_1 <= 0;
			enable_2 <= 0;
			enable_3 <= 0;
			dma_address[14:0] <= 15'h0000;
		end
		if (cold_reset) begin
			dmc_lsfr <= 0;
			loop <= 0;
			frequency <= 0;
			irq_enable <= 0;
			dmc_volume <= 0;
			dmc_volume_next <= 0;
			sample_address <= 0;
			sample_length <= 0;
		end
	end
endmodule
module FrameCtr (
	clk,
	aclk1,
	aclk2,
	reset,
	cold_reset,
	write,
	read,
	write_ce,
	din,
	addr,
	PAL,
	MMC5,
	irq,
	irq_flag,
	frame_half,
	frame_quarter
);
	input wire clk;
	input wire aclk1;
	input wire aclk2;
	input wire reset;
	input wire cold_reset;
	input wire write;
	input wire read;
	input wire write_ce;
	input wire [7:0] din;
	input wire [1:0] addr;
	input wire PAL;
	input wire MMC5;
	output wire irq;
	output wire irq_flag;
	output wire frame_half;
	output wire frame_quarter;
	wire frame_reset;
	reg frame_interrupt_buffer;
	wire frame_int_disabled;
	reg FrameInterrupt;
	wire frame_irq;
	wire set_irq;
	reg FrameSeqMode_2;
	reg frame_reset_2;
	reg w4017_1;
	reg w4017_2;
	reg [14:0] frame;
	reg DisableFrameInterrupt;
	reg FrameSeqMode;
	assign frame_int_disabled = DisableFrameInterrupt;
	assign irq = FrameInterrupt && ~DisableFrameInterrupt;
	assign irq_flag = frame_interrupt_buffer;
	wire seq_mode;
	assign seq_mode = (aclk1 ? FrameSeqMode : FrameSeqMode_2);
	wire frm_a;
	wire frm_b;
	wire frm_c;
	wire frm_d;
	wire frm_e;
	assign frm_a = (PAL ? 15'b001111110100100 : 15'b001000001100001) == frame;
	assign frm_b = (PAL ? 15'b100010000110000 : 15'b011011000000011) == frame;
	assign frm_c = (PAL ? 15'b101100000010101 : 15'b010110011010011) == frame;
	assign frm_d = ((PAL ? 15'b000101111101000 : 15'b000101000011111) == frame) && ~seq_mode;
	assign frm_e = (PAL ? 15'b000010011111010 : 15'b111000110000101) == frame;
	assign set_irq = frm_d & ~FrameSeqMode;
	assign frame_reset = (frm_d | frm_e) | w4017_2;
	assign frame_half = ((frm_b | frm_d) | frm_e) | (w4017_2 & seq_mode);
	assign frame_quarter = ((((frm_a | frm_b) | frm_c) | frm_d) | frm_e) | (w4017_2 & seq_mode);
	always @(posedge clk) begin : apu_block
		if (aclk1) begin
			frame <= (frame_reset_2 ? 15'h7fff : {frame[13:0], (frame[14] ^ frame[13]) | ~|frame});
			w4017_2 <= w4017_1;
			w4017_1 <= 0;
			FrameSeqMode_2 <= FrameSeqMode;
			frame_reset_2 <= 0;
		end
		if (aclk2 & frame_reset)
			frame_reset_2 <= 1;
		if (set_irq & ~frame_int_disabled) begin
			FrameInterrupt <= 1;
			frame_interrupt_buffer <= 1;
		end
		else if ((addr == 2'h1) && read)
			FrameInterrupt <= 0;
		else
			frame_interrupt_buffer <= FrameInterrupt;
		if (frame_int_disabled)
			FrameInterrupt <= 0;
		if ((write_ce && (addr == 3)) && ~MMC5) begin
			FrameSeqMode <= din[7];
			DisableFrameInterrupt <= din[6];
			w4017_1 <= 1;
		end
		if (reset) begin
			FrameInterrupt <= 0;
			frame_interrupt_buffer <= 0;
			w4017_1 <= 0;
			w4017_2 <= 0;
			DisableFrameInterrupt <= 0;
			if (cold_reset)
				FrameSeqMode <= 0;
			frame <= 15'h7fff;
		end
	end
endmodule
module APU (
	MMC5,
	clk,
	PHI2,
	ce,
	reset,
	cold_reset,
	allow_us,
	PAL,
	ADDR,
	DIN,
	RW,
	CS,
	audio_channels,
	DmaData,
	odd_or_even,
	DmaAck,
	DOUT,
	Sample,
	DmaReq,
	DmaAddr,
	IRQ
);
	input wire MMC5;
	input wire clk;
	input wire PHI2;
	input wire ce;
	input wire reset;
	input wire cold_reset;
	input wire allow_us;
	input wire PAL;
	input wire [4:0] ADDR;
	input wire [7:0] DIN;
	input wire RW;
	input wire CS;
	input wire [4:0] audio_channels;
	input wire [7:0] DmaData;
	input wire odd_or_even;
	input wire DmaAck;
	output wire [7:0] DOUT;
	output wire [15:0] Sample;
	output wire DmaReq;
	output wire [15:0] DmaAddr;
	output wire IRQ;
	wire [255:0] len_counter_lut;
	assign len_counter_lut = 256'h09fd130127034f059f073b090d0b190d0b0f17112f135f15bf1747190f1b1f1d;
	wire [7:0] lc_load;
	assign lc_load = len_counter_lut[(31 - DIN[7:3]) * 8+:8];
	wire read;
	wire read_old;
	wire write;
	wire write_ce;
	wire write_old;
	reg phi2_old;
	wire phi2_ce;
	assign read = RW & CS;
	assign write = ~RW & CS;
	assign phi2_ce = PHI2 & ~phi2_old;
	assign write_ce = write & phi2_ce;
	wire aclk1;
	wire aclk2;
	wire aclk1_delayed;
	wire phi1;
	assign aclk1 = ce & odd_or_even;
	assign aclk2 = phi2_ce & ~odd_or_even;
	assign aclk1_delayed = ce & ~odd_or_even;
	assign phi1 = ce;
	wire [4:0] Enabled;
	wire [3:0] Sq1Sample;
	wire [3:0] Sq2Sample;
	wire [3:0] TriSample;
	wire [3:0] NoiSample;
	wire [6:0] DmcSample;
	wire DmcIrq;
	wire IsDmcActive;
	wire irq_flag;
	wire frame_irq;
	wire ApuMW0;
	wire ApuMW1;
	wire ApuMW2;
	wire ApuMW3;
	wire ApuMW4;
	wire ApuMW5;
	assign ApuMW0 = ADDR[4:2] == 0;
	assign ApuMW1 = ADDR[4:2] == 1;
	assign ApuMW2 = ADDR[4:2] == 2;
	assign ApuMW3 = ADDR[4:2] == 3;
	assign ApuMW4 = ADDR[4:2] >= 4;
	assign ApuMW5 = ADDR[4:2] == 5;
	wire Sq1NonZero;
	wire Sq2NonZero;
	wire TriNonZero;
	wire NoiNonZero;
	wire ClkE;
	wire ClkL;
	reg [4:0] enabled_buffer;
	reg [4:0] enabled_buffer_1;
	assign Enabled = (aclk1 ? enabled_buffer : enabled_buffer_1);
	always @(posedge clk) begin
		phi2_old <= PHI2;
		if (aclk1)
			enabled_buffer_1 <= enabled_buffer;
		if ((ApuMW5 && write) && (ADDR[1:0] == 1))
			enabled_buffer <= DIN[4:0];
		if (reset) begin
			enabled_buffer <= 0;
			enabled_buffer_1 <= 0;
		end
	end
	wire frame_quarter;
	wire frame_half;
	assign ClkE = frame_quarter & aclk1_delayed;
	assign ClkL = frame_half & aclk1_delayed;
	assign DOUT = {DmcIrq, irq_flag, 1'b0, IsDmcActive, NoiNonZero, TriNonZero, Sq2NonZero, Sq1NonZero};
	assign IRQ = frame_irq || DmcIrq;
	SquareChan Squ1(
		.MMC5(MMC5),
		.clk(clk),
		.ce(ce),
		.aclk1(aclk1),
		.aclk1_d(aclk1_delayed),
		.reset(reset),
		.cold_reset(cold_reset),
		.allow_us(allow_us),
		.sq2(1'b0),
		.Addr(ADDR[1:0]),
		.DIN(DIN),
		.write(ApuMW0 && write),
		.lc_load(lc_load),
		.LenCtr_Clock(ClkL),
		.Env_Clock(ClkE),
		.odd_or_even(odd_or_even),
		.Enabled(Enabled[0]),
		.Sample(Sq1Sample),
		.IsNonZero(Sq1NonZero)
	);
	SquareChan Squ2(
		.MMC5(MMC5),
		.clk(clk),
		.ce(ce),
		.aclk1(aclk1),
		.aclk1_d(aclk1_delayed),
		.reset(reset),
		.cold_reset(cold_reset),
		.allow_us(allow_us),
		.sq2(1'b1),
		.Addr(ADDR[1:0]),
		.DIN(DIN),
		.write(ApuMW1 && write),
		.lc_load(lc_load),
		.LenCtr_Clock(ClkL),
		.Env_Clock(ClkE),
		.odd_or_even(odd_or_even),
		.Enabled(Enabled[1]),
		.Sample(Sq2Sample),
		.IsNonZero(Sq2NonZero)
	);
	TriangleChan Tri(
		.clk(clk),
		.phi1(phi1),
		.aclk1(aclk1),
		.aclk1_d(aclk1_delayed),
		.reset(reset),
		.cold_reset(cold_reset),
		.allow_us(allow_us),
		.Addr(ADDR[1:0]),
		.DIN(DIN),
		.write(ApuMW2 && write),
		.lc_load(lc_load),
		.LenCtr_Clock(ClkL),
		.LinCtr_Clock(ClkE),
		.Enabled(Enabled[2]),
		.Sample(TriSample),
		.IsNonZero(TriNonZero)
	);
	NoiseChan Noi(
		.clk(clk),
		.ce(ce),
		.aclk1(aclk1),
		.aclk1_d(aclk1_delayed),
		.reset(reset),
		.cold_reset(cold_reset),
		.Addr(ADDR[1:0]),
		.DIN(DIN),
		.PAL(PAL),
		.write(ApuMW3 && write),
		.lc_load(lc_load),
		.LenCtr_Clock(ClkL),
		.Env_Clock(ClkE),
		.Enabled(Enabled[3]),
		.Sample(NoiSample),
		.IsNonZero(NoiNonZero)
	);
	DmcChan Dmc(
		.MMC5(MMC5),
		.clk(clk),
		.aclk1(aclk1),
		.aclk1_d(aclk1_delayed),
		.reset(reset),
		.cold_reset(cold_reset),
		.ain(ADDR[2:0]),
		.DIN(DIN),
		.write(write & ApuMW4),
		.dma_ack(DmaAck),
		.dma_data(DmaData),
		.PAL(PAL),
		.dma_address(DmaAddr),
		.irq(DmcIrq),
		.Sample(DmcSample),
		.dma_req(DmaReq),
		.enable(IsDmcActive)
	);
	APUMixer mixer(
		.clk(clk),
		.square1(Sq1Sample),
		.square2(Sq2Sample),
		.noise(NoiSample),
		.triangle(TriSample),
		.dmc(DmcSample),
		.sample(Sample)
	);
	FrameCtr frame_counter(
		.clk(clk),
		.aclk1(aclk1),
		.aclk2(aclk2),
		.reset(reset),
		.cold_reset(cold_reset),
		.write(ApuMW5 & write),
		.read(ApuMW5 & read),
		.write_ce(ApuMW5 & write_ce),
		.addr(ADDR[1:0]),
		.din(DIN),
		.PAL(PAL),
		.MMC5(MMC5),
		.irq(frame_irq),
		.irq_flag(irq_flag),
		.frame_half(frame_half),
		.frame_quarter(frame_quarter)
	);
endmodule
module APUMixer (
	clk,
	square1,
	square2,
	triangle,
	noise,
	dmc,
	sample
);
	input wire clk;
	input wire [3:0] square1;
	input wire [3:0] square2;
	input wire [3:0] triangle;
	input wire [3:0] noise;
	input wire [6:0] dmc;
	output reg [15:0] sample;
	wire [511:0] pulse_lut;
	assign pulse_lut = 512'h331064f09590c520f38120e14d317881a2e1cc61f4e21c92437269728eb2b322d6e2f9e31c333dd35ec37f239ed3bdf3dc73fa6417d434b451046cd0000;
	wire [95:0] tri_lut;
	assign tri_lut = 96'h00420c41461c824a2cc34e3c;
	wire [95:0] noise_lut;
	assign noise_lut = 96'h0031482cd4135586dd823968;
	wire [1023:0] dmc_lut;
	assign dmc_lut = 1024'h103040607090a0c0d0e101113141617191a1c1d1e202123242627292a2b2d2e303133343637383a3b3d3e404143444547484a4b4d4e505153545557585a5b5d5e606162646567686a6b6d6e6f7172747577787a7b7c7e7f8182848587888a8b8c8e8f919294959798999b9c9e9fa1a2a4a5a6a8a9abacaeafb1b2b3b5b6b8;
	wire [8191:0] mix_lut;
	assign mix_lut = 8192'h128024f0374049705b806d707f509110a2b0b440c5b0d710e840f9610a711b612c313cf14da15e216ea17ef18f419f61af81bf71cf61df31eee1fe920e121d922cf23c324b725a926992788287629632a4f2b392c222d092df02ed52fb9309b317d325d333c341a34f735d336ad3787385f39363a0c3ae13bb53c873d593e293ef93fc740954161422c42f743c044884550461646db47a04863492549e74aa74b674c254ce34da04e5c4f174fd1508a514251f952b05365541a54ce5581563356e55795584558f459a25a4f5afc5ba75c525cfc5da55e4e5ef65f9d604360e8618d623162d46377641864b9655a65f96698673667d46871690d69a86a436add6b766c0f6ca76d3e6dd56e6b6f006f95702970bd715071e2727373047395742474b4754275d0765d76ea77767802788d791779a17a2a7ab37b3b7bc37c4a7cd07d567ddb7e607ee47f687feb806e80f0817281f3827482f4837383f2847184ef856c85e9866686e2875e87d9885388cd894789c08a398ab18b298ba08c178c8e8d038d798dee8e638ed78f4a8fbe903090a39115918691f7926892d8934893b8942794959503957195df964c96b89724979097fb986698d1993b99a59a0e9a779ae09b489bb09c189c7f9ce69d4c9db29e189e7d9ee29f479faba00fa073a0d6a139a19ba1fda25fa2c1a322a383a3e3a443a4a3a502a562a5c0a61fa67da6dba738a796a7f2a84fa8aba907a963a9beaa19aa74aaceab28ab82abdbac35ac8eace6ad3ead96adeeae46ae9daef4af4aafa0aff6b04cb0a200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
	reg [4:0] squares;
	reg [4:0] squares_r;
	reg [8:0] mix;
	reg [8:0] tri_out;
	reg [8:0] noise_out;
	reg [8:0] dmc_out;
	reg [15:0] ch1;
	reg [15:0] ch2;
	function automatic [8:0] sv2v_cast_9;
		input reg [8:0] inp;
		sv2v_cast_9 = inp;
	endfunction
	always @(posedge clk) begin
		squares <= square1 + square2;
		squares_r <= squares;
		ch1 <= pulse_lut[(31 - squares) * 16+:16];
		tri_out <= sv2v_cast_9(tri_lut[(15 - triangle) * 6+:6]);
		noise_out <= sv2v_cast_9(noise_lut[(15 - noise) * 6+:6]);
		dmc_out <= sv2v_cast_9(dmc_lut[(127 - dmc) * 8+:8]);
		mix <= (tri_out + noise_out) + dmc_out;
		ch2 <= mix_lut[(511 - mix) * 16+:16];
		sample <= ch1 + ch2;
	end
endmodule
