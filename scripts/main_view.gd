class_name MainView
extends Control

var game: GolfGame

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var rect := get_rect()
	draw_rect(rect, Color("0d2850"))
	_draw_sky(rect)
	_draw_landscape(rect)
	_draw_fairway_perspective(rect)
	_draw_goal_marker(rect)
	_draw_golfer(rect)
	_draw_ball(rect)
	_draw_hud(rect)

func _draw_sky(rect: Rect2) -> void:
	var top := rect.position
	for i in range(int(rect.size.y * 0.52)):
		var t := float(i) / (rect.size.y * 0.52)
		var color := RetroTheme.SKY_TOP.lerp(RetroTheme.SKY_BOTTOM, t)
		draw_line(top + Vector2(0.0, float(i)), top + Vector2(rect.size.x, float(i)), color, 1.0)

func _draw_landscape(rect: Rect2) -> void:
	var horizon_y := rect.position.y + rect.size.y * 0.48
	var water_pts := PackedVector2Array([
		Vector2(rect.position.x, horizon_y + 18.0),
		Vector2(rect.position.x + rect.size.x * 0.42, horizon_y + 8.0),
		Vector2(rect.position.x + rect.size.x * 0.42, horizon_y + 42.0),
		Vector2(rect.position.x, horizon_y + 52.0),
	])
	draw_colored_polygon(water_pts, RetroTheme.WATER)
	var hill_pts := PackedVector2Array([
		Vector2(rect.position.x, horizon_y + 30.0),
		Vector2(rect.position.x + rect.size.x * 0.25, horizon_y - 8.0),
		Vector2(rect.position.x + rect.size.x * 0.55, horizon_y + 4.0),
		Vector2(rect.position.x + rect.size.x * 0.82, horizon_y - 4.0),
		Vector2(rect.position.x + rect.size.x, horizon_y + 16.0),
		Vector2(rect.position.x + rect.size.x, horizon_y + 70.0),
		Vector2(rect.position.x, horizon_y + 70.0),
	])
	draw_colored_polygon(hill_pts, Color("3d7f3d"))
	# 池ラベル
	var font := RetroTheme.default_font()
	draw_string(font, Vector2(rect.position.x + 12.0, horizon_y + 36.0), "池（さけよう）", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)

func _draw_fairway_perspective(rect: Rect2) -> void:
	var progress := 0.0
	if game != null:
		progress = clampf(game.distance_meters / Course.LENGTH_METERS, 0.0, 1.0)
	var bottom_y := rect.position.y + rect.size.y * 0.92
	var top_y := rect.position.y + rect.size.y * 0.56
	var center_x := rect.position.x + rect.size.x * 0.5
	var half_bottom := rect.size.x * 0.34
	var half_top := rect.size.x * 0.05
	var fairway_pts := PackedVector2Array([
		Vector2(center_x - half_bottom, bottom_y),
		Vector2(center_x + half_bottom, bottom_y),
		Vector2(center_x + half_top, top_y),
		Vector2(center_x - half_top, top_y),
	])
	draw_colored_polygon(fairway_pts, RetroTheme.FAIRWAY)

func _draw_goal_marker(rect: Rect2) -> void:
	var bottom_y := rect.position.y + rect.size.y * 0.92
	var top_y := rect.position.y + rect.size.y * 0.56
	var center_x := rect.position.x + rect.size.x * 0.5
	var pin_y := lerpf(bottom_y - 12.0, top_y + 8.0, 0.88)
	draw_circle(Vector2(center_x, pin_y), 3.0, Color.WHITE)
	draw_line(Vector2(center_x, pin_y), Vector2(center_x, pin_y - 14.0), Color.WHITE, 2.0)
	var font := RetroTheme.default_font()
	draw_string(font, Vector2(center_x - 28.0, pin_y - 20.0), "ゴール", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)

func _draw_golfer(rect: Rect2) -> void:
	if game == null or game.state == GolfGame.State.FLYING:
		return
	var base := Vector2(rect.position.x + rect.size.x * 0.46, rect.position.y + rect.size.y * 0.78)
	draw_rect(Rect2(base.x - 4.0, base.y - 28.0, 8.0, 18.0), Color("2a58b8"))
	draw_rect(Rect2(base.x - 5.0, base.y - 10.0, 10.0, 14.0), Color.WHITE)
	draw_line(base + Vector2(8.0, -18.0), base + Vector2(24.0, -2.0), Color("d0d0d0"), 2.0)

func _draw_ball(rect: Rect2) -> void:
	if game == null:
		return
	var progress := clampf(game.distance_meters / Course.LENGTH_METERS, 0.0, 1.0)
	var bottom_y := rect.position.y + rect.size.y * 0.86
	var top_y := rect.position.y + rect.size.y * 0.60
	var ball_y := lerpf(bottom_y, top_y, progress)
	var lateral_t := clampf(game.lateral_meters / 25.0, -1.0, 1.0)
	var center_x := rect.position.x + rect.size.x * 0.5 + lateral_t * rect.size.x * 0.18
	var radius := lerpf(5.0, 2.0, progress)
	draw_circle(Vector2(center_x, ball_y), radius, Color.WHITE)
	draw_circle(Vector2(center_x - 1.0, ball_y - 1.0), radius * 0.25, Color("d8d8d8"))

func _draw_hud(rect: Rect2) -> void:
	if game == null:
		return
	var font := RetroTheme.default_font()
	var hud_rect := Rect2(rect.position.x + 8.0, rect.size.y - 38.0, rect.size.x - 16.0, 30.0)
	draw_rect(hud_rect, Color(0.0, 0.0, 0.0, 0.45))
	draw_string(
		font,
		hud_rect.position + Vector2(8.0, 12.0),
		"あなた",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		10,
		Color.WHITE
	)
	draw_string(
		font,
		hud_rect.position + Vector2(8.0, 24.0),
		"ゴールまで あと %dm" % int(game.remaining_meters()),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		11,
		Color("ffe080")
	)

func refresh() -> void:
	queue_redraw()
