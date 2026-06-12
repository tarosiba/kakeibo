class_name StatusBar
extends Control

var game: GolfGame
var player_name := "あなた"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var rect := get_rect()
	draw_rect(rect, RetroTheme.PANEL_BG)
	draw_line(rect.position, rect.position + Vector2(rect.size.x, 0.0), RetroTheme.PANEL_BORDER, 2.0)
	var font := RetroTheme.default_font()
	var y := rect.position.y + 14.0

	if game == null:
		return

	draw_string(
		font,
		Vector2(rect.position.x + 8.0, y),
		"第%dホール | ゴールまで %dm | 目標 %d回以内" % [
			Course.HOLE_NUMBER,
			int(Course.LENGTH_METERS),
			Course.PAR,
		],
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		11,
		RetroTheme.TEXT
	)
	draw_string(
		font,
		Vector2(rect.position.x + 420.0, y),
		"%sの %d回目" % [player_name, maxi(game.strokes + 1, 1)],
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		11,
		RetroTheme.TEXT
	)
	draw_string(
		font,
		Vector2(rect.position.x + 8.0, y + 16.0),
		game.last_message,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		11,
		RetroTheme.ACCENT
	)
	draw_string(
		font,
		Vector2(rect.position.x + 8.0, y + 30.0),
		game.hint_message,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		10,
		RetroTheme.TEXT_DIM
	)

func refresh() -> void:
	queue_redraw()
