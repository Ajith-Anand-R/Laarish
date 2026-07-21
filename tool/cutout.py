"""Knock the pure-black studio background out of the Laarish character art.

Flood-fills the connected near-black region starting from the image border, so
interior blacks (pupils, ink outlines, belt) are preserved — only the backdrop
that touches an edge is removed. Alpha is then feathered 1px to avoid a dark
halo on the cream app background. Input JPEGs -> transparent PNGs.
"""
import sys
from collections import deque
from PIL import Image, ImageFilter

# mascots + people have a plain black backdrop; cards are full posters (kept as jpeg).
CUTOUTS = [
    "tommy_mascot", "chilly_mascot", "methi_mascot", "okki_mascot",
    "rishi_character", "rishi_character_alt", "ayra_character", "all_characters",
    "tool_corky", "tool_diggy", "tool_misty", "tool_cuppy", "tool_growbag", "tool_label",
    "mg_soak", "mg_fill", "mg_poke", "mg_drop", "mg_label", "mg_mist", "mg_pour", "mg_snip", "mg_scatter", "mg_pick", "mg_match", "mg_count",
    "badge_tommy_sprout", "badge_tommy_harvest", "badge_okki_sprout", "badge_okki_harvest", "badge_chilly_sprout", "badge_chilly_harvest", "badge_methi_round1", "badge_methi_round2",
    "badge_first_seed", "badge_thinning_brave", "badge_graduation_day", "badge_big_move", "badge_first_flower", "badge_five_rules",
    "badge_patience_master", "badge_photo_reporter", "badge_curious_mind", "badge_streak_3", "badge_streak_7", "badge_streak_14", "badge_streak_30", "badge_proud_agriculturist",
    "cert_seal", "cert_frame"
]
SRC = "images"
DST = "assets/images"
LUM_BG = 14  # only near-pure black is background; ink outlines (20-60) survive

def lum(px):
    r, g, b = px[0], px[1], px[2]
    return 0.299 * r + 0.587 * g + 0.114 * b

def cutout(name):
    import os
    if os.path.exists(f"{SRC}/{name}.jpeg"):
        im = Image.open(f"{SRC}/{name}.jpeg").convert("RGBA")
    elif os.path.exists(f"{SRC}/{name}.png"):
        im = Image.open(f"{SRC}/{name}.png").convert("RGBA")
    else:
        print(f"Skipping {name}: file not found")
        return
    w, h = im.size
    px = im.load()
    transparent = bytearray(w * h)  # 1 = background
    q = deque()

    def consider(x, y):
        if 0 <= x < w and 0 <= y < h and not transparent[y * w + x] and lum(px[x, y]) < LUM_BG:
            transparent[y * w + x] = 1
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
            if transparent[y * w + x]:
                ap[x, y] = 0
    # feather the cut edge so no hard black fringe remains on cream
    im.putalpha(alpha.filter(ImageFilter.GaussianBlur(0.8)))
    im.save(f"{DST}/{name}.png")
    kept = sum(1 for i in range(w * h) if not transparent[i])
    print(f"{name}.png  {w}x{h}  kept {kept*100//(w*h)}%")

if __name__ == "__main__":
    for n in CUTOUTS:
        cutout(n)
