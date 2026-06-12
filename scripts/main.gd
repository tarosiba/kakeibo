extends Control

@onready var title_bar: Panel = $Layout/TitleBar
@onready var main_view: MainView = $Layout/MainView
@onready var course_map: CourseMap = $Layout/CourseMap
@onready var elevation_graph: ElevationGraph = $Layout/ElevationGraph
@onready var control_panel: ControlPanel = $Layout/ControlPanel
@onready var status_bar: StatusBar = $Layout/StatusBar

var game := GolfGame.new()

func _ready() -> void:
	main_view.game = game
	course_map.game = game
	elevation_graph.game = game
	control_panel.game = game
	status_bar.game = game

	game.state_changed.connect(_on_game_state_changed)
	game.hole_completed.connect(_on_hole_completed)
	control_panel.club_changed.connect(func(delta: int) -> void: game.cycle_club(delta))
	control_panel.aim_changed.connect(func(delta: float) -> void: game.adjust_aim(delta))
	control_panel.shot_pressed.connect(_on_shot_pressed)

	_refresh_all()

func _process(delta: float) -> void:
	if game.state == GolfGame.State.POWER:
		game.update_power(delta)
		_refresh_all()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		if game.state == GolfGame.State.AIMING:
			game.adjust_aim(-2.0)
		_refresh_all()
	elif event.is_action_pressed("ui_right"):
		if game.state == GolfGame.State.AIMING:
			game.adjust_aim(2.0)
		_refresh_all()
	elif event.is_action_pressed("ui_up"):
		if game.state == GolfGame.State.AIMING:
			game.cycle_club(-1)
		_refresh_all()
	elif event.is_action_pressed("ui_down"):
		if game.state == GolfGame.State.AIMING:
			game.cycle_club(1)
		_refresh_all()
	elif event.is_action_pressed("ui_accept"):
		_handle_shot_action()
	elif event.is_action_pressed("ui_cancel"):
		if game.state == GolfGame.State.DONE:
			game.reset_hole()
			_refresh_all()

func _on_shot_pressed() -> void:
	_handle_shot_action()

func _handle_shot_action() -> void:
	if game.state == GolfGame.State.AIMING:
		game.begin_power_gauge()
	elif game.state == GolfGame.State.POWER:
		game.confirm_shot()
	_refresh_all()

func _on_game_state_changed() -> void:
	_refresh_all()

func _on_hole_completed(strokes: int) -> void:
	game.last_message = "ホールアウト！ %d打 — Escで再プレイ" % strokes

func _refresh_all() -> void:
	main_view.refresh()
	course_map.refresh()
	elevation_graph.refresh()
	control_panel.refresh()
	status_bar.refresh()
	if is_instance_valid(title_bar):
		title_bar.queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), RetroTheme.BG)
