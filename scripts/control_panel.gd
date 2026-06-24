class_name ControlPanel
extends Control

signal aim_changed(delta: int)
signal power_changed(delta: int)
signal shot_pressed

var game: GolfGame

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func _draw() -> void:
	var rect := get_rect()
	RetroTheme.draw_panel(self, rect, "操作")
	var font := RetroTheme.default_font()
	var x := rect.position.x + 8.0
	var y := rect.position.y + 28.0

	if game == null:
		return

	var club := game.current_club()
	draw_string(font, Vector2(x, y), "おすすめ", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, RetroTheme.TEXT_DIM)
	draw_string(font, Vector2(x, y + 14.0), club.friendly_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, RetroTheme.TEXT)
	draw_string(font, Vector2(x, y + 32.0), "ゴールまで", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, RetroTheme.TEXT_DIM)
	draw_string(
		font,
		Vector2(x, y + 46.0),
		"あと %dm" % int(game.remaining_meters()),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		14,
		RetroTheme.ACCENT
	)

	var lie := game.current_lie()
	draw_string(font, Vector2(x, y + 68.0), "今いる場所", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, RetroTheme.TEXT_DIM)
	draw_string(font, Vector2(x, y + 82.0), Course.terrain_label(lie), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, RetroTheme.TEXT)

	y += 104.0
	draw_string(font, Vector2(x, y), "① 向き（なくてもOK）", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, RetroTheme.TEXT_DIM)
	_draw_triple_choice(
		rect,
		y + 8.0,
		["左", "まっすぐ", "右"],
		game.aim_slot + 1
	)

	y += 44.0
	draw_string(font, Vector2(x, y), "② 強さ", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, RetroTheme.TEXT_DIM)
	_draw_triple_choice(
		rect,
		y + 8.0,
		["ゆるく", "ふつう", "強く"],
		game.power_level
	)
	draw_string(
		font,
		Vector2(x, y + 38.0),
		"→ だいたい %dm 飛ぶ" % int(game.estimate_shot_distance()),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		10,
		RetroTheme.TEXT_DIM
	)

	var shot_rect := Rect2(rect.position.x + 8.0, rect.position.y + rect.size.y - 42.0, rect.size.x - 16.0, 34.0)
	var can_shot := game.state == GolfGame.State.AIMING
	draw_rect(shot_rect, RetroTheme.PANEL_BORDER, false, 2.0)
	if can_shot:
		draw_rect(shot_rect.grow(-2.0), Color("d8ecff"))
	draw_string(
		font,
		shot_rect.position + Vector2(shot_rect.size.x * 0.28, 22.0),
		"③ 打つ！",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		RetroTheme.TEXT if can_shot else RetroTheme.TEXT_DIM
	)

	# Aim arrows.
	_draw_small_arrow(Rect2(rect.position.x + 8.0, rect.position.y + 132.0, 20.0, 20.0), "<")
	_draw_small_arrow(Rect2(rect.position.x + rect.size.x - 28.0, rect.position.y + 132.0, 20.0, 20.0), ">")
	# Power arrows.
	_draw_small_arrow(Rect2(rect.position.x + 8.0, rect.position.y + 176.0, 20.0, 20.0), "<")
	_draw_small_arrow(Rect2(rect.position.x + rect.size.x - 28.0, rect.position.y + 176.0, 20.0, 20.0), ">")

func _draw_triple_choice(rect: Rect2, top_y: float, labels: Array, selected: int) -> void:
	var btn_w := (rect.size.x - 24.0) / 3.0
	for i in range(3):
		var btn_rect := Rect2(rect.position.x + 8.0 + float(i) * (btn_w + 2.0), top_y, btn_w, 22.0)
		if i == selected:
			draw_rect(btn_rect, Color("b8d8f8"))
		draw_rect(btn_rect, RetroTheme.PANEL_BORDER, false, 1.0)
		var text_x := btn_rect.position.x + btn_rect.size.x * 0.5 - 16.0
		draw_string(RetroTheme.default_font(), Vector2(text_x, btn_rect.position.y + 15.0), labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, RetroTheme.TEXT)

func _draw_small_arrow(rect: Rect2, label: String) -> void:
	draw_rect(rect, RetroTheme.PANEL_BORDER, false, 1.0)
	draw_string(RetroTheme.default_font(), rect.position + Vector2(6.0, 15.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, RetroTheme.TEXT)

func _gui_input(event: InputEvent) -> void:
	if game == null:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var local: Vector2 = event.position
	if _hit(Rect2(8.0, 132.0, 20.0, 20.0), local):
		aim_changed.emit(-1)
	elif _hit(Rect2(size.x - 28.0, 132.0, 20.0, 20.0), local):
		aim_changed.emit(1)
	elif _hit(Rect2(8.0, 176.0, 20.0, 20.0), local):
		power_changed.emit(-1)
	elif _hit(Rect2(size.x - 28.0, 176.0, 20.0, 20.0), local):
		power_changed.emit(1)
	elif _hit(Rect2(8.0, size.y - 42.0, size.x - 16.0, 34.0), local) and game.state == GolfGame.State.AIMING:
		shot_pressed.emit()
	else:
		_handle_triple_click(local)

func _handle_triple_click(local: Vector2) -> void:
	var aim_y := 136.0
	var power_y := 180.0
	var btn_w := (size.x - 24.0) / 3.0
	for i in range(3):
		if _hit(Rect2(8.0 + float(i) * (btn_w + 2.0), aim_y, btn_w, 22.0), local):
			aim_changed.emit(i - (game.aim_slot + 1))
			return
		if _hit(Rect2(8.0 + float(i) * (btn_w + 2.0), power_y, btn_w, 22.0), local):
			power_changed.emit(i - game.power_level)
			return

func _hit(rect: Rect2, point: Vector2) -> bool:
	return rect.has_point(point)

func refresh() -> void:
	queue_redraw()
