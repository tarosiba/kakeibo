extends Node2D

const SCENARIO_PATH := "res://data/scenarios/poland_1939.json"
const TERRAIN_PATH := "res://data/terrain.json"
const UNIT_SCENE: PackedScene = preload("res://scenes/UnitCounter.tscn")

@onready var camera: Camera2D = $Camera2D
@onready var map_manager: MapManager = $MapManager
@onready var unit_layer: Node2D = $UnitLayer
@onready var top_bar: Label = $CanvasLayer/TopBar
@onready var map_info: Label = $CanvasLayer/MapInfo
@onready var done_button: Button = $CanvasLayer/DoneButton

var scenario_data: Dictionary = {}
var turn_index: int = 0
var turn_number: int = 1
var units_by_id: Dictionary = {}
var selected_unit: Variant = null


func _ready() -> void:
	done_button.pressed.connect(_on_done_turn_pressed)
	scenario_data = ScenarioLoader.load_json(SCENARIO_PATH)
	var terrain_table: Dictionary = ScenarioLoader.load_json(TERRAIN_PATH)

	var map_variant: Variant = scenario_data.get("map", {})
	if typeof(map_variant) == TYPE_DICTIONARY:
		map_manager.load_from_scenario(map_variant, terrain_table)
		map_manager.tile_hovered.connect(_on_tile_hovered)

	_spawn_units_from_scenario()
	_reset_ap_for_current_side()
	_update_turn_label()
	_update_map_info_line()

	var bounds: Rect2 = map_manager.get_map_bounds_world()
	if camera.has_method("focus_on_rect"):
		camera.call("focus_on_rect", bounds)


func _process(_delta: float) -> void:
	map_manager.update_hover(get_global_mouse_position())


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return
	_handle_click(get_global_mouse_position())


func _on_done_turn_pressed() -> void:
	turn_index = (turn_index + 1) % _turn_order().size()
	if turn_index == 0:
		turn_number += 1
	_clear_selection()
	_reset_ap_for_current_side()
	_update_turn_label()


func _on_tile_hovered(tile_data: Dictionary) -> void:
	var terrain: String = str(tile_data.get("terrain", ""))
	var owner: String = str(tile_data.get("owner", ""))
	var city: String = str(tile_data.get("city_name", ""))
	var q: int = int(tile_data.get("q", 0))
	var r: int = int(tile_data.get("r", 0))
	var line: String = "Hex (%d,%d) %s" % [q, r, terrain]
	if owner != "":
		line += " | " + owner
	if city != "":
		line += " | " + city
	map_info.text = line


func _turn_order() -> Array[String]:
	var raw_order: Variant = scenario_data.get("turn_order", ["GER", "POL"])
	if typeof(raw_order) != TYPE_ARRAY:
		return ["GER", "POL"]
	var order: Array[String] = []
	for entry in raw_order:
		order.append(str(entry))
	if order.is_empty():
		return ["GER", "POL"]
	return order


func _current_side() -> String:
	var order: Array[String] = _turn_order()
	return order[turn_index]


func _update_turn_label() -> void:
	var scenario_name: String = str(scenario_data.get("name", "Scenario"))
	var scenario_date: String = str(scenario_data.get("date", ""))
	top_bar.text = "%s (%s) | Turn %d - %s | Units: %d" % [
		scenario_name,
		scenario_date,
		turn_number,
		_current_side(),
		units_by_id.size()
	]


func _update_map_info_line() -> void:
	var map_variant: Variant = scenario_data.get("map", {})
	if typeof(map_variant) != TYPE_DICTIONARY:
		map_info.text = "Map: unknown"
		return
	var map_data: Dictionary = map_variant
	map_info.text = "Map: %dx%d | Land hexes: %d" % [
		int(map_data.get("width", 0)),
		int(map_data.get("height", 0)),
		map_manager.count_land_hexes()
	]


