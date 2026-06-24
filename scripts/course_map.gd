class_name CourseMap
extends Control

var game: GolfGame

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var rect := get_rect()
	RetroTheme.draw_panel(self, rect, "地図")
	var inner := rect.grow(-4.0)
	inner.position.y += 18.0
	inner.size.y -= 22.0
	draw_rect(inner, RetroTheme.WATER)
	_draw_fairway_path(inner)
	_draw_hazards(inner)
	_draw_legend(inner)
	if game != null:
		_draw_ball(inner)
		_draw_aim_line(inner)

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
	# スタート
	var start := inner.position + Vector2(inner.size.x * 0.12, inner.size.y * 0.88)
	draw_string(RetroTheme.default_font(), start + Vector2(-4.0, 16.0), "スタート", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
	# ゴール
	draw_string(RetroTheme.default_font(), green_center + Vector2(-8.0, -14.0), "ゴール", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)

func _draw_legend(inner: Rect2) -> void:
	var font := RetroTheme.default_font()
	var base := inner.position + Vector2(4.0, inner.size.y - 10.0)
	draw_string(font, base, "●あなた", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)

func _draw_ball(inner: Rect2) -> void:
	var pos := Course.map_position(game.distance_meters, game.lateral_meters)
	var screen_pos := inner.position + Vector2(pos.x * inner.size.x, pos.y * inner.size.y)
	draw_circle(screen_pos, 5.0, Color.WHITE)
	draw_circle(screen_pos, 5.0, Color.BLACK, false, 1.0)
	draw_string(RetroTheme.default_font(), screen_pos + Vector2(6.0, 3.0), "あなた", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)

func _draw_aim_line(inner: Rect2) -> void:
	if game.state != GolfGame.State.AIMING:
		return
	var start := Course.map_position(game.distance_meters, game.lateral_meters)
	var start_screen := inner.position + Vector2(start.x * inner.size.x, start.y * inner.size.y)
	var aim_degrees: float = GolfGame.AIM_DEGREES[game.aim_slot + 1]
	var aim_rad := deg_to_rad(aim_degrees)
	var dir := Vector2(sin(aim_rad), -cos(aim_rad)).normalized()
	draw_line(start_screen, start_screen + dir * 30.0, Color("ffe080"), 2.0)

func refresh() -> void:
	queue_redraw()
