extends Node2D

const SCENARIO_PATH := "res://data/scenarios/poland_1939.json"
const UNIT_SCENE := preload("res://scenes/UnitCounter.tscn")
const MAP_ORIGIN := Vector2(140, 120)

@onready var top_bar: Label = $CanvasLayer/TopBar
@onready var done_button: Button = $CanvasLayer/DoneButton
@onready var unit_layer: Node2D = $UnitLayer

var scenario_data: Dictionary = {}
var turn_index: int = 0
var turn_number: int = 1
var units_by_id: Dictionary = {}

func _ready() -> void:
	done_button.pressed.connect(_on_done_turn_pressed)
	scenario_data = ScenarioLoader.load_json(SCENARIO_PATH)
	_spawn_units_from_scenario()
	_reset_ap_for_current_side()
	_update_turn_label()

func _on_done_turn_pressed() -> void:
	turn_index = (turn_index + 1) % _turn_order().size()
	if turn_index == 0:
		turn_number += 1
	_reset_ap_for_current_side()
	_update_turn_label()

func _turn_order() -> Array:
	return scenario_data.get("turn_order", ["GER", "POL"])

func _current_side() -> String:
	var order: Array = _turn_order()
	return order[turn_index]

func _update_turn_label() -> void:
	top_bar.text = "Turn %d - %s | Units: %d" % [turn_number, _current_side(), units_by_id.size()]

func _spawn_units_from_scenario() -> void:
	var units: Array = scenario_data.get("units", [])
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