func _spawn_units_from_scenario() -> void:
	var units_variant: Variant = scenario_data.get("units", [])
	if typeof(units_variant) != TYPE_ARRAY:
		return
	var units: Array = units_variant
	for unit_data_variant in units:
		if typeof(unit_data_variant) != TYPE_DICTIONARY:
			continue
		var unit_data: Dictionary = unit_data_variant
		var unit_instance: Node2D = UNIT_SCENE.instantiate() as Node2D
		var id: String = str(unit_data.get("id", ""))
		var country: String = str(unit_data.get("country", ""))
		var type: String = str(unit_data.get("type", "infantry"))
		var q: int = int(unit_data.get("q", 0))
		var r: int = int(unit_data.get("r", 0))
		var strength: int = int(unit_data.get("strength", 10))
		var ap: int = int(unit_data.get("ap", 2))

		unit_instance.set("unit_id", id)
		unit_instance.set("country", country)
		unit_instance.set("unit_type", type)
		unit_instance.set("max_ap", ap)
		unit_instance.set("current_ap", ap)
		unit_instance.set("strength", strength)
		unit_instance.call("set_axial_position", q, r)
		unit_instance.position = _hex_to_world(q, r)

		unit_layer.add_child(unit_instance)
		if id != "":
			units_by_id[id] = unit_instance


func _hex_to_world(q: int, r: int) -> Vector2:
	return map_manager.map_origin + HexGrid.axial_to_world(q, r)


func _handle_click(world_pos: Vector2) -> void:
	var hex: Vector2i = map_manager.world_to_hex(world_pos)
	if not map_manager.has_tile(hex):
		_clear_selection()
		return

	var clicked_unit: Variant = _unit_at_hex(hex)
	if clicked_unit != null:
		if clicked_unit.country == _current_side():
			_select_unit(clicked_unit)
		return

	if selected_unit == null:
		return
	if selected_unit.country != _current_side():
		return
	if not map_manager.is_passable(hex):
		return
	if not _is_adjacent(selected_unit, hex):
		return
	if _unit_at_hex(hex) != null:
		return
	if not selected_unit.spend_ap(1):
		return

	selected_unit.call("set_axial_position", hex.x, hex.y)
	selected_unit.position = _hex_to_world(hex.x, hex.y)
	_refresh_move_highlights()


func _select_unit(unit_node: Variant) -> void:
	if selected_unit != null:
		selected_unit.call("set_selected", false)
	selected_unit = unit_node
	selected_unit.call("set_selected", true)
	_refresh_move_highlights()


func _clear_selection() -> void:
	if selected_unit != null:
		selected_unit.call("set_selected", false)
	selected_unit = null
	map_manager.clear_highlights("move")
	map_manager.clear_highlights("select")


func _refresh_move_highlights() -> void:
	map_manager.clear_highlights("move")
	map_manager.clear_highlights("select")
	if selected_unit == null:
		return
	if selected_unit.country != _current_side():
		return
	if selected_unit.current_ap <= 0:
		return

	var hex: Vector2i = Vector2i(selected_unit.q, selected_unit.r)
	map_manager.set_selected_hex(hex)

	var reachable: Array[Vector2i] = []
	var neighbors: Array[Vector2i] = HexGrid.neighbors(selected_unit.q, selected_unit.r)
	for neighbor in neighbors:
		if not map_manager.is_passable(neighbor):
			continue
		if _unit_at_hex(neighbor) != null:
			continue
		reachable.append(neighbor)
	map_manager.set_move_highlights(reachable)


func _unit_at_hex(hex: Vector2i) -> Variant:
	for unit_node in units_by_id.values():
		if unit_node.q == hex.x and unit_node.r == hex.y:
			return unit_node
	return null


func _is_adjacent(unit_node: Variant, target_hex: Vector2i) -> bool:
	var neighbors: Array[Vector2i] = HexGrid.neighbors(unit_node.q, unit_node.r)
	return neighbors.has(target_hex)


func _reset_ap_for_current_side() -> void:
	var side: String = _current_side()
	for unit_node in units_by_id.values():
		if unit_node.country == side:
			unit_node.call("reset_ap")
