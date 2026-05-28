class_name TurnManager
extends RefCounted

var turn_order: Array[String] = ["GER", "POL"]
var turn_index: int = 0
var turn_number: int = 1

func setup(order: Array) -> void:
	turn_order.clear()
	for value in order:
		turn_order.append(str(value))

func current_side() -> String:
	if turn_order.is_empty():
		return ""
	return turn_order[turn_index]

func next_turn() -> void:
	if turn_order.is_empty():
		return
	turn_index = (turn_index + 1) % turn_order.size()
	if turn_index == 0:
		turn_number += 1
