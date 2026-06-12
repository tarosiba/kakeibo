#!/usr/bin/env python3
"""Generate placeholder pixel art sprites for Retro Soccer."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "sprites"


def rgba(value: str) -> tuple[int, int, int, int]:
    value = value.lstrip("#")
    if len(value) == 6:
        r, g, b = int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16)
        return r, g, b, 255
    raise ValueError(value)


TRANSPARENT = (0, 0, 0, 0)
WHITE = rgba("#FFFFFF")
SKIN = rgba("#F5D0A9")
SKIN_SHADOW = rgba("#D4A574")
HAIR = rgba("#4A2C12")
EYE = rgba("#111827")
SHOE = rgba("#1F2937")
SHOE_HI = rgba("#4B5563")
BALL_WHITE = rgba("#F8FAFC")
BALL_DARK = rgba("#111827")
STAR = rgba("#FACC15")
STAR_DARK = rgba("#CA8A04")
JERSEY_SHADE = rgba("#D1D5DB")
SHORTS_SHADE = rgba("#D1D5DB")


def put(img: Image.Image, x: int, y: int, color: tuple[int, int, int, int]) -> None:
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), color)


def fill_rect(img: Image.Image, x0: int, y0: int, x1: int, y1: int, color) -> None:
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(img, x, y, color)


def save(name: str, image: Image.Image) -> None:
    path = OUT / name
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)
    print(f"Wrote {path}")


def make_head() -> Image.Image:
    img = Image.new("RGBA", (8, 8), TRANSPARENT)
    hair = HAIR
    skin = SKIN
    rows = [
        "..HHHH..",
        ".HssssH.",
        "HssEsH.H",
        "HssssssH",
        ".HssssH.",
        "..ssss..",
        "...ss...",
        "........",
    ]
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch == "H":
                put(img, x, y, hair)
            elif ch == "s":
                put(img, x, y, skin)
            elif ch == "E":
                put(img, x, y, EYE)
    return img


def make_torso() -> Image.Image:
    img = Image.new("RGBA", (10, 10), TRANSPARENT)
    fill_rect(img, 2, 1, 7, 8, WHITE)
    fill_rect(img, 3, 0, 6, 1, WHITE)
    fill_rect(img, 1, 3, 1, 6, WHITE)
    fill_rect(img, 8, 3, 8, 6, WHITE)
    fill_rect(img, 3, 4, 6, 6, JERSEY_SHADE)
    put(img, 4, 5, SHORTS_SHADE)
    put(img, 5, 5, SHORTS_SHADE)
    return img


def make_sleeve() -> Image.Image:
    img = Image.new("RGBA", (4, 4), TRANSPARENT)
    fill_rect(img, 0, 0, 3, 2, WHITE)
    fill_rect(img, 1, 2, 2, 2, JERSEY_SHADE)
    return img


def make_hand() -> Image.Image:
    img = Image.new("RGBA", (4, 4), TRANSPARENT)
    fill_rect(img, 1, 0, 2, 2, SKIN)
    put(img, 1, 3, SKIN_SHADOW)
    put(img, 2, 3, SKIN_SHADOW)
    return img


def make_shorts() -> Image.Image:
    img = Image.new("RGBA", (6, 4), TRANSPARENT)
    fill_rect(img, 0, 0, 5, 2, WHITE)
    fill_rect(img, 1, 3, 2, 3, WHITE)
    fill_rect(img, 3, 3, 4, 3, WHITE)
    fill_rect(img, 1, 2, 4, 2, SHORTS_SHADE)
    return img


def make_shin() -> Image.Image:
    img = Image.new("RGBA", (5, 7), TRANSPARENT)
    fill_rect(img, 1, 0, 3, 3, SKIN)
    put(img, 1, 1, SKIN_SHADOW)
    fill_rect(img, 0, 4, 4, 5, SHOE)
    fill_rect(img, 1, 4, 3, 4, SHOE_HI)
    put(img, 1, 6, SHOE)
    put(img, 3, 6, SHOE)
    return img


def make_star() -> Image.Image:
    img = Image.new("RGBA", (7, 7), TRANSPARENT)
    points = [
        (3, 0),
        (4, 2),
        (6, 2),
        (4, 3),
        (5, 6),
        (3, 4),
        (1, 6),
        (2, 3),
        (0, 2),
        (2, 2),
    ]
    for x, y in points:
        put(img, x, y, STAR)
    put(img, 3, 2, STAR_DARK)
    return img


def make_ball() -> Image.Image:
    img = Image.new("RGBA", (8, 8), TRANSPARENT)
    center = (3.5, 3.5)
    radius = 3.6
    pattern = [
        (1, 1),
        (5, 1),
        (2, 3),
        (6, 4),
        (1, 5),
        (4, 6),
    ]
    for y in range(8):
        for x in range(8):
            dx = x - center[0]
            dy = y - center[1]
            if dx * dx + dy * dy <= radius * radius:
                put(img, x, y, BALL_WHITE)
    for x, y in pattern:
        put(img, x, y, BALL_DARK)
    fill_rect(img, 3, 0, 4, 0, BALL_DARK)
    put(img, 0, 3, BALL_DARK)
    put(img, 7, 3, BALL_DARK)
    return img


def main() -> None:
    save("player/head.png", make_head())
    save("player/torso.png", make_torso())
    save("player/sleeve.png", make_sleeve())
    save("player/hand.png", make_hand())
    save("player/shorts.png", make_shorts())
    save("player/shin.png", make_shin())
    save("player/star.png", make_star())
    save("ball.png", make_ball())


if __name__ == "__main__":
    main()
