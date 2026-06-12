class_name CourseMap
extends Control

var game: GolfGame

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var rect := get_rect()
	RetroTheme.draw_panel(self, rect, "layout")
	var inner := rect.grow(-4.0)
	inner.position.y += 18.0
	inner.size.y -= 22.0
	draw_rect(inner, RetroTheme.WATER)
	_draw_grid(inner)
	_draw_fairway_path(inner)
	_draw_hazards(inner)
	if game != null:
		_draw_ball(inner)
		_draw_aim_line(inner)

func _draw_grid(inner: Rect2) -> void:
	var cols := 8
	var rows := 12
	for x in range(cols + 1):
		var px := inner.position.x + inner.size.x * float(x) / float(cols)
		draw_line(Vector2(px, inner.position.y), Vector2(px, inner.position.y + inner.size.y), Color(1, 1, 1, 0.15), 1.0)
	for y in range(rows + 1):
		var py := inner.position.y + inner.size.y * float(y) / float(rows)
		draw_line(Vector2(inner.position.x, py), Vector2(inner.position.x + inner.size.x, py), Color(1, 1, 1, 0.15), 1.0)

func _draw_fairway_path(inner: Rect2) -> void:
	var points := Course.map_points()
	var scaled := PackedVector2Array()
	for p in points:
		scaled.append(inner.position + Vector2(p.x * inner.size.x, p.y * inner.size.y))
	for i in range(scaled.size() - 1):
		draw_line(scaled[i], scaled[i + 1], RetroTheme.FAIRWAY.lightened(0.1), 10.0)
		draw_line(scaled[i], scaled[i + 1], RetroTheme.ROUGH, 14.0)

func _draw_hazards(inner: Rect2) -> void:
	var bunker_center := inner.position + Vector2(inner.size.x * 0.44, inner.size.y * 0.47)
	draw_circle(bunker_center, 10.0, RetroTheme.SAND)
	var green_center := inner.position + Vector2(inner.size.x * 0.90, inner.size.y * 0.14)
	draw_circle(green_center, 12.0, RetroTheme.GREEN)

func _draw_ball(inner: Rect2) -> void:
	var pos := Course.map_position(game.distance_yards, game.lateral_yards)
	var screen_pos := inner.position + Vector2(pos.x * inner.size.x, pos.y * inner.size.y)
	draw_circle(screen_pos, 4.0, Color.WHITE)
	draw_circle(screen_pos, 4.0, Color.BLACK, false, 1.0)

func _draw_aim_line(inner: Rect2) -> void:
	if game.state != GolfGame.State.AIMING and game.state != GolfGame.State.POWER:
		return
	var start := Course.map_position(game.distance_yards, game.lateral_yards)
	var start_screen := inner.position + Vector2(start.x * inner.size.x, start.y * inner.size.y)
	var aim_rad := deg_to_rad(game.aim_degrees)
	var dir := Vector2(sin(aim_rad), -cos(aim_rad)).normalized()
	var end_screen := start_screen + dir * 36.0
	draw_line(start_screen, end_screen, Color.WHITE, 1.0)

func refresh() -> void:
	queue_redraw()
