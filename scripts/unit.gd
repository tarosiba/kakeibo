extends Node2D

@export var unit_id: String = ""
@export var country: String = ""
@export var unit_type: String = "infantry"
@export var strength: int = 10
@export var max_ap: int = 2
@export var current_ap: int = 2

@onready var strength_label: Label = $StrengthLabel

func _ready() -> void:
	_refresh_ui()

func spend_ap(cost: int) -> bool:
	if current_ap < cost:
		return false
	current_ap -= cost
	return true

func reset_ap() -> void:
	current_ap = max_ap

func apply_damage(amount: int) -> void:
	strength = max(0, strength - amount)
	_refresh_ui()

func _refresh_ui() -> void:
	strength_label.text = str(strength)
