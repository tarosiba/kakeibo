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
	spawn_unit(Map01.PLAYER_START, Unit.Faction.PLAYER, Color(0.85, 0.20, 0.20), 4)
	spawn_unit(Map01.ENEMY_START, Unit.Faction.ENEMY, Color(0.25, 0.45, 0.90), 3)


func spawn_unit(
	coord: Vector2i,
	faction: Unit.Faction,
	color: Color,
	move_range: int,
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


func _on_tile_clicked(tile: HexTile) -> void:
	tile_clicked.emit(tile)
