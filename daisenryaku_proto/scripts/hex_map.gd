class_name HexMap
extends Node2D

signal tile_clicked(tile: HexTile)

const HEX_TILE_SCENE: PackedScene = preload("res://scenes/hex_tile.tscn")
const UNIT_SCENE: PackedScene = preload("res://scenes/unit.tscn")

@export var hex_size: float = 28.0

var tiles: Dictionary = {}
var units: Array[Unit] = []

@onready var tiles_root: Node2D = $Tiles
@onready var units_root: Node2D = $Units


func _ready() -> void:
	generate_map(Map01.DATA)
	_spawn_starting_units()


func generate_map(map_data: Array) -> void:
	tiles.clear()

	for r in map_data.size():
		var row: Array = map_data[r]
		for q in row.size():
			var terrain_value: int = row[q]
			var coord := Vector2i(q, r)
			var tile: HexTile = HEX_TILE_SCENE.instantiate()
			tile.setup(coord, terrain_value as Terrain.Type)
			tile.position = HexCoord.axial_to_pixel(q, r, hex_size)
			tile.clicked.connect(_on_tile_clicked)
			tiles_root.add_child(tile)
			tiles[coord] = tile


func _spawn_starting_units() -> void:
	_spawn_player_unit(Map01.PLAYER_START)
	_spawn_enemy_unit(Map01.ENEMY_START)
	_spawn_enemy_unit(Map01.ENEMY_NEAR, 8, 2, 1)


func _spawn_player_unit(coord: Vector2i) -> Unit:
	return spawn_unit(
		coord,
		Unit.Faction.PLAYER,
		Color(0.85, 0.20, 0.20),
		4,
		1,
		4,
		1,
		10,
	)


func _spawn_enemy_unit(
	coord: Vector2i,
	hp: int = 8,
	attack_power: int = 3,
	defense: int = 1,
) -> Unit:
	return spawn_unit(
		coord,
		Unit.Faction.ENEMY,
		Color(0.25, 0.45, 0.90),
		3,
		1,
		attack_power,
		defense,
		hp,
	)


func spawn_unit(
	coord: Vector2i,
	faction: Unit.Faction,
	color: Color,
	move_range: int,
	attack_range: int = 1,
	attack_power: int = 3,
	defense: int = 1,
	max_hp: int = 10,
) -> Unit:
	if not tiles.has(coord):
		push_error("Cannot spawn unit at missing tile: %s" % coord)
		return null

	var tile: HexTile = tiles[coord]
	if tile.unit != null:
		push_error("Tile already occupied: %s" % coord)
		return null

	var unit: Unit = UNIT_SCENE.instantiate()
	unit.faction = faction
	unit.faction_color = color
	unit.move_range = move_range
	unit.attack_range = attack_range
	unit.attack_power = attack_power
	unit.defense = defense
	unit.max_hp = max_hp
	unit.hp = max_hp
	unit.coord = coord
	unit.position = tile.position
	tile.unit = unit
	units_root.add_child(unit)
	units.append(unit)
	return unit


func get_tile(coord: Vector2i) -> HexTile:
	return tiles.get(coord)


func get_reachable(from: Vector2i, move_points: int) -> Dictionary:
	var result: Dictionary = {}
	var frontier: Array = [[from, move_points]]

	while not frontier.is_empty():
		var current: Array = frontier.pop_front()
		var coord: Vector2i = current[0]
		var cost_left: int = current[1]

		for offset in HexCoord.NEIGHBORS:
			var next_coord: Vector2i = coord + offset
			if not tiles.has(next_coord):
				continue

			var tile: HexTile = tiles[next_coord]
			var step_cost: int = tile.get_move_cost()
			if step_cost > cost_left:
				continue

			if tile.unit != null and next_coord != from:
				continue

			var remaining: int = cost_left - step_cost
			if result.has(next_coord) and result[next_coord] >= remaining:
				continue

			result[next_coord] = remaining
			frontier.append([next_coord, remaining])

	return result


func get_attack_targets(attacker: Unit) -> Array[HexTile]:
	var targets: Array[HexTile] = []

	for coord: Vector2i in tiles.keys():
		if HexCoord.distance(attacker.coord, coord) > attacker.attack_range:
			continue

		var tile: HexTile = tiles[coord]
		if tile.unit == null or tile.unit.faction == attacker.faction:
			continue

		targets.append(tile)

	return targets


func attack_unit(attacker: Unit, target_tile: HexTile) -> Dictionary:
	var defender: Unit = target_tile.unit
	if defender == null or defender.faction == attacker.faction:
		return {"success": false}

	if HexCoord.distance(attacker.coord, target_tile.coord) > attacker.attack_range:
		return {"success": false}

	var damage: int = CombatResolver.apply_attack(attacker, defender, target_tile)
	var killed: bool = not defender.is_alive()
	if killed:
		remove_unit(defender)

	return {
		"success": true,
		"damage": damage,
		"killed": killed,
		"defender_hp": defender.hp,
	}


func remove_unit(unit: Unit) -> void:
	if not tiles.has(unit.coord):
		return

	var tile: HexTile = tiles[unit.coord]
	if tile.unit == unit:
		tile.unit = null

	units.erase(unit)
	unit.queue_free()


func move_unit(unit: Unit, target: HexTile) -> bool:
	var from_coord: Vector2i = unit.coord
	var to_coord: Vector2i = target.coord

	if from_coord == to_coord:
		return false

	var from_tile: HexTile = tiles[from_coord]
	if from_tile.unit != unit:
		return false

	if target.unit != null:
		return false

	from_tile.unit = null
	target.unit = unit
	unit.coord = to_coord
	unit.position = target.position
	return true


func clear_highlights() -> void:
	for tile: HexTile in tiles.values():
		tile.set_highlight("")


func show_reachable(reachable: Dictionary) -> void:
	for coord: Vector2i in reachable.keys():
		var tile: HexTile = tiles[coord]
		tile.set_highlight("reachable")


func show_selected(tile: HexTile) -> void:
	tile.set_highlight("selected")


func show_attackable(targets: Array[HexTile]) -> void:
	for tile: HexTile in targets:
		tile.set_highlight("attackable")


func _on_tile_clicked(tile: HexTile) -> void:
	tile_clicked.emit(tile)
