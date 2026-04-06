// Implementation of HDMI Spec v1.4a
// By Sameer Puri https://github.com/sameer
// Converted from SystemVerilog to Verilog

module hdmi
#(
    // Defaults to 640x480 which should be supported by almost if not all HDMI sinks.
    // See README.md or CEA-861-D for enumeration of video id codes.
    // Pixel repetition, interlaced scans and other special output modes are not implemented (yet).
    parameter VIDEO_ID_CODE = 2,

    // The IT content bit indicates that image samples are generated in an ad-hoc
    // manner (e.g. directly from values in a framebuffer, as by a PC video
    // card) and therefore aren't suitable for filtering or analog
    // reconstruction.  This is probably what you want if you treat pixels
    // as "squares".  If you generate a properly bandlimited signal or obtain
    // one from elsewhere (e.g. a camera), this can be turned off.
    //
    // This flag also tends to cause receivers to treat RGB values as full
    // range (0-255).
    parameter IT_CONTENT = 1'b1,

    // Defaults to minimum bit lengths required to represent positions.
    // Modify these parameters if you have alternate desired bit lengths.
    parameter BIT_WIDTH = VIDEO_ID_CODE < 4 ? 10 : VIDEO_ID_CODE == 4 ? 11 : 12,
    parameter BIT_HEIGHT = VIDEO_ID_CODE == 16 ? 11 : 10,

    // A true HDMI signal sends auxiliary data (i.e. audio, preambles) which prevents it from being parsed by DVI signal sinks.
    // HDMI signal sinks are fortunately backwards-compatible with DVI signals.
    // Enable this flag if the output should be a DVI signal. You might want to do this to reduce resource usage or if you're only outputting video.
    parameter DVI_OUTPUT = 1'b0,

    // **All parameters below matter ONLY IF you plan on sending auxiliary data (DVI_OUTPUT == 1'b0)**

    // As specified in Section 7.3, the minimal audio requirements are met: 16-bit or more L-PCM audio at 32 kHz, 44.1 kHz, or 48 kHz.
    // See Table 7-4 or README.md for an enumeration of sampling frequencies supported by HDMI.
    // Note that sinks may not support rates above 48 kHz.
    parameter AUDIO_RATE = 48000,

    // Defaults to 16-bit audio, the minmimum supported by HDMI sinks. Can be anywhere from 16-bit to 24-bit.
    parameter AUDIO_BIT_WIDTH = 24,

    // Some HDMI sinks will show the source product description below to users (i.e. in a list of inputs instead of HDMI 1, HDMI 2, etc.).
    // If you care about this, change it below.
    parameter [8*8-1:0] VENDOR_NAME = 64'h556e6b6e6f776e00, // "Unknown" + nulls
    parameter [8*16-1:0] PRODUCT_DESCRIPTION = 128'h46504741000000000000000000000000, // "FPGA" + nulls
    parameter [7:0] SOURCE_DEVICE_INFORMATION = 8'h08, // See README.md or CTA-861-G for the list of valid codes

    // Starting screen coordinate when module comes out of reset.
    //
    // Setting these to something other than (0, 0) is useful when positioning
    // an external video signal within a larger overall frame (e.g.
    // letterboxing an input video signal). This allows you to synchronize the
    // negative edge of reset directly to the start of the external signal
    // instead of to some number of clock cycles before.
    //
    // You probably don't need to change these parameters if you are
    // generating a signal from scratch instead of processing an
    // external signal.
    parameter [BIT_WIDTH-1:0] START_X = 0,
    parameter [BIT_HEIGHT-1:0] START_Y = 0,

    parameter [BIT_WIDTH-1:0] FRAME_WIDTH = 859,
    parameter [BIT_WIDTH-1:0] FRAME_HEIGHT = 523,

    parameter [BIT_HEIGHT-1:0] SCREEN_WIDTH = 720,
    parameter [BIT_HEIGHT-1:0] SCREEN_HEIGHT = 480,

    parameter [BIT_WIDTH-1:0] HSYNC_PULSE_START = 16,
    parameter [BIT_WIDTH-1:0] HSYNC_PULSE_SIZE = 62,

    parameter [BIT_HEIGHT-1:0] VSYNC_PULSE_START = 9,
    parameter [BIT_HEIGHT-1:0] VSYNC_PULSE_SIZE = 6,

    parameter INVERT = 1
)
(
    input clk_pixel,
    // synchronous reset back to 0,0
    input reset,
    input [23:0] rgb,
    input [AUDIO_BIT_WIDTH-1:0] audio_sample_word_0,
    input [AUDIO_BIT_WIDTH-1:0] audio_sample_word_1,
    output audio_sample_en,

    output [9:0] tmds_0,
    output [9:0] tmds_1,
    output [9:0] tmds_2,

    // All outputs below this line stay inside the FPGA
    // They are used (by you) to pick the color each pixel should have
    // i.e. always @(posedge pixel_clk) rgb <= {8'd0, 8'(cx), 8'(cy)};
    output reg [BIT_WIDTH-1:0] cx,
    output reg [BIT_HEIGHT-1:0] cy
);

