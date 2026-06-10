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

@export var unit_name: String = "ユニット"
@export var unit_type: UnitType = UnitType.INFANTRY
@export var move_range: int = 4
@export var attack_range: int = 1
@export var attack_power: int = 4
@export var defense: int = 1
@export var max_hp: int = 10
@export var faction: Faction = Faction.PLAYER
@export var faction_color: Color = Color(0.85, 0.20, 0.20)

var coord: Vector2i = Vector2i.ZERO
var hp: int = 10
var has_acted: bool = false


func _ready() -> void:
	hp = max_hp
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
	modulate = Color(0.55, 0.55, 0.55) if has_acted else Color.WHITE
	queue_redraw()


func _draw() -> void:
	match unit_type:
		UnitType.TANK:
			_draw_tank()
		UnitType.ARTILLERY:
			_draw_artillery()
		_:
			_draw_infantry()
	_draw_hp_bar()


func _draw_tank() -> void:
	var body := Rect2(-12.0, -10.0, 24.0, 20.0)
	draw_rect(body, faction_color)
	draw_rect(body, Color.BLACK, false, 2.0)
	draw_rect(Rect2(-8.0, -14.0, 10.0, 6.0), faction_color.lightened(0.15))
	draw_rect(Rect2(-8.0, -14.0, 10.0, 6.0), Color.BLACK, false, 1.0)


func _draw_infantry() -> void:
	var body := Rect2(-8.0, -8.0, 16.0, 16.0)
	draw_rect(body, faction_color)
	draw_rect(body, Color.BLACK, false, 2.0)
	draw_circle(Vector2.ZERO, 3.0, Color.WHITE)


func _draw_artillery() -> void:
	var points := PackedVector2Array([
		Vector2(0.0, -10.0),
		Vector2(10.0, 0.0),
		Vector2(0.0, 10.0),
		Vector2(-10.0, 0.0),
	])
	draw_colored_polygon(points, faction_color)
	draw_polyline(points + PackedVector2Array([points[0]]), Color.BLACK, 2.0)
	draw_line(Vector2(0.0, 0.0), Vector2(8.0, -4.0), Color.WHITE, 2.0)


func _draw_hp_bar() -> void:
	var bar_width: float = 24.0 if unit_type == UnitType.TANK else 22.0
	var bar_height: float = 4.0
	var bar_y: float = -20.0 if unit_type == UnitType.TANK else -18.0
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
