#!/usr/bin/env python3
"""Generates every pixel-art PNG used by Pixel Mod Fighter into ../assets.

Run:  python3 tools/make_sprites.py      (needs Pillow)
All art is drawn from rectangles and small hand-placed pixels with a fixed
palette, so the sprites keep a clean, hand-made look.
"""
import os
import random

from PIL import Image

OUT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets"))
os.makedirs(OUT, exist_ok=True)


def C(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


INK = C("#1a1424")
SKIN = C("#f0b98a")
SKIN_D = C("#c98a5f")
RED = C("#d9463e")
RED_D = C("#8f2a2e")
BLUE = C("#3b5dc9")
WHITE = C("#f4f1e8")
GREY = C("#8b93a7")
GREY_D = C("#4a5068")
GREY_L = C("#c9cfdd")
YEL = C("#ffd84a")
GRN = C("#5fcf6b")
GRN_D = C("#2f8f4a")
GRN_EYE = C("#7bff6b")
BRN = C("#8a5a3b")
BRN_D = C("#5a3826")
PINK = C("#ff7ad9")
PINK_D = C("#c04a9d")
CAT = C("#e8944a")
CAT_D = C("#b3622d")
CREAM = C("#f6d9b0")
CYAN = C("#5ad7ff")
WOOD = C("#b07b4a")
WOOD_L = C("#d6a066")
CLOUD = C("#aab4e0")


def new(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def px(img, x, y, c):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), c)


def rect(img, x, y, w, h, c):
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            px(img, xx, yy, c)


def outline(img, x0, y0, w, h, color=INK):
    """Adds a 1px outline around the opaque pixels inside one frame box."""
    src = img.copy()
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            if src.getpixel((x, y))[3] != 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if x0 <= nx < x0 + w and y0 <= ny < y0 + h and src.getpixel((nx, ny))[3] != 0:
                    img.putpixel((x, y), color)
                    break


def save(img, name):
    img.save(os.path.join(OUT, name + ".png"))
    print("wrote", name + ".png", img.size)


# ------------------------------------------------------------------ player
# Frame order: idle0, idle1, run0, run1, run2, run3, jump, fall, hurt
def player_frame(img, ox, bob, legs, hurt=False):
    rect(img, ox + 4, 8 + bob, 1, 3, SKIN_D)           # back arm
    rect(img, ox + 5, 7 + bob, 6, 4, WHITE)            # shirt
    rect(img, ox + 5, 10 + bob, 6, 1, RED_D)           # belt
    for (lx, top, h) in legs:
        rect(img, ox + lx, top, 2, h, BLUE)
        rect(img, ox + lx, top + h, 2, 1, BRN)         # boot
    rect(img, ox + 5, 2 + bob, 6, 5, SKIN)             # head
    rect(img, ox + 5, 2 + bob, 6, 1, BRN_D)            # hair
    rect(img, ox + 5, 3 + bob, 6, 1, RED)              # headband
    px(img, ox + 4, 4 + bob, RED)
    px(img, ox + 3, 5 + bob, RED)                      # headband tail
    if hurt:
        px(img, ox + 8, 5 + bob, INK)
        px(img, ox + 9, 5 + bob, INK)
        px(img, ox + 9, 6 + bob, RED_D)                # open mouth
    else:
        px(img, ox + 9, 5 + bob, INK)
    rect(img, ox + 10, 8 + bob, 2, 2, SKIN)            # front arm
    outline(img, ox, 0, 16, 16)


def make_player():
    img = new(16 * 9, 16)
    idle = [(5, 11, 3), (9, 11, 3)]
    frames = [
        (0, idle, False),
        (1, idle, False),
        (0, [(4, 11, 2), (10, 11, 3)], False),
        (1, [(6, 11, 2), (8, 11, 3)], False),
        (0, [(4, 11, 3), (10, 11, 2)], False),
        (1, [(6, 11, 3), (8, 11, 2)], False),
        (0, [(5, 11, 2), (9, 11, 2)], False),
        (0, [(4, 11, 3), (10, 11, 3)], False),
        (1, idle, True),
    ]
    for i, (bob, legs, hurt) in enumerate(frames):
        player_frame(img, i * 16, bob, legs, hurt)
    save(img, "player")


# ------------------------------------------------------------------- slime
TALL = [(4, 6, 9), (5, 5, 10), (6, 4, 11), (7, 3, 12), (8, 3, 12),
        (9, 3, 12), (10, 3, 12), (11, 3, 12), (12, 3, 12), (13, 3, 12)]
SQUISH = [(7, 5, 10), (8, 4, 11), (9, 3, 12), (10, 2, 13), (11, 2, 13),
          (12, 2, 13), (13, 2, 13)]


def slime_frame(img, ox, squish, hurt):
    body = WHITE if hurt else GRN
    shade = GREY_L if hurt else GRN_D
    rows = SQUISH if squish else TALL
    for (y, x0, x1) in rows:
        rect(img, ox + x0, y, x1 - x0 + 1, 1, body)
    for (y, x0, x1) in rows[-2:]:
        rect(img, ox + x0, y, x1 - x0 + 1, 1, shade)
    ey = 9 if squish else 8
    eye = GREY if hurt else WHITE
    rect(img, ox + 5, ey, 2, 2, eye)
    rect(img, ox + 9, ey, 2, 2, eye)
    px(img, ox + 6, ey + 1, INK)
    px(img, ox + 10, ey + 1, INK)
    for bx in (5, 6, 9, 10):
        px(img, ox + bx, ey - 1, INK)                  # angry brows
    outline(img, ox, 0, 16, 16)


