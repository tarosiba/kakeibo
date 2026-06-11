class_name Unit
extends Node2D

enum Faction {
	PLAYER,
	ENEMY,
}

enum UnitType {
	TANK,
	INFANTRY,
	ARTILLERY,
}

const FACTION_COLORS: Dictionary = {
	Faction.PLAYER: Color(0.28, 0.52, 0.92),
	Faction.ENEMY: Color(0.88, 0.22, 0.22),
}

@export var unit_name: String = "ユニット"
@export var unit_type: UnitType = UnitType.INFANTRY
@export var move_range: int = 4
@export var attack_range: int = 1
@export var attack_power: int = 4
@export var defense: int = 1
@export var max_hp: int = 10
@export var faction: Faction = Faction.PLAYER
@export var faction_color: Color = Color(0.28, 0.52, 0.92)

@onready var chip_sprite: Sprite2D = $ChipSprite

var coord: Vector2i = Vector2i.ZERO
var hp: int = 10
var has_acted: bool = false


static func get_faction_color(faction: Faction) -> Color:
	return FACTION_COLORS.get(faction, Color.WHITE)


func _ready() -> void:
	hp = max_hp
	faction_color = get_faction_color(faction)
	_update_visual()


func take_damage(amount: int) -> void:
	hp = maxi(0, hp - amount)
	_update_visual()


func is_alive() -> bool:
	return hp > 0


func mark_acted() -> void:
	has_acted = true
	_update_visual()


func reset_turn() -> void:
	has_acted = false
	_update_visual()


func _update_visual() -> void:
	faction_color = get_faction_color(faction)
	if chip_sprite != null:
		chip_sprite.texture = UnitAtlas.get_texture(unit_type, faction)
	modulate = Color(0.55, 0.55, 0.55) if has_acted else Color.WHITE
	queue_redraw()


func _draw() -> void:
	_draw_hp_bar()


func _draw_hp_bar() -> void:
	var bar_width: float = 24.0 if unit_type == UnitType.TANK else 22.0
	var bar_height: float = 4.0
	var bar_y: float = -22.0
	var ratio: float = float(hp) / float(max_hp)

	draw_rect(Rect2(-bar_width * 0.5, bar_y, bar_width, bar_height), Color(0.15, 0.15, 0.15))
	draw_rect(
		Rect2(-bar_width * 0.5, bar_y, bar_width * ratio, bar_height),
		_get_hp_color(ratio),
	)


func _get_hp_color(ratio: float) -> Color:
	if ratio > 0.5:
		return Color(0.25, 0.85, 0.30)
	if ratio > 0.25:
		return Color(0.95, 0.75, 0.15)
	return Color(0.90, 0.20, 0.20)
