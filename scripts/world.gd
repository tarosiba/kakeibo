extends Node2D

const SCENARIO_PATH := "res://data/scenarios/poland_1939.json"
const UNIT_SCENE := preload("res://scenes/UnitCounter.tscn")
const HEX_TILE_SCENE := preload("res://scenes/HexTile.tscn")
const MAP_ORIGIN := Vector2(140, 120)

@onready var top_bar: Label = $CanvasLayer/TopBar
@onready var done_button: Button = $CanvasLayer/DoneButton
@onready var map_layer: Node2D = $MapLayer
@onready var unit_layer: Node2D = $UnitLayer

var scenario_data: Dictionary = {}
var turn_index: int = 0
var turn_number: int = 1
var units_by_id: Dictionary = {}
var terrain_colors := {
	"clear": Color(0.78, 0.74, 0.58, 1),
	"forest": Color(0.39, 0.60, 0.35, 1),
	"mountain": Color(0.53, 0.51, 0.50, 1),
	"city": Color(0.72, 0.68, 0.52, 1),
	"river": Color(0.40, 0.64, 0.83, 1),
	"sea": Color(0.27, 0.49, 0.71, 1)
}

func _ready() -> void:
	done_button.pressed.connect(_on_done_turn_pressed)
	scenario_data = ScenarioLoader.load_json(SCENARIO_PATH)
	_spawn_tiles_from_scenario()
	_spawn_units_from_scenario()
	_reset_ap_for_current_side()
	_update_turn_label()

func _on_done_turn_pressed() -> void:
	turn_index = (turn_index + 1) % _turn_order().size()
	if turn_index == 0:
		turn_number += 1
	_reset_ap_for_current_side()
	_update_turn_label()

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
	top_bar.text = "Turn %d - %s | Units: %d" % [turn_number, _current_side(), units_by_id.size()]

func _spawn_tiles_from_scenario() -> void:
	var map_variant: Variant = scenario_data.get("map", {})
	if typeof(map_variant) != TYPE_DICTIONARY:
		return
	var map_data: Dictionary = map_variant
	var tiles_variant: Variant = map_data.get("tiles", [])
	if typeof(tiles_variant) != TYPE_ARRAY:
		return
	var tiles: Array = tiles_variant
	for tile_data_variant in tiles:
		if typeof(tile_data_variant) != TYPE_DICTIONARY:
			continue
		var tile_data: Dictionary = tile_data_variant
		var tile_instance := HEX_TILE_SCENE.instantiate()
		var q := int(tile_data.get("q", 0))
		var r := int(tile_data.get("r", 0))
		var terrain := str(tile_data.get("terrain", "sea"))
		tile_instance.position = _hex_to_world(q, r)
		var background: ColorRect = tile_instance.get_node("Background") as ColorRect
		if background == null:
			continue
		background.color = terrain_colors.get(terrain, terrain_colors["sea"])
		map_layer.add_child(tile_instance)

func _spawn_units_from_scenario() -> void:
	var units_variant: Variant = scenario_data.get("units", [])
	if typeof(units_variant) != TYPE_ARRAY:
		return
	var units: Array = units_variant
	for unit_data_variant in units:
		if typeof(unit_data_variant) != TYPE_DICTIONARY:
			continue
		var unit_data: Dictionary = unit_data_variant
		var unit_instance := UNIT_SCENE.instantiate()
		var id := str(unit_data.get("id", ""))
		var country := str(unit_data.get("country", ""))
		var type := str(unit_data.get("type", "infantry"))
		var q := int(unit_data.get("q", 0))
		var r := int(unit_data.get("r", 0))
		var strength := int(unit_data.get("strength", 10))
		var ap := int(unit_data.get("ap", 2))

		unit_instance.unit_id = id
		unit_instance.country = country
		unit_instance.unit_type = type
		unit_instance.max_ap = ap
		unit_instance.current_ap = ap
		unit_instance.strength = strength
		unit_instance.set_axial_position(q, r)
		unit_instance.position = _hex_to_world(q, r)

		unit_layer.add_child(unit_instance)
		if id != "":
			units_by_id[id] = unit_instance

func _hex_to_world(q: int, r: int) -> Vector2:
	return MAP_ORIGIN + HexGrid.axial_to_world(q, r)

func _reset_ap_for_current_side() -> void:
	var side := _current_side()
	for unit_node in units_by_id.values():
		if unit_node.country == side:
			unit_node.reset_ap()
