# Retro Soccer

A retro top-down soccer game built with **Godot 4**, inspired by classic Nintendo arcade soccer titles (e.g. Nintendo World Cup).

## Features (current prototype)

- 320×240 pixel-perfect viewport with integer scaling
- Modular player visuals with animated head, arms, and legs
- 5 vs 5 match with simple CPU opponents
- Pass (Z), shoot/tackle (X), super shot (Z+X while super shots remain)
- Knockdown tackles, two halves, score and timer HUD

## Requirements

- [Godot 4.6+](https://godotengine.org/download)

## How to run

1. Open this folder in Godot (`project.godot`)
2. Press **F5** to run
3. On the title screen, press **Space** or **Enter**
4. In match:
   - **WASD / Arrow keys** — move your player
   - **Z** — pass
   - **X** — shoot (with ball) / tackle (without ball)
   - **Z + X** — super shot (5 per half)
   - **Esc** — return to title

## Project structure

```
scenes/          Main scenes (title, match, player, ball, field)
scripts/         GDScript gameplay logic
scripts/autoload/ Global game manager
```

## Roadmap

- [ ] Team select and tournament mode
- [ ] Ice / dirt field surfaces
- [ ] Pixel art sprites replacing placeholder limbs
- [ ] Improved AI and teammate commands
- [ ] Audio (chiptune BGM / SFX)
