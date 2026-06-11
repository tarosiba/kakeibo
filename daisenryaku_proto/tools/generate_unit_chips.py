#!/usr/bin/env python3
"""Generate Daisenryaku-style unit chip PNGs for infantry, tank, and artillery."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "units"
SIZE = 64

OUTLINE = (24, 20, 36, 255)
SHADOW = (0, 0, 0, 60)


def new_canvas() -> Image.Image:
    return Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))


def put(img: Image.Image, x: int, y: int, color: tuple[int, int, int, int]) -> None:
    if 0 <= x < SIZE and 0 <= y < SIZE:
        img.putpixel((x, y), color)


def rect(img: Image.Image, x: int, y: int, w: int, h: int, color) -> None:
    for py in range(y, y + h):
        for px in range(x, x + w):
            put(img, px, py, color)


def outline_rect(img: Image.Image, x: int, y: int, w: int, h: int, color=OUTLINE) -> None:
    for px in range(x, x + w):
        put(img, px, y, color)
        put(img, px, y + h - 1, color)
    for py in range(y, y + h):
        put(img, x, py, color)
        put(img, x + w - 1, py, color)


def line(img: Image.Image, x0: int, y0: int, x1: int, y1: int, color) -> None:
    dx = abs(x1 - x0)
    dy = -abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx + dy
    while True:
        put(img, x0, y0, color)
        if x0 == x1 and y0 == y1:
            break
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x0 += sx
        if e2 <= dx:
            err += dx
            y0 += sy


def make_infantry() -> Image.Image:
    img = new_canvas()
    gold = (236, 196, 56, 255)
    gold_hi = (255, 232, 120, 255)
    gold_lo = (176, 132, 24, 255)
    pack = (92, 64, 36, 255)
    skin = (224, 184, 140, 255)

    def soldier(ox: int) -> None:
        rect(img, ox + 4, 24, 10, 12, gold)
        rect(img, ox + 5, 25, 8, 4, gold_hi)
        rect(img, ox + 5, 31, 8, 3, gold_lo)
        rect(img, ox + 5, 16, 8, 8, gold)
        rect(img, ox + 6, 17, 6, 3, gold_hi)
        rect(img, ox + 6, 14, 6, 3, gold)
        rect(img, ox + 7, 18, 4, 2, skin)
        put(img, ox + 7, 15, OUTLINE)
        put(img, ox + 9, 15, OUTLINE)
        rect(img, ox + 2, 26, 3, 8, pack)
        rect(img, ox + 13, 27, 2, 6, pack)
        outline_rect(img, ox + 4, 24, 10, 12)
        outline_rect(img, ox + 5, 14, 8, 10)

    soldier(10)
    soldier(30)
    return img


def make_tank() -> Image.Image:
    img = new_canvas()
    blue = (64, 108, 220, 255)
    blue_hi = (132, 172, 255, 255)
    blue_lo = (36, 56, 140, 255)
    tread = (28, 28, 36, 255)
    barrel = (180, 188, 204, 255)

    rect(img, 8, 36, 44, 14, blue)
    rect(img, 9, 37, 42, 4, blue_hi)
    rect(img, 9, 44, 42, 4, blue_lo)
    for tx in range(10, 48, 5):
        rect(img, tx, 48, 3, 3, tread)

    rect(img, 22, 22, 20, 16, blue)
    rect(img, 23, 23, 18, 5, blue_hi)
    rect(img, 6, 26, 18, 4, blue_hi)
    for i in range(16):
        put(img, 5 - i, 27, barrel if i % 2 == 0 else blue_hi)
    put(img, 4, 27, OUTLINE)
    put(img, 3, 27, OUTLINE)

    outline_rect(img, 8, 36, 44, 14)
    outline_rect(img, 22, 22, 20, 16)
    return img


def make_artillery() -> Image.Image:
    img = new_canvas()
    green = (48, 156, 72, 255)
    green_hi = (104, 220, 120, 255)
    green_lo = (24, 96, 44, 255)
    tread = (24, 24, 32, 255)
    barrel = (196, 204, 180, 255)

    rect(img, 14, 38, 34, 12, green)
    rect(img, 15, 39, 32, 4, green_hi)
    rect(img, 15, 44, 32, 4, green_lo)
    for tx in range(16, 44, 5):
        rect(img, tx, 48, 3, 3, tread)

    rect(img, 24, 28, 16, 12, green)
    rect(img, 25, 29, 14, 4, green_hi)
    for i in range(18):
        x = 38 + i
        y = 24 - i // 2
        put(img, x, y, barrel if i % 2 == 0 else green_hi)
    put(img, 56, 15, OUTLINE)
    put(img, 57, 15, OUTLINE)

    outline_rect(img, 14, 38, 34, 12)
    outline_rect(img, 24, 28, 16, 12)
    return img


def shift_to_enemy(img: Image.Image) -> Image.Image:
    out = img.copy()
    pixels = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            if r == OUTLINE[0] and g == OUTLINE[1] and b == OUTLINE[2]:
                pixels[x, y] = (48, 16, 16, a)
            elif g > r + 30:
                pixels[x, y] = (176, 48, 48, a)
            elif b > r + 20:
                pixels[x, y] = (196, 56, 56, a)
            elif r > 180 and g > 140:
                pixels[x, y] = (220, 96, 72, a)
            elif r > 150:
                pixels[x, y] = (min(255, r + 40), max(0, g - 60), max(0, b - 60), a)
            else:
                pixels[x, y] = (200, 64, 56, a)
    return out


def save_all() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    makers = {
        "infantry": make_infantry,
        "tank": make_tank,
        "artillery": make_artillery,
    }
    for name, maker in makers.items():
        base = maker()
        base.save(OUT_DIR / f"{name}.png")
        base.save(OUT_DIR / f"{name}_player.png")
        shift_to_enemy(base).save(OUT_DIR / f"{name}_enemy.png")
        print(f"wrote {name} chips ({SIZE}x{SIZE})")


if __name__ == "__main__":
    save_all()