reg hsync;
reg vsync;

always @(*) begin
    hsync = INVERT ^ (cx >= SCREEN_WIDTH + HSYNC_PULSE_START && cx < SCREEN_WIDTH + HSYNC_PULSE_START + HSYNC_PULSE_SIZE);
    // vsync pulses should begin and end at the start of hsync, so special
    // handling is required for the lines on which vsync starts and ends
    if (cy == SCREEN_HEIGHT + VSYNC_PULSE_START - 1)
        vsync = INVERT ^ (cx >= SCREEN_WIDTH + HSYNC_PULSE_START);
    else if (cy == SCREEN_HEIGHT + VSYNC_PULSE_START + VSYNC_PULSE_SIZE - 1)
        vsync = INVERT ^ (cx < SCREEN_WIDTH + HSYNC_PULSE_START);
    else
        vsync = INVERT ^ (cy >= SCREEN_HEIGHT + VSYNC_PULSE_START && cy < SCREEN_HEIGHT + VSYNC_PULSE_START + VSYNC_PULSE_SIZE);
end

localparam integer VIDEO_RATE = (VIDEO_ID_CODE == 1 ? 25200000
    : VIDEO_ID_CODE == 2 || VIDEO_ID_CODE == 3 ? 27027000
    : VIDEO_ID_CODE == 4 ? 74250000
    : VIDEO_ID_CODE == 16 ? 14850000
    : VIDEO_ID_CODE == 17 || VIDEO_ID_CODE == 18 ? 27000000
    : VIDEO_ID_CODE == 19 ? 74250000
    : VIDEO_ID_CODE == 34 ? 74250000
    : VIDEO_ID_CODE == 95 || VIDEO_ID_CODE == 105 || VIDEO_ID_CODE == 97 || VIDEO_ID_CODE == 107 ? 594000000
    : 0);

// Initialize cx and cy
initial begin
    cx = START_X;
    cy = START_Y;
end

// Wrap-around pixel position counters indicating the pixel to be generated by the user in THIS clock and sent out in the NEXT clock.
always @(posedge clk_pixel)
begin
    if (reset)
    begin
        cx <= START_X;
        cy <= START_Y;
    end
    else
    begin
        cx <= cx == FRAME_WIDTH-1 ? 0 : cx + 1;
        cy <= cx == FRAME_WIDTH-1 ? cy == FRAME_HEIGHT-1 ? 0 : cy + 1 : cy;
    end
end

// See Section 5.2
reg video_data_period;
always @(posedge clk_pixel)
begin
    if (reset)
        video_data_period <= 0;
    else
        video_data_period <= cx < SCREEN_WIDTH && cy < SCREEN_HEIGHT;
end

