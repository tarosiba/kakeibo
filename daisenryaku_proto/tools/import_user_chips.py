#!/usr/bin/env python3
"""Import user-provided unit chip PNGs from assets/units/source/."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets" / "units" / "source"
OUT_DIR = ROOT / "assets" / "units"
NAMES = ("infantry", "tank", "artillery")


def remove_background(img: Image.Image) -> Image.Image:
    img = img.convert("RGBA")
    pixels = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = pixels[x, y]
            if a < 16:
                pixels[x, y] = (0, 0, 0, 0)
                continue
            if r > 240 and g > 240 and b > 240:
                pixels[x, y] = (0, 0, 0, 0)
            elif r < 24 and g < 24 and b < 24:
                pixels[x, y] = (0, 0, 0, 0)
    return img


def shift_to_enemy(img: Image.Image) -> Image.Image:
    out = img.copy()
    pixels = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            if r > 200 and g > 170 and b < 130:
                pixels[x, y] = (210, 72, 56, a)
            elif b > r + 20:
                pixels[x, y] = (196, 56, 56, a)
            elif g > r + 20:
                pixels[x, y] = (176, 48, 48, a)
            else:
                pixels[x, y] = (min(255, r + 50), max(0, g - 70), max(0, b - 70), a)
    return out


def import_all() -> int:
    if not SOURCE_DIR.exists():
        SOURCE_DIR.mkdir(parents=True, exist_ok=True)
        print(f"Place PNG files in: {SOURCE_DIR}")
        print("Expected: infantry.png, tank.png, artillery.png")
        return 1

    imported = 0
    for name in NAMES:
        source = SOURCE_DIR / f"{name}.png"
        if not source.exists():
            print(f"skip (missing): {source.name}")
            continue

        base = remove_background(Image.open(source))
        OUT_DIR.mkdir(parents=True, exist_ok=True)
        base.save(OUT_DIR / f"{name}.png")
        base.save(OUT_DIR / f"{name}_player.png")
        shift_to_enemy(base).save(OUT_DIR / f"{name}_enemy.png")
        print(f"imported: {name}")
        imported += 1

    if imported == 0:
        print("No source PNG files found.")
        return 1

    print(f"Done. Imported {imported} chip set(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(import_all())
