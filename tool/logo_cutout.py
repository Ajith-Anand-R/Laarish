"""Convert the Laarish wordmark logo from black background to clean white background.

Output: assets/images/logo.png and assets/images/logo.jpeg
"""
from collections import deque
from PIL import Image, ImageFilter
import os

SRC = "Logo.jpeg"
DST_PNG = "assets/images/logo.png"
DST_JPG = "assets/images/logo.jpeg"
LUM_BG = 55

def lum(px):
    return 0.299 * px[0] + 0.587 * px[1] + 0.114 * px[2]

def main():
    if not os.path.exists(SRC):
        src_fallback = "assets/images/logo.jpeg"
        if os.path.exists(src_fallback):
            im = Image.open(src_fallback).convert("RGB")
        else:
            print("Logo source image not found.")
            return
    else:
        im = Image.open(SRC).convert("RGB")

    w, h = im.size
    px = im.load()
    bg = bytearray(w * h)
    q = deque()

    def consider(x, y):
        if 0 <= x < w and 0 <= y < h and not bg[y * w + x] and lum(px[x, y]) < LUM_BG:
            bg[y * w + x] = 1
            q.append((x, y))

    for x in range(w):
        consider(x, 0); consider(x, h - 1)
    for y in range(h):
        consider(0, y); consider(w - 1, y)
    while q:
        x, y = q.popleft()
        consider(x + 1, y); consider(x - 1, y); consider(x, y + 1); consider(x, y - 1)

    alpha = Image.new("L", (w, h), 255)
    ap = alpha.load()
    for y in range(h):
        for x in range(w):
            if bg[y * w + x]:
                ap[x, y] = 0

    blurred_alpha = alpha.filter(ImageFilter.GaussianBlur(0.8))
    balpha_px = blurred_alpha.load()

    final_im = Image.new("RGB", (w, h), (255, 255, 255))
    final_px = final_im.load()
    for y in range(h):
        for x in range(w):
            a = balpha_px[x, y] / 255.0
            r = int(px[x, y][0] * a + 255 * (1 - a))
            g = int(px[x, y][1] * a + 255 * (1 - a))
            b = int(px[x, y][2] * a + 255 * (1 - a))
            final_px[x, y] = (r, g, b)

    min_x, max_x = w, 0
    min_y, max_y = h, 0
    for y in range(h):
        for x in range(w):
            r, g, b = final_px[x, y]
            if r < 248 or g < 248 or b < 248:
                if x < min_x: min_x = x
                if x > max_x: max_x = x
                if y < min_y: min_y = y
                if y > max_y: max_y = y

    pad_x = int((max_x - min_x) * 0.08)
    pad_y = int((max_y - min_y) * 0.15)
    crop_x0 = max(0, min_x - pad_x)
    crop_y0 = max(0, min_y - pad_y)
    crop_x1 = min(w, max_x + pad_x)
    crop_y1 = min(h, max_y + pad_y)

    cropped_im = final_im.crop((crop_x0, crop_y0, crop_x1, crop_y1))
    os.makedirs(os.path.dirname(DST_PNG), exist_ok=True)
    cropped_im.save(DST_PNG, "PNG")
    cropped_im.save(DST_JPG, "JPEG", quality=95)
    print(f"Saved white background logo to {DST_PNG} and {DST_JPG}")

if __name__ == "__main__":
    main()

