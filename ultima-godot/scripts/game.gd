extends Control

const DungeonDataScript = preload("res://scripts/dungeon_data.gd")

enum Mode { PLAY, DIALOGUE, MAP }

@onready var ray_view: Control = $RaycastView
@onready var log_label: RichTextLabel = $BottomPanel/LogLabel
@onready var choice_box: HBoxContainer = $BottomPanel/ChoiceBox
@onready var map_panel: Panel = $MapPanel
@onready var map_canvas: Control = $MapPanel/MapCanvas
@onready var hp_bar: ColorRect = $RightPanel/HPFlask/Fill
@onready var mp_bar: ColorRect = $RightPanel/MPFlask/Fill

var player_pos := Vector2(2.5, 2.5)
var player_angle := PI * 0.5
const MOVE_SPEED := 2.0
const TURN_SPEED := 2.2

var mode: Mode = Mode.PLAY
var door_open := false
var has_key := false
var quest_stage := 0
var hp := 100.0
var mp := 80.0

var visited: Dictionary = {}
var seen: Dictionary = {}

var npcs: Array = [
	{
		"id": "ghost", "name": "亡霊シャングリック", "x": 5, "y": 3,
		"color": Color("#88ccff", 0.75),
		"dialogue_stage": 0,
	},
	{
		"id": "troll", "name": "洞窟のトロル", "x": 10, "y": 19,
		"color": Color("#8a6a40"),
		"dialogue_stage": 0,
	},
]

var items: Array = [
	{"id": "key", "name": "古い鍵", "x": 12, "y": 7, "taken": false},
]

var current_npc: Dictionary = {}
var log_lines: Array[String] = []


func _ready() -> void:
	map_canvas.game = self
	_add_log("深い迷宮に足を踏み入れた…")
	_add_log("T: 話す  L: 調べる  M: 地図  Space: 決定")
	_reveal_around_player()
	_update_view()
	_update_flasks()


func _physics_process(delta: float) -> void:
	if mode == Mode.PLAY:
		_handle_movement(delta)
		_reveal_around_player()
		_check_item_pickup()
	_update_view()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_map"):
		mode = Mode.MAP if mode != Mode.MAP else Mode.PLAY
		map_panel.visible = (mode == Mode.MAP)
		map_canvas.queue_redraw()
		return

	if mode == Mode.MAP:
		if event is InputEventKey and event.pressed and not event.echo:
			mode = Mode.PLAY
			map_panel.visible = false
		return

	if mode == Mode.DIALOGUE:
		return

	if event.is_action_pressed("action_talk"):
		_try_talk()
	elif event.is_action_pressed("action_look"):
		_try_look()
	elif event.is_action_pressed("interact"):
		_try_use()


func _handle_movement(delta: float) -> void:
	var turn := 0.0
	if Input.is_action_pressed("turn_left"):
		turn -= 1.0
	if Input.is_action_pressed("turn_right"):
		turn += 1.0
	player_angle += turn * TURN_SPEED * delta

	var move := 0.0
	if Input.is_action_pressed("move_forward"):
		move += 1.0
	if Input.is_action_pressed("move_back"):
		move -= 1.0

	var strafe := 0.0
	if Input.is_action_pressed("strafe_left"):
		strafe -= 1.0
	if Input.is_action_pressed("strafe_right"):
		strafe += 1.0

	if move != 0.0:
		_try_move(player_angle, move * MOVE_SPEED * delta)
	if strafe != 0.0:
		_try_move(player_angle + PI / 2.0, strafe * MOVE_SPEED * delta)


func _try_move(angle: float, dist: float) -> void:
	var nx := player_pos.x + sin(angle) * dist
	var ny := player_pos.y + cos(angle) * dist
	if not _is_blocked(nx, player_pos.y):
		player_pos.x = nx
	if not _is_blocked(player_pos.x, ny):
		player_pos.y = ny


func _is_blocked(x: float, y: float) -> bool:
	var margin := 0.2
	var checks := [
		Vector2(x - margin, y - margin),
		Vector2(x + margin, y - margin),
		Vector2(x - margin, y + margin),
		Vector2(x + margin, y + margin),
	]
	for c in checks:
		if DungeonDataScript.is_wall(int(c.x), int(c.y), door_open):
			return true
	return false


func _reveal_around_player() -> void:
	var px := int(player_pos.x)
	var py := int(player_pos.y)
	for dy in range(-8, 9):
		for dx in range(-8, 9):
			var tx := px + dx
			var ty := py + dy
			var key := Vector2i(tx, ty)
			visited[key] = true
			if _has_line_of_sight(tx, ty):
				seen[key] = true


func _has_line_of_sight(tx: int, ty: int) -> bool:
	var steps := maxi(absi(tx - int(player_pos.x)), absi(ty - int(player_pos.y)))
	if steps == 0:
		return true
	for i in range(1, steps):
		var t := float(i) / float(steps)
		var sx := int(lerpf(player_pos.x, float(tx) + 0.5, t))
		var sy := int(lerpf(player_pos.y, float(ty) + 0.5, t))
		if DungeonDataScript.is_wall(sx, sy, door_open):
			return false
	return true


func _check_item_pickup() -> void:
	for it in items:
		if it["taken"]:
			continue
		if player_pos.distance_to(Vector2(it["x"] + 0.5, it["y"] + 0.5)) < 0.6:
			it["taken"] = true
			if it["id"] == "key":
				has_key = true
				_add_log("古い鍵を手に入れた！")
				if quest_stage == 0:
					quest_stage = 1


