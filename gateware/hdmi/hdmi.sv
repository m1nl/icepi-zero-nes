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
    parameter BIT_HEIGHT = VIDEO_ID_CODE == 16 ? 11: 10,

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
    parameter START_X = 0,
    parameter START_Y = 0
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
    output reg [BIT_HEIGHT-1:0] cy,

    // The screen is at the upper left corner of the frame.
    // 0,0 = 0,0 in video
    // the frame includes extra space for sending auxiliary data
    output [BIT_WIDTH-1:0] frame_width,
    output [BIT_HEIGHT-1:0] frame_height,
    output [BIT_WIDTH-1:0] screen_width,
    output [BIT_HEIGHT-1:0] screen_height,

    // Indicates if we're in the blanking period
    output reg hblank,
    output reg vblank
);

reg hsync;
reg vsync;

wire [BIT_WIDTH-1:0] hsync_pulse_start, hsync_pulse_size;
wire [BIT_HEIGHT-1:0] vsync_pulse_start, vsync_pulse_size;
wire invert;

// See CEA-861-D for more specifics formats described below.
generate
    case (VIDEO_ID_CODE)
        1:
        begin
            assign frame_width = 800;
            assign frame_height = 525;
            assign screen_width = 640;
            assign screen_height = 480;
            assign hsync_pulse_start = 16;
            assign hsync_pulse_size = 96;
            assign vsync_pulse_start = 10;
            assign vsync_pulse_size = 2;
            assign invert = 1;
            end
        2, 3:
        begin
            assign frame_width = 857;
            assign frame_height = 525;
            assign screen_width = 720;
            assign screen_height = 480;
            assign hsync_pulse_start = 16;
            assign hsync_pulse_size = 62;
            assign vsync_pulse_start = 9;
            assign vsync_pulse_size = 6;
            assign invert = 1;
            end
        4:
        begin
            assign frame_width = 1650;
            assign frame_height = 750;
            assign screen_width = 1280;
            assign screen_height = 720;
            assign hsync_pulse_start = 110;
            assign hsync_pulse_size = 40;
            assign vsync_pulse_start = 5;
            assign vsync_pulse_size = 5;
            assign invert = 0;
        end
        16, 34:
        begin
            assign frame_width = 2200;
            assign frame_height = 1125;
            assign screen_width = 1920;
            assign screen_height = 1080;
            assign hsync_pulse_start = 88;
            assign hsync_pulse_size = 44;
            assign vsync_pulse_start = 4;
            assign vsync_pulse_size = 5;
            assign invert = 0;
        end
        17, 18:
        begin
            assign frame_width = 864;
            assign frame_height = 625;
            assign screen_width = 720;
            assign screen_height = 576;
            assign hsync_pulse_start = 12;
            assign hsync_pulse_size = 64;
            assign vsync_pulse_start = 5;
            assign vsync_pulse_size = 5;
            assign invert = 1;
        end
        19:
        begin
            assign frame_width = 1980;
            assign frame_height = 750;
            assign screen_width = 1280;
            assign screen_height = 720;
            assign hsync_pulse_start = 440;
            assign hsync_pulse_size = 40;
            assign vsync_pulse_start = 5;
            assign vsync_pulse_size = 5;
            assign invert = 0;
        end
        95, 105, 97, 107:
        begin
            assign frame_width = 4400;
            assign frame_height = 2250;
            assign screen_width = 3840;
            assign screen_height = 2160;
            assign hsync_pulse_start = 176;
            assign hsync_pulse_size = 88;
            assign vsync_pulse_start = 8;
            assign vsync_pulse_size = 10;
            assign invert = 0;
        end
    endcase
endgenerate

always @(*) begin
    hsync = invert ^ (cx >= screen_width + hsync_pulse_start && cx < screen_width + hsync_pulse_start + hsync_pulse_size);
    // vsync pulses should begin and end at the start of hsync, so special
    // handling is required for the lines on which vsync starts and ends
    if (cy == screen_height + vsync_pulse_start - 1)
        vsync = invert ^ (cx >= screen_width + hsync_pulse_start);
    else if (cy == screen_height + vsync_pulse_start + vsync_pulse_size - 1)
        vsync = invert ^ (cx < screen_width + hsync_pulse_start);
    else
        vsync = invert ^ (cy >= screen_height + vsync_pulse_start && cy < screen_height + vsync_pulse_start + vsync_pulse_size);

    hblank = cx >= screen_width;
    vblank = cy >= screen_height;
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
        cx <= cx == frame_width-1'b1 ? 0 : cx + 1'b1;
        cy <= cx == frame_width-1'b1 ? cy == frame_height-1'b1 ? 0 : cy + 1'b1 : cy;
    end
end

// See Section 5.2
reg video_data_period;
always @(posedge clk_pixel)
begin
    if (reset)
        video_data_period <= 0;
    else
        video_data_period <= cx < screen_width && cy < screen_height;
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
                video_guard <= (cx >= frame_width - 2) && cx < frame_width && (cy == frame_height - 1 || cy < screen_height - 1 /* no VG at end of last line */);
                video_preamble <= (cx >= frame_width - 10) && (cx < frame_width - 2) && (cy == frame_height - 1 || cy < screen_height - 1 /* no VP at end of last line */);
            end
        end

        // See Section 5.2.3.1
        wire [31:0] max_num_packets_alongside;
        wire [4:0] num_packets_alongside;

        assign max_num_packets_alongside = (frame_width - screen_width  /* VD period */ - 2 /* V guard */ - 8 /* V preamble */ - 4 /* Min V control period */ - 2 /* DI trailing guard */ - 2 /* DI leading guard */ - 8 /* DI premable */ - 4 /* Min DI control period */) / 32;
        assign num_packets_alongside = (max_num_packets_alongside > 18) ? 5'd18 : max_num_packets_alongside[4:0];

        wire data_island_period_instantaneous;
        assign data_island_period_instantaneous = num_packets_alongside > 0 && cx >= screen_width + 14 && cx < screen_width + 14 + num_packets_alongside * 32;
        wire packet_enable;
        assign packet_enable = data_island_period_instantaneous && ((cx + screen_width + 18) & 5'h1f) == 5'd0;

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
                    (cx >= screen_width + 12 && cx < screen_width + 14) /* leading guard */ ||
                    (cx >= screen_width + 14 + num_packets_alongside * 32 && cx < screen_width + 14 + num_packets_alongside * 32 + 2) /* trailing guard */
                );
                data_island_preamble <= num_packets_alongside > 0 && cx >= screen_width + 4 && cx < screen_width + 12;
                data_island_period <= data_island_period_instantaneous;
            end
        end

        // See Section 5.2.3.4
        wire [23:0] header;
        wire [55:0] sub_0, sub_1, sub_2, sub_3;
        wire video_field_end;
        assign video_field_end = cx == screen_width - 1'b1 && cy == screen_height - 1'b1;
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
