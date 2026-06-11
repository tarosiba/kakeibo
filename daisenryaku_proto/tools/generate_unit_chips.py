#!/usr/bin/env python3
"""Generate unit chip PNGs and optional enemy variants."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "units"

OUTLINE = (20, 20, 30, 255)
WHITE = (245, 245, 245, 255)


def new_canvas(size: tuple[int, int] = (48, 48)) -> Image.Image:
    return Image.new("RGBA", size, (0, 0, 0, 0))


def px(draw: ImageDraw.ImageDraw, x: int, y: int, color: tuple[int, int, int, int]) -> None:
    draw.rectangle((x, y, x, y), fill=color)


def block(draw: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int, color) -> None:
    draw.rectangle((x, y, x + w - 1, y + h - 1), fill=color)


def outline_rect(draw: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int, color=OUTLINE) -> None:
    draw.rectangle((x, y, x + w - 1, y + h - 1), outline=color)


def make_infantry() -> Image.Image:
    img = new_canvas()
    draw = ImageDraw.Draw(img)
    body = (228, 196, 48, 255)
    shadow = (156, 108, 28, 255)
    gear = (92, 64, 36, 255)

    for ox in (8, 22):
        block(draw, ox + 2, 14, 8, 10, body)
        block(draw, ox + 3, 15, 6, 3, (248, 220, 96, 255))
        block(draw, ox + 3, 21, 6, 2, shadow)
        block(draw, ox + 3, 10, 6, 5, body)
        block(draw, ox + 4, 11, 4, 2, (248, 220, 96, 255))
        px(draw, ox + 4, 12, OUTLINE)
        px(draw, ox + 6, 12, OUTLINE)
        block(draw, ox + 1, 16, 2, 6, gear)
        outline_rect(draw, ox + 2, 14, 8, 10)
        outline_rect(draw, ox + 3, 10, 6, 5)

    return img


def make_tank() -> Image.Image:
    img = new_canvas()
    draw = ImageDraw.Draw(img)
    hull = (72, 108, 220, 255)
    hull_hi = (132, 164, 248, 255)
    hull_lo = (44, 64, 156, 255)
    tread = (28, 28, 36, 255)

    block(draw, 8, 24, 30, 10, hull)
    block(draw, 9, 25, 28, 3, hull_hi)
    block(draw, 9, 30, 28, 3, hull_lo)
    for x in range(10, 34, 4):
        block(draw, x, 33, 3, 2, tread)

    block(draw, 16, 16, 14, 9, hull)
    block(draw, 17, 17, 12, 3, hull_hi)
    block(draw, 6, 18, 12, 3, hull_hi)
    block(draw, 4, 18, 3, 3, OUTLINE)

    outline_rect(draw, 8, 24, 30, 10)
    outline_rect(draw, 16, 16, 14, 9)
    return img


def make_artillery() -> Image.Image:
    img = new_canvas()
    draw = ImageDraw.Draw(img)
    body = (56, 168, 72, 255)
    body_hi = (104, 220, 120, 255)
    body_lo = (32, 108, 48, 255)
    tread = (20, 20, 28, 255)

    block(draw, 14, 24, 20, 10, body)
    block(draw, 15, 25, 18, 3, body_hi)
    block(draw, 15, 30, 18, 3, body_lo)
    for x in range(16, 32, 4):
        block(draw, x, 33, 2, 2, tread)

    block(draw, 18, 18, 12, 8, body)
    for i in range(10):
        px(draw, 30 + i, 14 - i // 2, body_hi if i % 2 == 0 else body)
    px(draw, 39, 11, OUTLINE)
    px(draw, 40, 11, OUTLINE)

    outline_rect(draw, 14, 24, 20, 10)
    outline_rect(draw, 18, 18, 12, 8)
    return img


def shift_to_enemy_palette(img: Image.Image) -> Image.Image:
    out = img.copy()
    pixels = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            if r > 200 and g > 180 and b < 120:
                pixels[x, y] = (210, 72, 56, a)
            elif b > r and b > 80:
                pixels[x, y] = (196, 56, 56, a)
            elif g > r and g > 80:
                pixels[x, y] = (176, 48, 48, a)
            elif r == OUTLINE[0] and g == OUTLINE[1] and b == OUTLINE[2]:
                pixels[x, y] = (36, 16, 16, a)
            else:
                pixels[x, y] = (min(255, r + 60), max(0, g - 80), max(0, b - 80), a)
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
        shift_to_enemy_palette(base).save(OUT_DIR / f"{name}_enemy.png")
        print(f"wrote {name}.png, {name}_player.png, {name}_enemy.png")


if __name__ == "__main__":
    save_all()
