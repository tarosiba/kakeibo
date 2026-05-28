extends Node2D

const SCENARIO_PATH := "res://data/scenarios/poland_1939.json"

@onready var top_bar: Label = $CanvasLayer/TopBar
@onready var done_button: Button = $CanvasLayer/DoneButton

var scenario_data: Dictionary = {}
var turn_index: int = 0
var turn_number: int = 1

func _ready() -> void:
	done_button.pressed.connect(_on_done_turn_pressed)
	scenario_data = ScenarioLoader.load_json(SCENARIO_PATH)
	_update_turn_label()

func _on_done_turn_pressed() -> void:
	turn_index = (turn_index + 1) % _turn_order().size()
	if turn_index == 0:
		turn_number += 1
	_update_turn_label()

func _turn_order() -> Array:
	return scenario_data.get("turn_order", ["GER", "POL"])

func _current_side() -> String:
	var order: Array = _turn_order()
	return order[turn_index]

func _update_turn_label() -> void:
	top_bar.text = "Turn %d - %s" % [turn_number, _current_side()]
