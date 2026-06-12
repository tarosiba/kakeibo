class_name ControlPanel
extends Control

signal club_changed(delta: int)
signal aim_changed(delta: float)
signal shot_pressed

var game: GolfGame

const ROW_HEIGHT := 22.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func _draw() -> void:
	var rect := get_rect()
	RetroTheme.draw_panel(self, rect)
	var font := RetroTheme.default_font()
	var x := rect.position.x + 8.0
	var y := rect.position.y + 8.0
	draw_string(font, Vector2(x, y + 12.0), "club", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, RetroTheme.TEXT_DIM)
	if game != null:
		var club := Clubs.get_club(game.club_index)
		draw_string(font, Vector2(x + 52.0, y + 12.0), club.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, RetroTheme.TEXT)
		draw_string(font, Vector2(x, y + 36.0), "AUTO SET", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, RetroTheme.ACCENT)
		draw_string(font, Vector2(x, y + 58.0), "direction", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, RetroTheme.TEXT_DIM)
		draw_string(font, Vector2(x + 72.0, y + 58.0), "%+.0f°" % game.aim_degrees, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, RetroTheme.TEXT)
		draw_string(font, Vector2(x, y + 82.0), "view", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, RetroTheme.TEXT_DIM)
		draw_string(font, Vector2(x + 40.0, y + 82.0), "OFF", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, RetroTheme.TEXT)
		var info_y := y + 108.0
		draw_string(font, Vector2(x, info_y), "wind", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, RetroTheme.TEXT_DIM)
		draw_string(font, Vector2(x, info_y + 16.0), _wind_label(), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, RetroTheme.TEXT)
		draw_string(font, Vector2(x, info_y + 36.0), "lie", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, RetroTheme.TEXT_DIM)
		draw_string(font, Vector2(x, info_y + 52.0), _lie_label(game.current_lie()), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, RetroTheme.TEXT)
		draw_string(font, Vector2(x, info_y + 72.0), "残り", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, RetroTheme.TEXT_DIM)
		draw_string(font, Vector2(x + 34.0, info_y + 72.0), "%.0fy" % game.remaining_yards(), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, RetroTheme.ACCENT)
	_draw_buttons(rect)

func _draw_buttons(rect: Rect2) -> void:
	var labels := ["ADVICE", "LAYOUT", "MESH", "LIE", "AUTO"]
	var start_y := rect.position.y + 250.0
	for i in range(labels.size()):
		var btn_rect := Rect2(rect.position.x + 8.0, start_y + float(i) * 24.0, rect.size.x - 16.0, 20.0)
		draw_rect(btn_rect, RetroTheme.PANEL_BORDER, false, 1.0)
		draw_string(RetroTheme.default_font(), btn_rect.position + Vector2(8.0, 14.0), labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, RetroTheme.TEXT_DIM)
	# Club arrows.
	_draw_arrow(Rect2(rect.position.x + 8.0, rect.position.y + 18.0, 18.0, 18.0), "<")
	_draw_arrow(Rect2(rect.position.x + rect.size.x - 26.0, rect.position.y + 18.0, 18.0, 18.0), ">")
	# Direction arrows.
	_draw_arrow(Rect2(rect.position.x + 8.0, rect.position.y + 64.0, 18.0, 18.0), "<")
	_draw_arrow(Rect2(rect.position.x + rect.size.x - 26.0, rect.position.y + 64.0, 18.0, 18.0), ">")
	# SHOT button.
	var shot_rect := Rect2(rect.position.x + 8.0, rect.position.y + rect.size.y - 34.0, rect.size.x - 16.0, 26.0)
	var shot_enabled := game != null and game.state == GolfGame.State.AIMING
	var shot_color := RetroTheme.TEXT if shot_enabled else RetroTheme.TEXT_DIM
	draw_rect(shot_rect, RetroTheme.PANEL_BORDER, false, 2.0)
	draw_string(RetroTheme.default_font(), shot_rect.position + Vector2(shot_rect.size.x * 0.38, 18.0), "SHOT", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, shot_color)

func _draw_arrow(rect: Rect2, label: String) -> void:
	draw_rect(rect, RetroTheme.PANEL_BORDER, false, 1.0)
	draw_string(RetroTheme.default_font(), rect.position + Vector2(6.0, 14.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, RetroTheme.TEXT)

func _wind_label() -> String:
	if game == null:
		return ""
	var head := game.wind_head
	if head > 0.5:
		return "against %.0fm" % head
	if head < -0.5:
		return "follow %.0fm" % absf(head)
	return "calm"

func _lie_label(lie: String) -> String:
	match lie:
		"fairway":
			return "フェアウェイ"
		"rough":
			return "ラフ"
		"bunker":
			return "バンカー"
		"green":
			return "グリーン"
		"water":
			return "池"
		"tee":
			return "ティー"
		_:
			return lie

func _gui_input(event: InputEvent) -> void:
	if game == null:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local: Vector2 = event.position
		if _rect_contains(Rect2(8.0, 18.0, 18.0, 18.0), local):
			club_changed.emit(-1)
		elif _rect_contains(Rect2(size.x - 26.0, 18.0, 18.0, 18.0), local):
			club_changed.emit(1)
		elif _rect_contains(Rect2(8.0, 64.0, 18.0, 18.0), local):
			aim_changed.emit(-2.0)
		elif _rect_contains(Rect2(size.x - 26.0, 64.0, 18.0, 18.0), local):
			aim_changed.emit(2.0)
		elif _rect_contains(Rect2(8.0, size.y - 34.0, size.x - 16.0, 26.0), local) and game.state == GolfGame.State.AIMING:
			shot_pressed.emit()

func _rect_contains(rect: Rect2, point: Vector2) -> bool:
	return Rect2(rect.position, rect.size).has_point(point)

func refresh() -> void:
	queue_redraw()
