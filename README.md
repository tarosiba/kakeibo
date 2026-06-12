# Retro Soccer

A retro top-down soccer game built with **Godot 4**, inspired by classic Nintendo arcade soccer titles (e.g. Nintendo World Cup).

## Features (current prototype)

- 320×240 pixel-perfect viewport with integer scaling
- Modular player visuals with **pixel art sprites** (head, torso, arms, legs) and limb animation
- 5 vs 5 match with simple CPU opponents
- Team select screen with 8 fictional teams, color previews, and super shot names
- Pass (Z), shoot/tackle (X), super shot (Z+X while super shots remain)
- Knockdown tackles, two halves, score and timer HUD

## Requirements

- [Godot 4.6+](https://godotengine.org/download)

## How to run

1. Open this folder in Godot (`project.godot`)
2. Press **F5** to run
3. On the title screen, press **Space** or **Enter**
4. On team select, choose **HOME** and **AWAY**, then press **Space**
5. In match:
   - **Arrow keys / WASD** — move cursor / your player
   - **Left / Right** — switch HOME or AWAY side on team select
   - **Z** — pass
   - **X** — shoot (with ball) / tackle (without ball)
   - **Z + X** — super shot (5 per half)
   - **Esc** — return to title

## Sprites

Pixel art lives in `assets/sprites/`. To regenerate placeholder art:

```bash
python3 tools/generate_sprites.py
godot --headless --path . --import
```

```
assets/sprites/  Pixel art sprites (player parts, ball)
data/            Team definitions (teams.json)
scenes/          Main scenes (title, team select, match, player, ball, field)
scripts/         GDScript gameplay logic
scripts/autoload/ Global game manager
tools/           Sprite generation script
```

## Roadmap

- [x] Team select screen
- [ ] Tournament mode
- [ ] Ice / dirt field surfaces
- [x] Pixel art sprites replacing placeholder limbs
- [ ] Improved AI and teammate commands
- [ ] Audio (chiptune BGM / SFX)
