import random

import numpy as np

palette_lut = np.asarray(
    [
        (0x58, 0x58, 0x58),
        (0x00, 0x23, 0x8C),
        (0x00, 0x13, 0x9B),
        (0x2D, 0x05, 0x85),
        (0x5D, 0x00, 0x52),
        (0x7A, 0x00, 0x17),
        (0x7A, 0x08, 0x00),
        (0x5F, 0x18, 0x00),
        (0x35, 0x2A, 0x00),
        (0x09, 0x39, 0x00),
        (0x00, 0x3F, 0x00),
        (0x00, 0x3C, 0x22),
        (0x00, 0x32, 0x5D),
        (0x00, 0x00, 0x00),
        (0x00, 0x00, 0x00),
        (0x00, 0x00, 0x00),
        (0xA1, 0xA1, 0xA1),
        (0x00, 0x53, 0xEE),
        (0x15, 0x3C, 0xFE),
        (0x60, 0x28, 0xE4),
        (0xA9, 0x1D, 0x98),
        (0xD4, 0x1E, 0x41),
        (0xD2, 0x2C, 0x00),
        (0xAA, 0x44, 0x00),
        (0x6C, 0x5E, 0x00),
        (0x2D, 0x73, 0x00),
        (0x00, 0x7D, 0x06),
        (0x00, 0x78, 0x52),
        (0x00, 0x69, 0xA9),
        (0x00, 0x00, 0x00),
        (0x00, 0x00, 0x00),
        (0x00, 0x00, 0x00),
        (0xFF, 0xFF, 0xFF),
        (0x1F, 0xA5, 0xFE),
        (0x5E, 0x89, 0xFE),
        (0xB5, 0x72, 0xFE),
        (0xFE, 0x65, 0xF6),
        (0xFE, 0x67, 0x90),
        (0xFE, 0x77, 0x3C),
        (0xFE, 0x93, 0x08),
        (0xC4, 0xB2, 0x00),
        (0x79, 0xCA, 0x10),
        (0x3A, 0xD5, 0x4A),
        (0x11, 0xD1, 0xA4),
        (0x06, 0xBF, 0xFE),
        (0x42, 0x42, 0x42),
        (0x00, 0x00, 0x00),
        (0x00, 0x00, 0x00),
        (0xFF, 0xFF, 0xFF),
        (0xA0, 0xD9, 0xFE),
        (0xBD, 0xCC, 0xFE),
        (0xE1, 0xC2, 0xFE),
        (0xFE, 0xBC, 0xFB),
        (0xFE, 0xBD, 0xD0),
        (0xFE, 0xC5, 0xA9),
        (0xFE, 0xD1, 0x8E),
        (0xE9, 0xDE, 0x86),
        (0xC7, 0xE9, 0x92),
        (0xA8, 0xEE, 0xB0),
        (0x95, 0xEC, 0xD9),
        (0x91, 0xE4, 0xFE),
        (0xAC, 0xAC, 0xAC),
        (0x00, 0x00, 0x00),
        (0x00, 0x00, 0x00),
    ]
)


def srgb_to_linear(c):
    c = np.asarray(c, dtype=np.float64)
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def luma_from_rgb(rgb):
    rgb = np.asarray(rgb, dtype=np.float64)

    if rgb.max() > 1.0:
        rgb = rgb / 255.0

    # rgb = srgb_to_linear(rgb)

    # Rec.709 / sRGB luminance (linear)
    y = 0.2126 * rgb[..., 0] + 0.7152 * rgb[..., 1] + 0.0722 * rgb[..., 2]
    return y


def quantize(y, thresholds):
    return np.searchsorted(thresholds, y)


def darken(c, step):
    return c - (c >> (4 - step))


def verilog_lut_init(array, reg_name="palette_luma", bit_width=2, cols=2):
    N = len(array)
    lines = f"reg [{bit_width-1}:0] {reg_name} [0:{N-1}];\n\ninitial begin\n"
    col = 0

    for i, val in enumerate(array):
        if col == 0:
            lines += "  "

        lines += f"{reg_name}[{i}] = {bit_width}'d{val};"
        lines += "\n" if col == (cols - 1) else " "
        col = (col + 1) % 2

    if col != 0:
        lines += "\n"

    lines += "end\n"
    return lines


if __name__ == "__main__":
    luma = luma_from_rgb(palette_lut)
    lowest_error = -1
    result = None

    for iteration in range(0, 1000):
        q1 = random.randrange(1, 1000)
        q2 = random.randrange(q1, 1000)
        q3 = random.randrange(q2, 1000)

        q1 = float(q1) / 1000
        q2 = float(q2) / 1000
        q3 = float(q3) / 1000

        error = 0

        luma_quant = quantize(luma, [q1, q2, q3])

        for i in range(0, len(palette_lut)):
            for j in range(0, len(palette_lut)):
                a = palette_lut[i]
                b = palette_lut[j]

                luma_a = luma[i]
                luma_b = luma[j]
                diff_1 = luma_a - luma_b

                luma_a_q = luma_quant[i]
                luma_b_q = luma_quant[j]
                step = luma_a_q - luma_b_q

                if step > 0:
                    a = darken(a, step)
                elif step < 0:
                    b = darken(b, -step)

                luma_a = luma_from_rgb(a)
                luma_b = luma_from_rgb(b)
                diff_2 = luma_a - luma_b

                error += (diff_1 * 0.75 - diff_2) ** 2

        if (error < lowest_error) or lowest_error == -1:
            lowest_error = error
            result = (q1, q2, q3)

            print(lowest_error)
            print(result)

        print("iter = ", iteration)

    print(lowest_error)
    print(result)

    luma_quant = quantize(luma, result)

    print(luma)
    print(luma_quant)

    print(verilog_lut_init(luma_quant))
