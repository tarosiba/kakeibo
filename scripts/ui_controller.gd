extends Node

func set_turn_label(label: Label, turn_number: int, side: String) -> void:
	label.text = "Turn %d - %s" % [turn_number, side]

func show_message(label: Label, text: String) -> void:
	label.text = text
