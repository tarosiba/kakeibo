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
var kickoff_position := Vector2(-12.0, 0.0)


func _ready() -> void:
	home_team = GameManager.get_home_team()
	away_team = GameManager.get_away_team()

	var field := FIELD_SCENE.instantiate()
	field.z_index = -10
	add_child(field)
	move_child(field, 0)

	players_root.z_index = 1
	ball.z_index = 2

	_spawn_teams()
	_reset_kickoff()

	if human_player:
		camera.global_position = human_player.global_position
	camera.make_current()
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
		player.is_goalkeeper = index == 0
		player.global_position = formation[index]
		player.is_human_controlled = human_on_team and index == 3 and not player.is_goalkeeper
		player.set_meta("formation_anchor", formation[index])
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
	_try_goalkeeper_saves()
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
	_reset_kickoff()
	for player in get_tree().get_nodes_in_group("players"):
		if player.has_method("recover_for_new_half"):
			player.recover_for_new_half()
	_reset_player_positions()
	hint_label.text = "2ND HALF"


func _reset_kickoff() -> void:
	ball.reset_to(kickoff_position)


func _reset_player_positions() -> void:
	for player in get_tree().get_nodes_in_group("players"):
		var anchor: Variant = player.get_meta("formation_anchor")
		if anchor is Vector2:
			player.global_position = anchor
			player.velocity = Vector2.ZERO


func _update_camera() -> void:
	if human_player:
		camera.global_position = human_player.global_position


func _update_cpu_players() -> void:
	var chasers := _pick_ball_chasers()

	for player in get_tree().get_nodes_in_group("players"):
		if player.is_human_controlled or player.is_knocked_down:
			continue

		if player.is_goalkeeper:
			_update_goalkeeper(player)
			continue

		var anchor: Vector2 = player.get_meta("formation_anchor")
		var target := anchor
		var speed_scale := 0.55

		if player == chasers.get(player.team_id):
			target = ball.global_position
			speed_scale = 0.82
		else:
			target = anchor + Vector2(0.0, clampf(ball.global_position.y - anchor.y, -18.0, 18.0) * 0.35)

		target += _get_separation_offset(player)

		var direction: Vector2 = player.global_position.direction_to(target)
		if direction.length_squared() < 0.01:
			player.velocity = Vector2.ZERO
			player.visual.set_pose(player.visual.Pose.IDLE)
			continue

		player.facing_direction = direction
		player.velocity = direction * player.MOVE_SPEED * speed_scale
		player.visual.set_pose(player.visual.Pose.RUN)
		player.visual.set_facing(direction)


func _update_goalkeeper(gk: CharacterBody2D) -> void:
	var anchor: Vector2 = gk.get_meta("formation_anchor")
	var box: Rect2 = FieldScript.get_penalty_box(gk.team_id)
	var goal_h := FieldScript.get_goal_half_height()
	var target_y := clampf(ball.global_position.y, -goal_h + 3.0, goal_h - 3.0)
	var target_x := anchor.x

	if gk.team_id == 0:
		target_x = clampf(anchor.x + clampf(ball.global_position.x - anchor.x, -8.0, 18.0), box.position.x + 6.0, box.end.x - 6.0)
		gk.facing_direction = Vector2.RIGHT
	else:
		target_x = clampf(anchor.x + clampf(ball.global_position.x - anchor.x, -18.0, 8.0), box.position.x + 6.0, box.end.x - 6.0)
		gk.facing_direction = Vector2.LEFT

	var target := Vector2(target_x, target_y)

	if gk.global_position.distance_to(ball.global_position) <= gk.BALL_CONTROL_RADIUS and box.has_point(ball.global_position):
		var clear_dir := Vector2.RIGHT if gk.team_id == 0 else Vector2.LEFT
		ball.kick(clear_dir, 95.0, gk.team_id)
		gk.visual.trigger_kick()
		return

	var direction: Vector2 = gk.global_position.direction_to(target)
	if direction.length_squared() < 0.01:
		gk.velocity = Vector2.ZERO
		gk.visual.set_gk_idle()
		gk.visual.set_facing(gk.facing_direction)
		return

	gk.velocity = direction * gk.MOVE_SPEED * 0.68
	if absf(direction.x) > 0.05:
		gk.facing_direction = direction
	gk.visual.set_pose(gk.visual.Pose.RUN)
	gk.visual.set_facing(gk.facing_direction)


