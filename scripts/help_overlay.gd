class_name HelpOverlay
extends Control

var visible_help := true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func _draw() -> void:
	if not visible_help:
		return
	var rect := get_rect()
	draw_rect(rect, Color(0.0, 0.0, 0.0, 0.55))
	var panel := Rect2(rect.position + Vector2(40.0, 80.0), Vector2(rect.size.x - 80.0, 280.0))
	RetroTheme.draw_panel(self, panel, "はじめかた")
	var font := RetroTheme.default_font()
	var x := panel.position.x + 14.0
	var y := panel.position.y + 34.0
	var lines := [
		"【ゴルフのルール（かんたん版）】",
		"・白い旗（カップ）までボールを運ぶゲームです",
		"・「打つ！」を押すたびに1回カウントされます",
		"・回数が少ないほどうまいです（このホールの目標: 5回）",
		"",
		"【操作】",
		"・強さ: ゆるく / ふつう / 強く から選ぶ",
		"・向き: そのままでOK（左・右は慣れたら）",
		"・「打つ！」でボールを飛ばす",
		"",
		"クリックまたは Enter で始める",
	]
	for line in lines:
		draw_string(font, Vector2(x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, RetroTheme.TEXT)
		y += 18.0

func _gui_input(event: InputEvent) -> void:
	if not visible_help:
		return
	if event is InputEventMouseButton and event.pressed:
		visible_help = false
		queue_redraw()
	elif event.is_action_pressed("ui_accept"):
		visible_help = false
		queue_redraw()

func refresh() -> void:
	queue_redraw()
