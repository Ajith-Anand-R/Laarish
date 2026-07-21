"""Chroma-aware black-background cutout for the curly-haired characters.

Luminance flood-fill (cutout.py) can't separate dark-brown hair from a black
backdrop — both are dark — so it eats the frizzy curls. Key insight: the
backdrop is NEUTRAL black (R≈G≈B) while hair is warm brown (R>B). So a pixel is
background only if it is BOTH dark AND near-neutral. Dark-but-warm hair survives.

Steps:
  1. flood-fill border-connected (dark AND neutral) pixels -> background,
  2. keep only the LARGEST connected foreground blob (drops stray fragments of
     a neighbouring character caught in the source frame, plus specks),
  3. close the silhouette (fill tunneled gaps), erode 1px + feather (kill halo),
  4. crop to the kept blob's bounding box.

Usage: python tool/hair_cutout.py <name> [V_THRESH] [C_THRESH] [CLOSE] [ERODE]
Reads images/<name>.jpeg -> writes assets/images/<name>.png
"""
import sys
from collections import deque
from PIL import Image, ImageFilter

SRC = "images"
DST = "assets/images"


def cutout(name, v_thresh, c_thresh, close_k, erode_k):
    im = Image.open(f"{SRC}/{name}.jpeg").convert("RGBA")
    w, h = im.size
    px = im.load()
    n = w * h
    bg = bytearray(n)

    def is_darkneutral(x, y):
        r, g, b, _ = px[x, y]
        value = max(r, g, b)
        chroma = value - min(r, g, b)
        return value < v_thresh and chroma < c_thresh

    # 1. flood-fill background from the border.
    q = deque()

    def consider(x, y):
        if 0 <= x < w and 0 <= y < h and not bg[y * w + x] and is_darkneutral(x, y):
            bg[y * w + x] = 1
            q.append((x, y))

    for x in range(w):
        consider(x, 0); consider(x, h - 1)
    for y in range(h):
        consider(0, y); consider(w - 1, y)
    while q:
        x, y = q.popleft()
        consider(x + 1, y); consider(x - 1, y); consider(x, y + 1); consider(x, y - 1)

    # 2. keep only the largest connected foreground component.
    seen = bytearray(n)
    best = []
    for sy in range(h):
        for sx in range(w):
            i0 = sy * w + sx
            if bg[i0] or seen[i0]:
                continue
            comp = []
            dq = deque([(sx, sy)])
            seen[i0] = 1
            while dq:
                x, y = dq.popleft()
                comp.append(y * w + x)
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= nx < w and 0 <= ny < h:
                        j = ny * w + nx
                        if not bg[j] and not seen[j]:
                            seen[j] = 1
                            dq.append((nx, ny))
            if len(comp) > len(best):
                best = comp

    keep = bytearray(n)
    for i in best:
        keep[i] = 1

    alpha = Image.new("L", (w, h), 0)
    ap = alpha.load()
    minx, miny, maxx, maxy = w, h, 0, 0
    for i in best:
        x, y = i % w, i // w
        ap[x, y] = 255
        if x < minx: minx = x
        if y < miny: miny = y
        if x > maxx: maxx = x
        if y > maxy: maxy = y

    # 3. close gaps, erode the halo, feather.
    if close_k > 1:
        alpha = alpha.filter(ImageFilter.MaxFilter(close_k)).filter(ImageFilter.MinFilter(close_k))
    if erode_k > 1:
        alpha = alpha.filter(ImageFilter.MinFilter(erode_k))
    alpha = alpha.filter(ImageFilter.GaussianBlur(0.8))
    im.putalpha(alpha)

    # 4. crop to the blob (with a little padding).
    pad = 8
    box = (max(0, minx - pad), max(0, miny - pad), min(w, maxx + pad), min(h, maxy + pad))
    im = im.crop(box)
    im.save(f"{DST}/{name}.png")
    print(f"{name}.png  kept {len(best) * 100 // n}%  crop {im.size}  (v={v_thresh} c={c_thresh} close={close_k} erode={erode_k})")


if __name__ == "__main__":
    name = sys.argv[1] if len(sys.argv) > 1 else "rishi_character"
    v = int(sys.argv[2]) if len(sys.argv) > 2 else 70
    c = int(sys.argv[3]) if len(sys.argv) > 3 else 14
    close_k = int(sys.argv[4]) if len(sys.argv) > 4 else 5
    erode_k = int(sys.argv[5]) if len(sys.argv) > 5 else 3
    cutout(name, v, c, close_k, erode_k)