def make_slime():
    img = new(48, 16)
    slime_frame(img, 0, False, False)
    slime_frame(img, 16, True, False)
    slime_frame(img, 32, False, True)
    save(img, "slime")


# --------------------------------------------------------------------- cat
def cat_frame(img, ox, blink):
    rect(img, ox + 12, 11, 2, 3, CAT)                  # tail
    px(img, ox + 13, 10, CAT)
    rect(img, ox + 4, 9, 8, 5, CAT)                    # body
    rect(img, ox + 6, 10, 4, 4, CREAM)                 # belly
    rect(img, ox + 4, 3, 8, 6, CAT)                    # head
    rect(img, ox + 4, 1, 2, 2, CAT)                    # ears
    rect(img, ox + 10, 1, 2, 2, CAT)
    px(img, ox + 5, 2, PINK)
    px(img, ox + 10, 2, PINK)
    px(img, ox + 7, 3, CAT_D)                          # forehead stripes
    px(img, ox + 8, 3, CAT_D)
    if blink:
        rect(img, ox + 5, 6, 2, 1, INK)
        rect(img, ox + 9, 6, 2, 1, INK)
    else:
        rect(img, ox + 6, 5, 1, 2, GRN_EYE)
        rect(img, ox + 9, 5, 1, 2, GRN_EYE)
    px(img, ox + 7, 7, PINK)                           # nose
    px(img, ox + 8, 7, PINK)
    rect(img, ox + 5, 13, 2, 1, CREAM)                 # paws
    rect(img, ox + 9, 13, 2, 1, CREAM)
    outline(img, ox, 0, 16, 16)


def make_cat():
    img = new(32, 16)
    cat_frame(img, 0, False)
    cat_frame(img, 16, True)
    save(img, "cat")


# ----------------------------------------------------------- weapon icons
def make_sword():
    img = new(16, 16)
    rect(img, 0, 7, 1, 2, YEL)
    rect(img, 1, 7, 3, 2, BRN)
    rect(img, 4, 5, 1, 6, YEL)
    rect(img, 5, 7, 9, 2, GREY_L)
    rect(img, 5, 8, 9, 1, GREY)
    px(img, 14, 7, GREY_L)
    outline(img, 0, 0, 16, 16)
    save(img, "wp_sword")


def make_pistol():
    img = new(16, 16)
    rect(img, 3, 8, 3, 5, BRN)
    rect(img, 2, 6, 10, 3, GREY_D)
    rect(img, 2, 6, 10, 1, GREY)
    rect(img, 12, 6, 3, 2, GREY)
    outline(img, 0, 0, 16, 16)
    save(img, "wp_pistol")


def make_shotgun():
    img = new(16, 16)
    rect(img, 0, 7, 4, 3, BRN)
    rect(img, 4, 6, 12, 3, GREY_D)
    rect(img, 6, 6, 10, 1, GREY_L)
    rect(img, 8, 9, 3, 2, BRN_D)
    outline(img, 0, 0, 16, 16)
    save(img, "wp_shotgun")


def make_pewpew():
    img = new(16, 16)
    rect(img, 2, 6, 10, 4, PINK)
    rect(img, 2, 9, 10, 1, PINK_D)
    rect(img, 4, 4, 2, 2, PINK)                        # cat ears
    rect(img, 8, 4, 2, 2, PINK)
    rect(img, 12, 7, 3, 2, WHITE)
    px(img, 15, 7, CYAN)
    px(img, 15, 8, CYAN)
    rect(img, 4, 10, 2, 3, PINK_D)
    px(img, 6, 7, INK)                                 # eyes
    px(img, 9, 7, INK)
    outline(img, 0, 0, 16, 16)
    save(img, "wp_pewpew")


# ------------------------------------------------------------------- tiles
def make_tiles():
    rng = random.Random(7)
    grass = new(16, 16)
    rect(grass, 0, 0, 16, 16, BRN)
    for _ in range(14):
        px(grass, rng.randrange(16), rng.randrange(5, 16), BRN_D)
    rect(grass, 0, 0, 16, 4, GRN)
    rect(grass, 0, 3, 16, 1, GRN_D)
    for x in range(16):
        if rng.random() < 0.5:
            px(grass, x, 4, GRN_D)
        if rng.random() < 0.35:
            px(grass, x, 1, GRN_D)
    save(grass, "tile_grass")

    dirt = new(16, 16)
    rect(dirt, 0, 0, 16, 16, BRN)
    for _ in range(22):
        px(dirt, rng.randrange(16), rng.randrange(16), BRN_D)
    for _ in range(5):
        px(dirt, rng.randrange(16), rng.randrange(16), SKIN_D)
    save(dirt, "tile_dirt")

    plank = new(16, 8)
    rect(plank, 0, 0, 16, 8, WOOD)
    rect(plank, 0, 0, 16, 2, WOOD_L)
    rect(plank, 0, 7, 16, 1, BRN_D)
    px(plank, 1, 4, GREY_D)
    px(plank, 14, 4, GREY_D)
    for y in range(2, 7):
        px(plank, 7, y, BRN_D)
    save(plank, "tile_plank")

    cloud = new(32, 12)
    rect(cloud, 6, 6, 20, 5, CLOUD)
    rect(cloud, 10, 3, 12, 4, CLOUD)
    rect(cloud, 3, 8, 26, 3, CLOUD)
    save(cloud, "cloud")


if __name__ == "__main__":
    make_player()
    make_slime()
    make_cat()
    make_sword()
    make_pistol()
    make_shotgun()
    make_pewpew()
    make_tiles()
