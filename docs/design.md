# Strategic Command-like Prototype (Godot 4)

## Goal
Create a small, playable prototype inspired by Strategic Command:
- One scenario: Poland 1939 area
- Two countries: GER and POL
- Turn-based hex gameplay
- Simple movement, combat, and victory condition

## Scope (v0)
- Hex map rendering and tile selection
- Unit placement and movement with AP
- Adjacent combat with simple formula
- Turn flow: GER -> POL
- Victory check: GER captures Warsaw

## Out of Scope (v0)
- Diplomacy
- Research tree
- Naval/air special rules
- AI opponent
- Save/load

## Folder Structure
- `scenes/`: Godot scenes (World, UI, unit/tile)
- `scripts/`: GDScript logic
- `data/`: game data and scenario JSON
- `assets/`: graphics placeholders/replacements
- `docs/`: design notes and tasks

## Core Data Contracts
- `terrain.json`: movement/defense values by terrain key
- `unit_types.json`: stats and cost by unit type
- `countries.json`: country metadata
- `scenarios/poland_1939.json`: initial map, units, turn order, victory

## Map System (v1)
- `map_builder.gd` builds a full hex grid from `width`/`height`, `default_terrain`, `regions`, and `features`
- `map_manager.gd` spawns hex tiles, handles hover/move/select highlights, and terrain passability
- `camera_controller.gd` supports right-drag pan and mouse wheel zoom
- `hex_tile.gd` draws pointy-top hex polygons with terrain color, owner tint, and city labels

## Coordinate Model
Use axial hex coordinates:
- `q`: column
- `r`: row

All tiles and unit positions are defined as `(q, r)`.

## Turn Rules (v0)
1. Start current side turn.
2. Reset AP for current side units.
3. Player moves and attacks with available AP.
4. Press "Done" to end turn.
5. Swap side and re-check victory.

## Combat Formula (v0)
Simple deterministic + small randomization:

```
damage_to_defender = max(1, attacker_attack - defender_defense + rand(-1..1))
damage_to_attacker = max(0, floor(defender_defense / 2) + rand(0..1))
```

Clamp strength to `0..max_strength`. Remove units at `<= 0`.

## Victory Condition (v0)
- Immediate Axis win when GER controls city tile `Warsaw`
- Allied win if GER fails within `max_turns`
