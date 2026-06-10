class_name HexMap
extends Node2D

signal tile_clicked(tile: HexTile)
signal tile_hovered(tile: HexTile)
signal tile_unhovered(tile: HexTile)

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
			tile.hovered.connect(_on_tile_hovered)
			tile.unhovered.connect(_on_tile_unhovered)
			tiles_root.add_child(tile)
			tiles[coord] = tile


func _spawn_starting_units() -> void:
	for config: Dictionary in Map01.PLAYER_UNITS:
		_spawn_unit_from_config(config, Unit.Faction.PLAYER)
	for config: Dictionary in Map01.ENEMY_UNITS:
		_spawn_unit_from_config(config, Unit.Faction.ENEMY)


func _spawn_unit_from_config(config: Dictionary, faction: Unit.Faction) -> Unit:
	return spawn_unit(
		config.coord,
		faction,
		config.color,
		config.move,
		config.range,
		config.atk,
		config.def,
		config.hp,
		config.name,
		config.type,
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
	unit_name: String = "ユニット",
	unit_type: Unit.UnitType = Unit.UnitType.INFANTRY,
) -> Unit:
	if not tiles.has(coord):
		push_error("Cannot spawn unit at missing tile: %s" % coord)
		return null

	var tile: HexTile = tiles[coord]
	if tile.unit != null:
		push_error("Tile already occupied: %s" % coord)
		return null

	var unit: Unit = UNIT_SCENE.instantiate()
	unit.unit_name = unit_name
	unit.unit_type = unit_type
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


func get_units_by_faction(faction: Unit.Faction) -> Array[Unit]:
	var result: Array[Unit] = []
	for unit: Unit in units:
		if unit.is_alive() and unit.faction == faction:
			result.append(unit)
	return result


func get_idle_units_by_faction(faction: Unit.Faction) -> Array[Unit]:
	var result: Array[Unit] = []
	for unit: Unit in units:
		if unit.is_alive() and unit.faction == faction and not unit.has_acted:
			result.append(unit)
	return result


func count_idle_units(faction: Unit.Faction) -> int:
	return get_idle_units_by_faction(faction).size()


func reset_all_unit_turns() -> void:
	for unit: Unit in units:
		if unit.is_alive():
			unit.reset_turn()


func has_living_units(faction: Unit.Faction) -> bool:
	return not get_units_by_faction(faction).is_empty()


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


func attack_unit(
	attacker: Unit,
	target_tile: HexTile,
	allow_counter: bool = true,
) -> Dictionary:
	var defender: Unit = target_tile.unit
	if defender == null or defender.faction == attacker.faction:
		return {"success": false}

	if HexCoord.distance(attacker.coord, target_tile.coord) > attacker.attack_range:
		return {"success": false}

	var damage: int = CombatResolver.apply_attack(attacker, defender, target_tile)
	var killed: bool = not defender.is_alive()
	if killed:
		remove_unit(defender)

	var counter: Dictionary = {}
	if allow_counter and CombatResolver.can_counterattack(attacker, defender):
		counter = _resolve_counterattack(defender, attacker)

	return {
		"success": true,
		"damage": damage,
		"killed": killed,
		"defender_hp": defender.hp if not killed else 0,
		"counter": counter,
	}


func _resolve_counterattack(defender: Unit, attacker: Unit) -> Dictionary:
	if not tiles.has(attacker.coord):
		return {"occurred": false}

	var attacker_tile: HexTile = tiles[attacker.coord]
	var counter_damage: int = CombatResolver.apply_attack(defender, attacker, attacker_tile)
	var attacker_killed: bool = not attacker.is_alive()
	if attacker_killed:
		remove_unit(attacker)

	return {
		"occurred": true,
		"damage": counter_damage,
		"killed": attacker_killed,
		"attacker_hp": attacker.hp if not attacker_killed else 0,
		"counter_attacker": defender,
		"counter_victim": attacker,
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


func predict_attack(attacker: Unit, target_tile: HexTile) -> Dictionary:
	var defender: Unit = target_tile.unit
	if defender == null or defender.faction == attacker.faction:
		return {}

	if not tiles.has(attacker.coord):
		return {}

	var attacker_tile: HexTile = tiles[attacker.coord]
	return CombatResolver.predict_exchange(
		attacker,
		defender,
		target_tile,
		attacker_tile,
	)


func clear_highlights() -> void:
	for tile: HexTile in tiles.values():
		tile.set_highlight("")
		tile.set_damage_preview("")


func show_reachable(reachable: Dictionary) -> void:
	for coord: Vector2i in reachable.keys():
		var tile: HexTile = tiles[coord]
		tile.set_highlight("reachable")


func show_selected(tile: HexTile) -> void:
	tile.set_highlight("selected")


func show_attackable(targets: Array[HexTile]) -> void:
	for tile: HexTile in targets:
		tile.set_highlight("attackable")


func show_attack_predictions(attacker: Unit, targets: Array[HexTile]) -> void:
	for tile: HexTile in targets:
		var preview: Dictionary = predict_attack(attacker, tile)
		tile.set_damage_preview(_format_tile_preview(preview))


func _format_tile_preview(preview: Dictionary) -> String:
	if preview.is_empty():
		return ""

	if preview.will_kill_defender:
		return "%d KO" % preview.outgoing_damage

	if preview.counter_possible:
		return "%d/%d" % [preview.outgoing_damage, preview.counter_damage]

	return "%d" % preview.outgoing_damage


func _on_tile_clicked(tile: HexTile) -> void:
	tile_clicked.emit(tile)


func _on_tile_hovered(tile: HexTile) -> void:
	tile_hovered.emit(tile)


func _on_tile_unhovered(tile: HexTile) -> void:
	tile_unhovered.emit(tile)