func _npc_in_front() -> Dictionary:
	var check_dist := 2.5
	for n in npcs:
		var np := Vector2(n["x"] + 0.5, n["y"] + 0.5)
		var to_npc := np - player_pos
		if to_npc.length() > check_dist:
			continue
		var angle_to := atan2(to_npc.x, to_npc.y) - player_angle
		while angle_to > PI: angle_to -= TAU
		while angle_to < -PI: angle_to += TAU
		if absf(angle_to) < 0.5:
			return n
	return {}


func _try_talk() -> void:
	var n := _npc_in_front()
	if n.is_empty():
		_add_log("誰もいない。")
		return
	_start_dialogue(n)


func _try_look() -> void:
	var n := _npc_in_front()
	if not n.is_empty():
		_add_log("それは「%s」だ。" % n["name"])
		return
	var tx := int(player_pos.x + sin(player_angle) * 1.5)
	var ty := int(player_pos.y + cos(player_angle) * 1.5)
	var tile: String = DungeonDataScript.get_tile(tx, ty)
	match tile:
		"#":
			_add_log("苔むした石の壁だ。")
		"D":
			_add_log("重い鉄の扉だ。鍵穴がある。")
		"K":
			_add_log("何かが床に落ちているようだ。")
		_:
			_add_log("特に変わったものはない。")


func _try_use() -> void:
	var tx := int(player_pos.x + sin(player_angle) * 1.2)
	var ty := int(player_pos.y + cos(player_angle) * 1.2)
	if DungeonDataScript.get_tile(tx, ty) == "D":
		if has_key and quest_stage >= 1:
			door_open = true
			quest_stage = 2
			_add_log("扉の鍵が開いた！迷宮から脱出できる…")
			_add_log("=== クエストクリア！ ===")
		elif has_key:
			_add_log("扉は固く閉ざされている。何か手がかりがあるはずだ。")
		else:
			_add_log("扉は鍵がかかっている。")


func _start_dialogue(npc: Dictionary) -> void:
	mode = Mode.DIALOGUE
	current_npc = npc
	_clear_choices()
	match npc["id"]:
		"ghost":
			_ghost_dialogue()
		"troll":
			_troll_dialogue()


func _ghost_dialogue() -> void:
	if quest_stage == 0:
		_show_dialogue_text(
			"亡霊シャングリック",
			"ようこそ、深き迷宮へ…\n我はかつてここに住んでいた者の亡霊。\n東の通路の先に「古い鍵」がある。\nそれを見つけ、南の扉を開けてくれ。",
			[
				{"text": "1. 鍵を探してみる", "cb": _end_dialogue},
				{"text": "2. なぜ俺なのだ？", "cb": _ghost_why_me},
			]
		)
	elif quest_stage == 1:
		_show_dialogue_text(
			"亡霊シャングリック",
			"鍵を持っているな！\n南のほうにある鉄の扉へ向かえ。\nトロルが道を塞いでいるかもしれん。",
			[{"text": "1. ありがとう", "cb": _end_dialogue}]
		)
	else:
		_show_dialogue_text(
			"亡霊シャングリック",
			"扉は開いたのか…\nよくやった。我はここで静かに眠ろう。",
			[{"text": "1. さようなら", "cb": _end_dialogue}]
		)


func _troll_dialogue() -> void:
	if quest_stage >= 1:
		_show_dialogue_text(
			"洞窟のトロル",
			"ほう、亡霊の使いか。\n鍵を持っているなら通してやる。どうぞ。",
			[{"text": "1. 通る", "cb": _end_dialogue}]
		)
	else:
		_show_dialogue_text(
			"洞窟のトロル",
			"通さん！\nこの先は禁断の扉だ。\n亡霊に話を聞いてこい。",
			[
				{"text": "1. わかった", "cb": _end_dialogue},
				{"text": "2. 戦う（未実装）", "cb": _fight_not_impl},
			]
		)


func _ghost_why_me() -> void:
	_show_dialogue_text(
		"亡霊シャングリック",
		"生者の温もりが…久しく感じたくてな。\n頼んだぞ。",
		[{"text": "1. わかった", "cb": _end_dialogue}]
	)


func _fight_not_impl() -> void:
	_add_log("今は戦えない…")
	_end_dialogue()


func _show_dialogue_text(speaker: String, body: String, choices: Array) -> void:
	log_label.text = "[b]%s[/b]\n\n%s" % [speaker, body]
	_clear_choices()
	for ch in choices:
		var btn := Button.new()
		btn.text = ch["text"]
		btn.pressed.connect(ch["cb"])
		choice_box.add_child(btn)


func _end_dialogue() -> void:
	mode = Mode.PLAY
	_clear_choices()
	_update_log_display()


func _clear_choices() -> void:
	for c in choice_box.get_children():
		c.queue_free()


func _add_log(line: String) -> void:
	log_lines.append(line)
	if log_lines.size() > 6:
		log_lines.pop_front()
	_update_log_display()


func _update_log_display() -> void:
	log_label.text = "\n".join(log_lines)


func _update_view() -> void:
	ray_view.player_pos = player_pos
	ray_view.player_angle = player_angle
	ray_view.door_open = door_open
	ray_view.npcs = npcs
	ray_view.items = items
	map_canvas.queue_redraw()


func _update_flasks() -> void:
	var hp_h := 60.0 * (hp / 100.0)
	hp_bar.offset_top = 70.0 - hp_h
	hp_bar.offset_bottom = 70.0
	var mp_h := 60.0 * (mp / 100.0)
	mp_bar.offset_top = 70.0 - mp_h
	mp_bar.offset_bottom = 70.0
