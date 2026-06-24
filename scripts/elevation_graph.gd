class_name ElevationGraph
extends Control

var game: GolfGame

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var rect := get_rect()
	draw_rect(rect, Color(0.0, 0.0, 0.0, 0.45))
	var font := RetroTheme.default_font()
	draw_string(font, rect.position + Vector2(8.0, 12.0), "道のりの起伏（うえ＝高い）", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)

	var inner := rect.grow(-6.0)
	inner.position.y += 14.0
	inner.size.y -= 16.0
	var samples := Course.elevation_profile()
	if samples.is_empty():
		return
	var min_e := samples[0]
	var max_e := samples[0]
	for value in samples:
		min_e = minf(min_e, value)
		max_e = maxf(max_e, value)
	var range_e := maxf(max_e - min_e, 0.1)
	var points := PackedVector2Array()
	for i in range(samples.size()):
		var x := inner.position.x + inner.size.x * float(i) / float(samples.size() - 1)
		var y := inner.position.y + inner.size.y - ((samples[i] - min_e) / range_e) * inner.size.y
		points.append(Vector2(x, y))
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], Color.WHITE, 2.0)
	if game != null:
		var progress := clampf(game.distance_meters / Course.LENGTH_METERS, 0.0, 1.0)
		var marker_x := inner.position.x + inner.size.x * progress
		draw_line(Vector2(marker_x, inner.position.y), Vector2(marker_x, inner.position.y + inner.size.y), RetroTheme.ACCENT, 2.0)
		draw_string(font, Vector2(marker_x + 3.0, inner.position.y + 10.0), "現在地", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, RetroTheme.ACCENT)

func refresh() -> void:
	queue_redraw()