func _try_goalkeeper_saves() -> void:
	if ball.velocity.length() < 35.0:
		return

	for gk in get_tree().get_nodes_in_group("players"):
		if not gk.is_goalkeeper or gk.is_knocked_down:
			continue
		if not _ball_threatens_goal(gk.team_id):
			continue
		if gk.global_position.distance_to(ball.global_position) > 13.0:
			continue
		if absf(gk.global_position.y - ball.global_position.y) > goal_save_max_offset():
			continue

		var block_dir := Vector2.RIGHT if gk.team_id == 0 else Vector2.LEFT
		ball.velocity = block_dir * 55.0 + Vector2(0.0, (gk.global_position.y - ball.global_position.y) * -1.5)
		ball.global_position += block_dir * 2.5
		gk.visual.trigger_save()


func goal_save_max_offset() -> float:
	return FieldScript.get_goal_half_height() - 2.0


func _ball_threatens_goal(defending_team_id: int) -> bool:
	var goal_x := FieldScript.get_goal_line_x(defending_team_id)
	var goal_h := FieldScript.get_goal_half_height()
	var ball_pos := ball.global_position
	var ball_vel := ball.velocity

	if absf(ball_pos.y) > goal_h + 6.0:
		return false

	if defending_team_id == 0:
		return ball_vel.x < -25.0 and ball_pos.x < -35.0
	return ball_vel.x > 25.0 and ball_pos.x > 35.0


func _pick_ball_chasers() -> Dictionary:
	var chasers: Dictionary = {}
	for team_id in [0, 1]:
		var closest_player: CharacterBody2D = null
		var closest_distance := INF
		for player in get_tree().get_nodes_in_group("players"):
			if player.team_id != team_id or player.is_knocked_down or player.is_goalkeeper:
				continue
			var distance: float = player.global_position.distance_to(ball.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_player = player
		chasers[team_id] = closest_player
	return chasers


func _get_separation_offset(player: CharacterBody2D) -> Vector2:
	var offset := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("players"):
		if other == player or other.is_knocked_down:
			continue
		var delta: Vector2 = player.global_position - other.global_position
		var distance: float = delta.length()
		if distance > 0.01 and distance < 14.0:
			offset += delta.normalized() * (14.0 - distance) * 0.35
	return offset


func _get_ball_controller() -> CharacterBody2D:
	var closest_player: CharacterBody2D = null
	var closest_distance := INF

	for player in get_tree().get_nodes_in_group("players"):
		if player.is_knocked_down:
			continue
		if player.is_goalkeeper and not _goalkeeper_can_control_ball(player):
			continue
		var distance: float = player.global_position.distance_to(ball.global_position)
		if distance > player.BALL_CONTROL_RADIUS:
			continue
		if player.is_human_controlled:
			return player
		if distance < closest_distance:
			closest_player = player
			closest_distance = distance

	return closest_player


func _goalkeeper_can_control_ball(gk: CharacterBody2D) -> bool:
	var box: Rect2 = FieldScript.get_penalty_box(gk.team_id)
	return box.has_point(ball.global_position) or box.has_point(gk.global_position)


func _handle_dribbling() -> void:
	var controller := _get_ball_controller()
	if controller == null:
		return
	ball.absorb_dribble(controller.get_dribble_velocity())
	ball.last_touch_by_team = controller.team_id


func _on_ball_kicked(kicked_ball: Node2D, direction: Vector2, power: float) -> void:
	if kicked_ball != ball:
		return

	var kicker := _get_kick_candidate()
	if kicker == null:
		return
	ball.kick(direction, power, kicker.team_id)


func _get_kick_candidate() -> CharacterBody2D:
	for player in get_tree().get_nodes_in_group("players"):
		if player.is_knocked_down or not player.is_human_controlled:
			continue
		if player.global_position.distance_to(ball.global_position) <= player.BALL_CONTROL_RADIUS:
			return player

	for player in get_tree().get_nodes_in_group("players"):
		if player.is_knocked_down or player.is_goalkeeper:
			continue
		if player.global_position.distance_to(ball.global_position) <= player.BALL_CONTROL_RADIUS:
			return player

	return null


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
	_reset_kickoff()
	_reset_player_positions()
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
