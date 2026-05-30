class_name MapManager
extends Node2D

signal tile_hovered(tile_data: Dictionary)
signal tile_clicked(tile_data: Dictionary)

const HEX_TILE_SCENE: PackedScene = preload("res://scenes/HexTile.tscn")

var terrain_colors: Dictionary = {
	"clear": Color(0.78, 0.74, 0.58, 1),
	"forest": Color(0.39, 0.60, 0.35, 1),
	"mountain": Color(0.53, 0.51, 0.50, 1),
	"city": Color(0.72, 0.68, 0.52, 1),
	"river": Color(0.40, 0.64, 0.83, 1),
	"sea": Color(0.27, 0.49, 0.71, 1)
}

var owner_tints: Dictionary = {
	"GER": Color(0.92, 0.35, 0.35, 1),
	"POL": Color(0.85, 0.88, 0.95, 1),
	"SOV": Color(0.75, 0.35, 0.35, 1)
}

var tiles_by_key: Dictionary = {}
var tile_nodes_by_key: Dictionary = {}
var map_origin: Vector2 = Vector2.ZERO
var hovered_key: String = ""

var _terrain_stats: Dictionary = {}


func load_from_scenario(map_data: Dictionary, terrain_table: Dictionary) -> void:
	_terrain_stats = terrain_table
	tiles_by_key = MapBuilder.build_tile_map(map_data)
	_clear_children()
	_center_origin(map_data)
	_spawn_tiles()


func _clear_children() -> void:
	for child in get_children():
		child.queue_free()
	tile_nodes_by_key.clear()


func _spawn_tiles() -> void:
	for key in tiles_by_key.keys():
		var tile_data: Dictionary = tiles_by_key[key]
		var node: Node2D = HEX_TILE_SCENE.instantiate() as Node2D
		var q: int = int(tile_data.get("q", 0))
		var r: int = int(tile_data.get("r", 0))
		node.position = map_origin + HexGrid.axial_to_world(q, r)
		add_child(node)
		if node.has_method("setup"):
			node.call("setup", tile_data, terrain_colors, owner_tints)
		tile_nodes_by_key[key] = node


func _center_origin(map_data: Dictionary) -> void:
	var width: int = int(map_data.get("width", 20))
	var height: int = int(map_data.get("height", 14))
	var center: Vector2 = HexGrid.axial_to_world(int(width / 2), int(height / 2))
	map_origin = Vector2(560, 360) - center


func reposition_tiles() -> void:
	for key in tile_nodes_by_key.keys():
		var node: Node2D = tile_nodes_by_key[key] as Node2D
		var tile_data: Dictionary = tiles_by_key[key]
		var q: int = int(tile_data.get("q", 0))
		var r: int = int(tile_data.get("r", 0))
		node.position = map_origin + HexGrid.axial_to_world(q, r)


func world_to_hex(world_pos: Vector2) -> Vector2i:
	return HexGrid.world_to_axial(world_pos - map_origin)


func has_tile(hex: Vector2i) -> bool:
	return tiles_by_key.has(_key(hex.x, hex.y))


func get_tile(hex: Vector2i) -> Dictionary:
	var key: String = _key(hex.x, hex.y)
	if tiles_by_key.has(key):
		return tiles_by_key[key]
	return {}


func get_tile_node(hex: Vector2i) -> Node:
	var key: String = _key(hex.x, hex.y)
	if tile_nodes_by_key.has(key):
		return tile_nodes_by_key[key]
	return null


func is_passable(hex: Vector2i) -> bool:
	var tile: Dictionary = get_tile(hex)
	if tile.is_empty():
		return false
	var terrain: String = str(tile.get("terrain", "sea"))
	if terrain == "sea":
		return false
	var move_cost: int = _move_cost(terrain)
	return move_cost < 90


func _move_cost(terrain: String) -> int:
	if _terrain_stats.has(terrain) and typeof(_terrain_stats[terrain]) == TYPE_DICTIONARY:
		return int(_terrain_stats[terrain].get("move_cost", 1))
	return 1


func set_move_highlights(hexes: Array[Vector2i]) -> void:
	clear_highlights("move")
	for hex in hexes:
		var node: Node = get_tile_node(hex)
		if node != null and node.has_method("set_highlight"):
			node.call("set_highlight", "move", true)


func set_selected_hex(hex: Vector2i) -> void:
	clear_highlights("select")
	var node: Node = get_tile_node(hex)
	if node != null and node.has_method("set_highlight"):
		node.call("set_highlight", "select", true)


func clear_highlights(mode: String) -> void:
	for key in tile_nodes_by_key.keys():
		var node: Node = tile_nodes_by_key[key]
		if node == null or not node.has_method("set_highlight"):
			continue
		node.call("set_highlight", mode, false)


func count_land_hexes() -> int:
	var count: int = 0
	for key in tiles_by_key.keys():
		var tile: Dictionary = tiles_by_key[key]
		if str(tile.get("terrain", "sea")) != "sea":
			count += 1
	return count


func update_hover(world_pos: Vector2) -> void:
	var hex: Vector2i = world_to_hex(world_pos)
	var key: String = _key(hex.x, hex.y)
	if key == hovered_key:
		return
	if hovered_key != "" and tile_nodes_by_key.has(hovered_key):
		var old_node: Node = tile_nodes_by_key[hovered_key]
		if old_node.has_method("set_highlight"):
			old_node.call("set_highlight", "hover", false)
	hovered_key = ""
	if has_tile(hex) and tile_nodes_by_key.has(key):
		hovered_key = key
		var node: Node = tile_nodes_by_key[key]
		if node != null and node.has_method("set_highlight"):
			node.call("set_highlight", "hover", true)
		tile_hovered.emit(get_tile(hex))


func get_map_bounds_world() -> Rect2:
	if tiles_by_key.is_empty():
		return Rect2(map_origin, Vector2(800, 600))
	var min_v := Vector2(99999, 99999)
	var max_v := Vector2(-99999, -99999)
	for key in tile_nodes_by_key.keys():
		var node: Node2D = tile_nodes_by_key[key] as Node2D
		var p: Vector2 = node.position
		min_v.x = minf(min_v.x, p.x)
		min_v.y = minf(min_v.y, p.y)
		max_v.x = maxf(max_v.x, p.x)
		max_v.y = maxf(max_v.y, p.y)
	return Rect2(min_v - Vector2(48, 48), max_v - min_v + Vector2(96, 96))


func _key(q: int, r: int) -> String:
	return "%d,%d" % [q, r]
