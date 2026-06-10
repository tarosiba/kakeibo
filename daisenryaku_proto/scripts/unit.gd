class_name Unit
extends Node2D

enum Faction {
	PLAYER,
	ENEMY,
}

@export var move_range: int = 4
@export var faction: Faction = Faction.PLAYER
@export var faction_color: Color = Color(0.85, 0.20, 0.20)

var coord: Vector2i = Vector2i.ZERO


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var body := Rect2(-10.0, -10.0, 20.0, 20.0)
	draw_rect(body, faction_color)
	draw_rect(body, Color.BLACK, false, 2.0)
	draw_line(Vector2(-6.0, 0.0), Vector2(6.0, 0.0), Color.WHITE, 2.0)
	draw_line(Vector2(0.0, -6.0), Vector2(0.0, 6.0), Color.WHITE, 2.0)
