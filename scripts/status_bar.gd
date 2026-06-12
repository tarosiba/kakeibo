class_name StatusBar
extends Control

var game: GolfGame
var player_name := "中村"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var rect := get_rect()
	draw_rect(rect, RetroTheme.PANEL_BG)
	draw_line(rect.position, rect.position + Vector2(rect.size.x, 0.0), RetroTheme.PANEL_BORDER, 2.0)
	var font := RetroTheme.default_font()
	var y := rect.position.y + 15.0
	draw_string(
		font,
		Vector2(rect.position.x + 8.0, y),
		"No.%d  %dY  par %d" % [Course.HOLE_NUMBER, Course.LENGTH_YARDS, Course.PAR],
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		12,
		RetroTheme.TEXT
	)
	if game != null:
		var wind_text := "against %.0fm" % game.wind_head if game.wind_head > 0.0 else "wind calm"
		draw_string(font, Vector2(rect.position.x + 180.0, y), wind_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, RetroTheme.ACCENT)
		draw_string(
			font,
			Vector2(rect.position.x + 320.0, y),
			"%s  %d打目" % [player_name, maxi(game.strokes + 1, 1)],
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			12,
			RetroTheme.TEXT
		)
		draw_string(
			font,
			Vector2(rect.position.x + 8.0, y + 16.0),
			game.last_message,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			10,
			RetroTheme.TEXT_DIM
		)

func refresh() -> void:
	queue_redraw()
