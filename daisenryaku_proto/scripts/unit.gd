class_name Unit
extends Node2D

enum Faction {
	PLAYER,
	ENEMY,
}

@export var move_range: int = 4
@export var attack_range: int = 1
@export var attack_power: int = 4
@export var defense: int = 1
@export var max_hp: int = 10
@export var faction: Faction = Faction.PLAYER
@export var faction_color: Color = Color(0.85, 0.20, 0.20)

var coord: Vector2i = Vector2i.ZERO
var hp: int = 10


func _ready() -> void:
	hp = max_hp
	queue_redraw()


func take_damage(amount: int) -> void:
	hp = maxi(0, hp - amount)
	queue_redraw()


func is_alive() -> bool:
	return hp > 0


func _draw() -> void:
	var body := Rect2(-10.0, -10.0, 20.0, 20.0)
	draw_rect(body, faction_color)
	draw_rect(body, Color.BLACK, false, 2.0)
	draw_line(Vector2(-6.0, 0.0), Vector2(6.0, 0.0), Color.WHITE, 2.0)
	draw_line(Vector2(0.0, -6.0), Vector2(0.0, 6.0), Color.WHITE, 2.0)
	_draw_hp_bar()


func _draw_hp_bar() -> void:
	var bar_width: float = 22.0
	var bar_height: float = 4.0
	var bar_y: float = -18.0
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
