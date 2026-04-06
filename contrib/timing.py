if __name__ == "__main__":
    master_clock = 21.47727273e6
    hdmi_clock = 27e6

    cycles = 341
    scanlines = 262

    hdmi_width = 858
    hdmi_height = 525

    frame_time = (cycles * scanlines - 0.5) / (master_clock / 4)

    result = None
    min_score = 1

    w1 = 0.5
    w2 = 0.5

    for i in range(-5, 5):
        for j in range(-5, 5):
            for k in range(-200, 200):
                w = hdmi_width + i
                h = hdmi_height + j
                c = round((master_clock + (float(k) / 1000) * 1e6) / 1e6, 3) * 1e6

                h_time_hdmi = (2 * w) / hdmi_clock
                h_time_ppu = cycles / (c / 4)

                if h_time_ppu * 1.0001 >= h_time_hdmi:
                    continue

                frame_time_hdmi = w * h / hdmi_clock
                frame_time_ppu = (cycles * scanlines - 0.5) / (c / 4)

                if frame_time_hdmi * 1.0001 >= frame_time_ppu:
                    continue

                score = (
                    w1 * ((frame_time_hdmi - frame_time) / frame_time) ** 2
                    + w2 * ((c - master_clock) / master_clock) ** 2
                ) ** 0.5

                if score < min_score:
                    min_score = score
                    result = (1 / frame_time_hdmi, score, w, h, c, (frame_time_ppu - frame_time_hdmi) * c)

    print("frame_rate = ", result[0])
    print("score = ", result[1])
    print("hdmi_width = ", result[2])
    print("hdmi_height = ", result[3])
    print("nes_clock = ", result[4])
    print("nes_lost_ticks_per_frame = ", result[5])