reg [2:0] mode;
reg [23:0] video_data;
reg [5:0] control_data;
reg [11:0] data_island_data;

generate
    if (!DVI_OUTPUT)
    begin: true_hdmi_output
        reg video_guard;
        reg video_preamble;
        always @(posedge clk_pixel)
        begin
            if (reset)
            begin
                video_guard <= 0;
                video_preamble <= 0;
            end
            else
            begin
                video_guard <= (cx >= FRAME_WIDTH - 2) && cx < FRAME_WIDTH && (cy == FRAME_HEIGHT - 1 || cy < SCREEN_HEIGHT - 1 /* no VG at end of last line */);
                video_preamble <= (cx >= FRAME_WIDTH - 10) && (cx < FRAME_WIDTH - 2) && (cy == FRAME_HEIGHT - 1 || cy < SCREEN_HEIGHT - 1 /* no VP at end of last line */);
            end
        end

        // See Section 5.2.3.1
        wire [31:0] max_num_packets_alongside;
        wire [4:0] num_packets_alongside;

        assign max_num_packets_alongside = (FRAME_WIDTH - SCREEN_WIDTH  /* VD period */ - 2 /* V guard */ - 8 /* V preamble */ - 4 /* Min V control period */ - 2 /* DI trailing guard */ - 2 /* DI leading guard */ - 8 /* DI premable */ - 4 /* Min DI control period */) / 32;
        assign num_packets_alongside = (max_num_packets_alongside > 18) ? 5'd18 : max_num_packets_alongside[4:0];

        wire data_island_period_instantaneous;
        assign data_island_period_instantaneous = num_packets_alongside > 0 && cx >= SCREEN_WIDTH + 14 && cx < SCREEN_WIDTH + 14 + num_packets_alongside * 32;
        wire packet_enable;
        assign packet_enable = data_island_period_instantaneous && ((cx + SCREEN_WIDTH + 18) & 5'h1f) == 5'd0;

        reg data_island_guard;
        reg data_island_preamble;
        reg data_island_period;
        always @(posedge clk_pixel)
        begin
            if (reset)
            begin
                data_island_guard <= 0;
                data_island_preamble <= 0;
                data_island_period <= 0;
            end
            else
            begin
                data_island_guard <= num_packets_alongside > 0 && (
                    (cx >= SCREEN_WIDTH + 12 && cx < SCREEN_WIDTH + 14) /* leading guard */ ||
                    (cx >= SCREEN_WIDTH + 14 + num_packets_alongside * 32 && cx < SCREEN_WIDTH + 14 + num_packets_alongside * 32 + 2) /* trailing guard */
                );
                data_island_preamble <= num_packets_alongside > 0 && cx >= SCREEN_WIDTH + 4 && cx < SCREEN_WIDTH + 12;
                data_island_period <= data_island_period_instantaneous;
            end
        end

        // See Section 5.2.3.4
        wire [23:0] header;
        wire [55:0] sub_0, sub_1, sub_2, sub_3;
        wire video_field_end;
        assign video_field_end = cx == SCREEN_WIDTH - 1 && cy == SCREEN_HEIGHT - 1;
        wire [4:0] packet_pixel_counter;

        packet_picker #(
            .VIDEO_ID_CODE(VIDEO_ID_CODE),
            .IT_CONTENT(IT_CONTENT),
            .AUDIO_RATE(AUDIO_RATE),
            .AUDIO_BIT_WIDTH(AUDIO_BIT_WIDTH),
            .VENDOR_NAME(VENDOR_NAME),
            .PRODUCT_DESCRIPTION(PRODUCT_DESCRIPTION),
            .SOURCE_DEVICE_INFORMATION(SOURCE_DEVICE_INFORMATION)
        ) packet_picker_inst (
            .clk_pixel(clk_pixel),
            .audio_sample_en(audio_sample_en),
            .reset(reset),
            .video_field_end(video_field_end),
            .packet_enable(packet_enable),
            .packet_pixel_counter(packet_pixel_counter),
            .audio_sample_word_0(audio_sample_word_0),
            .audio_sample_word_1(audio_sample_word_1),
            .header(header),
            .sub_0(sub_0),
            .sub_1(sub_1),
            .sub_2(sub_2),
            .sub_3(sub_3)
        );

        wire [8:0] packet_data;
        packet_assembler packet_assembler_inst (
            .clk_pixel(clk_pixel),
            .reset(reset),
            .data_island_period(data_island_period),
            .header(header),
            .sub_0(sub_0),
            .sub_1(sub_1),
            .sub_2(sub_2),
            .sub_3(sub_3),
            .packet_data(packet_data),
            .counter(packet_pixel_counter)
        );

        reg data_island_first;

        always @(posedge clk_pixel)
        begin
            if (reset)
            begin
                mode <= 3'd0;
                video_data <= 24'd0;
                control_data <= 6'd0;
                data_island_data <= 12'd0;
                data_island_first <= 0;
            end
            else
            begin
                mode <= data_island_guard ? 3'd4 : data_island_period ? 3'd3 : video_guard ? 3'd2 : video_data_period ? 3'd1 : 3'd0;
                video_data <= rgb;
                control_data <= {{1'b0, data_island_preamble}, {1'b0, video_preamble || data_island_preamble}, {vsync, hsync}}; // ctrl3, ctrl2, ctrl1, ctrl0, vsync, hsync
                data_island_data[11:4] <= packet_data[8:1];
                data_island_data[3] <= !data_island_first;
                data_island_data[2] <= packet_data[0];
                data_island_data[1:0] <= {vsync, hsync};

                if (data_island_guard)
                    data_island_first <= 1;
                if (data_island_period)
                    data_island_first <= 0;
            end
        end

        localparam integer AUDIO_CLOCK_COUNTER_WIDTH = $clog2(VIDEO_RATE + AUDIO_RATE + 1);

        reg [AUDIO_CLOCK_COUNTER_WIDTH-1:0] audio_clock_counter;

        assign audio_sample_en = audio_clock_counter >= VIDEO_RATE;

        always @(posedge clk_pixel) begin
            if (reset) begin
                audio_clock_counter <= 0;
            end else begin
                audio_clock_counter <= audio_clock_counter + AUDIO_RATE;

                if (audio_sample_en)
                    audio_clock_counter <= audio_clock_counter + AUDIO_RATE - VIDEO_RATE;
            end
        end
    end
    else // DVI_OUTPUT = 1
    begin: dvi_output
        always @(posedge clk_pixel)
        begin
            if (reset)
            begin
                mode <= 3'd0;
                video_data <= 24'd0;
                control_data <= 6'd0;
            end
            else
            begin
                mode <= video_data_period ? 3'd1 : 3'd0;
                video_data <= rgb;
                control_data <= {4'b0000, {vsync, hsync}}; // ctrl3, ctrl2, ctrl1, ctrl0, vsync, hsync
            end
        end
    end
endgenerate

// TMDS code production.
tmds_channel #(.CN(0)) tmds_channel_0 (
    .clk_pixel(clk_pixel),
    .video_data(video_data[7:0]),
    .data_island_data(data_island_data[3:0]),
    .control_data(control_data[1:0]),
    .mode(mode),
    .tmds(tmds_0)
);

tmds_channel #(.CN(1)) tmds_channel_1 (
    .clk_pixel(clk_pixel),
    .video_data(video_data[15:8]),
    .data_island_data(data_island_data[7:4]),
    .control_data(control_data[3:2]),
    .mode(mode),
    .tmds(tmds_1)
);

tmds_channel #(.CN(2)) tmds_channel_2 (
    .clk_pixel(clk_pixel),
    .video_data(video_data[23:16]),
    .data_island_data(data_island_data[11:8]),
    .control_data(control_data[5:4]),
    .mode(mode),
    .tmds(tmds_2)
);

endmodule
