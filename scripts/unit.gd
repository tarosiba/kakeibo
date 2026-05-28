extends Node2D

@export var unit_id: String = ""
@export var country: String = ""
@export var unit_type: String = "infantry"
@export var q: int = 0
@export var r: int = 0
@export var strength: int = 10
@export var max_ap: int = 2
@export var current_ap: int = 2

@onready var strength_label: Label = $StrengthLabel
@onready var body: ColorRect = $Body
var base_color: Color = Color(0.82, 0.82, 0.82, 1)

func _ready() -> void:
	_apply_country_color()
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

func set_axial_position(new_q: int, new_r: int) -> void:
	q = new_q
	r = new_r

func _refresh_ui() -> void:
	strength_label.text = str(strength)

func _apply_country_color() -> void:
	if country == "GER":
		base_color = Color(0.9, 0.3, 0.3, 1)
	elif country == "POL":
		base_color = Color(0.95, 0.95, 0.95, 1)
	else:
		base_color = Color(0.82, 0.82, 0.82, 1)
	body.color = base_color

func set_selected(is_selected: bool) -> void:
	if is_selected:
		body.color = base_color.lightened(0.25)
		scale = Vector2(1.15, 1.15)
	else:
		body.color = base_color
		scale = Vector2.ONE
