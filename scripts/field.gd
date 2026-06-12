extends Node2D

const FIELD_SIZE := Vector2(300.0, 180.0)
const GOAL_HALF_HEIGHT := 24.0


func _draw() -> void:
	var origin := Vector2(-FIELD_SIZE.x * 0.5, -FIELD_SIZE.y * 0.5)
	draw_rect(Rect2(origin, FIELD_SIZE), Color("#2f855a"))
	draw_rect(Rect2(origin, FIELD_SIZE), Color.WHITE, false, 2.0)

	var center := Vector2.ZERO
	draw_line(Vector2(-FIELD_SIZE.x * 0.5, 0.0), Vector2(FIELD_SIZE.x * 0.5, 0.0), Color.WHITE, 1.0)
	draw_arc(center, 24.0, 0.0, TAU, 24, Color.WHITE, 1.0)
	draw_rect(Rect2(-10.0, -10.0, 20.0, 20.0), Color.WHITE, false, 1.0)

	_draw_goal(-FIELD_SIZE.x * 0.5)
	_draw_goal(FIELD_SIZE.x * 0.5)


func _draw_goal(x: float) -> void:
	draw_line(Vector2(x, -GOAL_HALF_HEIGHT), Vector2(x, GOAL_HALF_HEIGHT), Color.WHITE, 2.0)
	draw_line(Vector2(x, -GOAL_HALF_HEIGHT), Vector2(x - 8.0 * signf(x), -GOAL_HALF_HEIGHT), Color("#f8fafc"), 2.0)
	draw_line(Vector2(x, GOAL_HALF_HEIGHT), Vector2(x - 8.0 * signf(x), GOAL_HALF_HEIGHT), Color("#f8fafc"), 2.0)


static func get_bounds() -> Rect2:
	return Rect2(-FIELD_SIZE * 0.5, FIELD_SIZE)


static func get_goal_half_height() -> float:
	return GOAL_HALF_HEIGHT
