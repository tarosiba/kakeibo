extends Node2D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const FIELD_SCENE := preload("res://scenes/field.tscn")
const FieldScript := preload("res://scripts/field.gd")

const HALF_DURATION := 90.0
const HOME_FORMATION := [
	Vector2(-70.0, 0.0),
	Vector2(-45.0, -35.0),
	Vector2(-45.0, 35.0),
	Vector2(-20.0, -20.0),
	Vector2(-20.0, 20.0),
]
const AWAY_FORMATION := [
	Vector2(70.0, 0.0),
	Vector2(45.0, -35.0),
	Vector2(45.0, 35.0),
	Vector2(20.0, -20.0),
	Vector2(20.0, 20.0),
]

@onready var players_root: Node2D = $Players
@onready var ball: CharacterBody2D = $Ball
@onready var camera: Camera2D = $Camera2D
@onready var score_label: Label = $UI/ScoreLabel
@onready var timer_label: Label = $UI/TimerLabel
@onready var hint_label: Label = $UI/HintLabel

var human_player: CharacterBody2D
var home_team: Dictionary
var away_team: Dictionary
var match_timer := HALF_DURATION
var current_half := 1
var is_running := true
var match_finished := false


func _ready() -> void:
	home_team = GameManager.get_home_team()
	away_team = GameManager.get_away_team()
	add_child(FIELD_SCENE.instantiate())
	_spawn_teams()
	ball.reset_to(Vector2.ZERO)
	_update_hud()


func _spawn_teams() -> void:
	_create_team(0, HOME_FORMATION, GameManager.get_team_color(home_team), true)
	_create_team(1, AWAY_FORMATION, GameManager.get_team_color(away_team), false)


func _create_team(team_id: int, formation: Array, color: Color, human_on_team: bool) -> void:
	for index in formation.size():
		var player: CharacterBody2D = PLAYER_SCENE.instantiate()
		player.name = "%s_%d" % ["Home" if team_id == 0 else "Away", index]
		player.team_id = team_id
		player.team_color = color
		player.global_position = formation[index]
		player.is_human_controlled = human_on_team and index == 1
		player.add_to_group("players")
		player.ball_kicked.connect(_on_ball_kicked)
		players_root.add_child(player)

		if player.is_human_controlled:
			human_player = player


func _physics_process(delta: float) -> void:
	if not is_running:
		return

	_update_match_timer(delta)
	_update_camera()
	_update_cpu_players()
	_handle_dribbling()
	_clamp_ball_to_field()
	_check_goals()


func _update_match_timer(delta: float) -> void:
	match_timer -= delta
	if match_timer <= 0.0:
		if current_half == 1:
			current_half = 2
			match_timer = HALF_DURATION
			_reset_half()
		else:
			is_running = false
			match_finished = true
			if GameManager.is_tournament_mode():
				hint_label.text = "FULL TIME  SPACE: results"
			else:
				hint_label.text = "FULL TIME  SPACE: results  ESC: title"
	_update_hud()


func _reset_half() -> void:
	ball.reset_to(Vector2.ZERO)
	for player in get_tree().get_nodes_in_group("players"):
		if player.has_method("recover_for_new_half"):
			player.recover_for_new_half()
	hint_label.text = "2ND HALF"


func _update_camera() -> void:
	if human_player:
		camera.global_position = human_player.global_position


func _update_cpu_players() -> void:
	for player in get_tree().get_nodes_in_group("players"):
		if player.is_human_controlled or player.is_knocked_down:
			continue

		var direction: Vector2 = player.global_position.direction_to(ball.global_position)
		if direction.length_squared() < 0.01:
			continue

		player.facing_direction = direction
		player.velocity = direction * player.MOVE_SPEED * 0.72
		player.visual.set_pose(player.visual.Pose.RUN)
		player.visual.set_facing(direction)


func _handle_dribbling() -> void:
	for player in get_tree().get_nodes_in_group("players"):
		if player.is_knocked_down:
			continue
		if player.global_position.distance_to(ball.global_position) > player.BALL_CONTROL_RADIUS:
			continue
		ball.absorb_dribble(player.get_dribble_velocity())
		ball.last_touch_by_team = player.team_id


func _on_ball_kicked(kicked_ball: Node2D, direction: Vector2, power: float) -> void:
	if kicked_ball != ball:
		return

	for candidate in get_tree().get_nodes_in_group("players"):
		if candidate.global_position.distance_to(ball.global_position) <= candidate.BALL_CONTROL_RADIUS:
			ball.kick(direction, power, candidate.team_id)
			return


func _clamp_ball_to_field() -> void:
	var bounds: Rect2 = FieldScript.get_bounds()
	var goal_h := FieldScript.get_goal_half_height()
	var pos := ball.global_position

	pos.x = clampf(pos.x, bounds.position.x + 4.0, bounds.end.x - 4.0)
	pos.y = clampf(pos.y, bounds.position.y + 4.0, bounds.end.y - 4.0)

	if pos.x <= bounds.position.x + 4.0 and absf(pos.y) <= goal_h:
		ball.global_position = pos
		return
	if pos.x >= bounds.end.x - 4.0 and absf(pos.y) <= goal_h:
		ball.global_position = pos
		return

	ball.global_position = pos


func _check_goals() -> void:
	var bounds: Rect2 = FieldScript.get_bounds()
	var goal_h := FieldScript.get_goal_half_height()
	var pos := ball.global_position

	if pos.x < bounds.position.x and absf(pos.y) <= goal_h:
		GameManager.away_score += 1
		_restart_after_goal()
	elif pos.x > bounds.end.x and absf(pos.y) <= goal_h:
		GameManager.home_score += 1
		_restart_after_goal()


func _restart_after_goal() -> void:
	ball.reset_to(Vector2.ZERO)
	for index in HOME_FORMATION.size():
		var home_player := players_root.get_node("Home_%d" % index)
		home_player.global_position = HOME_FORMATION[index]
		home_player.velocity = Vector2.ZERO
		var away_player := players_root.get_node("Away_%d" % index)
		away_player.global_position = AWAY_FORMATION[index]
		away_player.velocity = Vector2.ZERO
	_update_hud()


func _update_hud() -> void:
	var home_abbr: String = home_team.get("abbr", "HOM")
	var away_abbr: String = away_team.get("abbr", "AWY")
	score_label.text = "%s %d - %d %s" % [home_abbr, GameManager.home_score, GameManager.away_score, away_abbr]
	if not GameManager.is_tournament_mode():
		timer_label.text = "H%d  %02d:%02d" % [current_half, int(match_timer) / 60, int(match_timer) % 60]
	elif is_running:
		timer_label.text = "%s  H%d %02d:%02d" % [
			GameManager.get_current_round_name(),
			current_half,
			int(match_timer) / 60,
			int(match_timer) % 60,
		]


func _input(event: InputEvent) -> void:
	if match_finished and event.is_action_pressed("start"):
		get_viewport().set_input_as_handled()
		GameManager.go_to_match_result()
		return

	if event.is_action_pressed("ui_cancel") and not match_finished:
		GameManager.go_to_title()
