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
var active_controller: CharacterBody2D = null

const ATTACK_PUSH := 30.0
const SUPPORT_SPREAD := 24.0
const PRESS_RADIUS := 13.0
const LOOSE_BALL_CHASE_RANGE := 95.0
const POSSESSION_RADIUS := 16.0
const POSSESSION_RELEASE_RADIUS := 24.0


func _ready() -> void:
	process_physics_priority = 10
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
	var controller := _get_ball_controller()
	var possession_team: int = _get_possession_team(controller)

	for player in get_tree().get_nodes_in_group("players"):
		if player.is_human_controlled or player.is_knocked_down:
			continue

		if player.is_goalkeeper:
			_update_goalkeeper(player)
			continue

		if controller == player:
			_update_cpu_carrier(player)
		elif possession_team == player.team_id:
			_update_cpu_support(player, controller)
		elif possession_team >= 0:
			_update_cpu_defender(player, controller)
		else:
			_update_cpu_loose(player)


func _get_possession_team(controller: CharacterBody2D) -> int:
	if controller != null:
		return controller.team_id
	if ball.last_touch_by_team >= 0 and ball.velocity.length() < 55.0:
		return ball.last_touch_by_team
	return -1


func _attack_direction(team_id: int) -> float:
	return 1.0 if team_id == 0 else -1.0


func _enemy_goal_x(team_id: int) -> float:
	return FieldScript.get_goal_line_x(1 if team_id == 0 else 0)


func _update_cpu_carrier(carrier: CharacterBody2D) -> void:
	var attack_dir := _attack_direction(carrier.team_id)
	var goal_x := _enemy_goal_x(carrier.team_id)
	var move_dir := Vector2(attack_dir, clampf(ball.global_position.y - carrier.global_position.y, -1.0, 1.0) * 0.35).normalized()

	if _is_pressured(carrier):
		var pass_target := _find_best_pass_target(carrier)
		if pass_target != null:
			var pass_dir := carrier.global_position.direction_to(pass_target.global_position)
			if carrier.cpu_try_pass(pass_dir):
				return
	elif _should_pass_forward(carrier):
		var pass_target := _find_best_pass_target(carrier)
		if pass_target != null:
			var pass_dir := carrier.global_position.direction_to(pass_target.global_position)
			if carrier.cpu_try_pass(pass_dir):
				return

	if absf(goal_x - carrier.global_position.x) < 38.0 and absf(carrier.global_position.y) < FieldScript.get_goal_half_height() + 6.0:
		var shoot_dir := Vector2(attack_dir, (0.0 - carrier.global_position.y) * 0.08).normalized()
		ball.kick(shoot_dir, carrier.KICK_POWER, carrier.team_id)
		carrier.visual.trigger_kick()
		carrier.cpu_pass_cooldown = 0.6
		return

	_move_cpu_player(carrier, carrier.global_position + move_dir * 16.0, 0.62)


func _update_cpu_support(supporter: CharacterBody2D, controller: CharacterBody2D) -> void:
	var anchor: Vector2 = supporter.get_meta("formation_anchor")
	var attack_dir := _attack_direction(supporter.team_id)
	var ball_pos := ball.global_position if controller else anchor
	var lane_offset := anchor.y - ball_pos.y

	var target := Vector2(
		ball_pos.x + attack_dir * ATTACK_PUSH,
		ball_pos.y + clampf(lane_offset, -SUPPORT_SPREAD, SUPPORT_SPREAD)
	)
	target.x = lerpf(anchor.x, target.x, 0.75)
	target.y = clampf(target.y, -70.0, 70.0)

	if target.distance_to(ball_pos) < 18.0:
		target += Vector2(0.0, signf(lane_offset + 0.01) * 14.0)

	_move_cpu_player(supporter, target, 0.78)


func _update_cpu_defender(defender: CharacterBody2D, controller: CharacterBody2D) -> void:
	var anchor: Vector2 = defender.get_meta("formation_anchor")
	var presser := _get_team_presser(defender.team_id)

	if defender == presser and controller != null:
		var to_ball := defender.global_position.direction_to(ball.global_position)
		var distance := defender.global_position.distance_to(ball.global_position)
		var target := ball.global_position
		if distance < PRESS_RADIUS:
			var tangent := Vector2(-to_ball.y, to_ball.x)
			target = ball.global_position + tangent * 10.0
		_move_cpu_player(defender, target, 0.84)
		return

	var guard_x := lerpf(anchor.x, ball.global_position.x, 0.45)
	var guard_y := lerpf(anchor.y, ball.global_position.y, 0.55)
	var target := Vector2(guard_x, guard_y)
	_move_cpu_player(defender, target, 0.62)


func _update_cpu_loose(player: CharacterBody2D) -> void:
	var chaser: CharacterBody2D = _pick_ball_chasers().get(player.team_id)
	if player != chaser:
		var anchor: Vector2 = player.get_meta("formation_anchor")
		var target := anchor + Vector2(0.0, clampf(ball.global_position.y - anchor.y, -16.0, 16.0) * 0.4)
		_move_cpu_player(player, target, 0.5)
		return

	if player.global_position.distance_to(ball.global_position) > LOOSE_BALL_CHASE_RANGE:
		var anchor: Vector2 = player.get_meta("formation_anchor")
		_move_cpu_player(player, anchor, 0.45)
		return

	_move_cpu_player(player, ball.global_position, 0.8)


func _move_cpu_player(player: CharacterBody2D, target: Vector2, speed_scale: float) -> void:
	target += _get_separation_offset(player)
	var direction: Vector2 = player.global_position.direction_to(target)
	if direction.length_squared() < 0.01:
		player.velocity = Vector2.ZERO
		player.visual.set_pose(player.visual.Pose.IDLE)
		return

	player.facing_direction = direction
	player.velocity = direction * player.MOVE_SPEED * speed_scale
	player.visual.set_pose(player.visual.Pose.RUN)
	player.visual.set_facing(direction)


func _is_pressured(player: CharacterBody2D) -> bool:
	for other in get_tree().get_nodes_in_group("players"):
		if other.team_id == player.team_id or other.is_goalkeeper or other.is_knocked_down:
			continue
		if player.global_position.distance_to(other.global_position) < 16.0:
			return true
	return false


func _should_pass_forward(carrier: CharacterBody2D) -> bool:
	var target := _find_best_pass_target(carrier)
	if target == null:
		return false
	var attack_dir := _attack_direction(carrier.team_id)
	return (target.global_position.x - carrier.global_position.x) * attack_dir > 18.0


func _find_best_pass_target(carrier: CharacterBody2D) -> CharacterBody2D:
	var attack_dir := _attack_direction(carrier.team_id)
	var best_player: CharacterBody2D = null
	var best_score: float = -INF

	for teammate in get_tree().get_nodes_in_group("players"):
		if teammate == carrier or teammate.team_id != carrier.team_id or teammate.is_goalkeeper:
			continue
		if carrier.global_position.distance_to(teammate.global_position) < 16.0:
			continue
		var advance: float = (teammate.global_position.x - carrier.global_position.x) * attack_dir
		if advance < -8.0:
			continue
		if not _is_pass_lane_open(carrier, teammate):
			continue
		var openness := _get_teammate_openness(teammate)
		var score: float = advance * 1.2 + openness * 18.0 - carrier.global_position.distance_to(teammate.global_position) * 0.08
		if score > best_score:
			best_score = score
			best_player = teammate

	return best_player


func _is_pass_lane_open(from_player: CharacterBody2D, to_player: CharacterBody2D) -> bool:
	for enemy in get_tree().get_nodes_in_group("players"):
		if enemy.team_id == from_player.team_id or enemy.is_goalkeeper or enemy.is_knocked_down:
			continue
		if _distance_to_segment(enemy.global_position, from_player.global_position, to_player.global_position) < 9.0:
			return false
	return true


func _get_teammate_openness(teammate: CharacterBody2D) -> float:
	var closest_enemy: float = INF
	for enemy in get_tree().get_nodes_in_group("players"):
		if enemy.team_id == teammate.team_id or enemy.is_goalkeeper or enemy.is_knocked_down:
			continue
		closest_enemy = minf(closest_enemy, teammate.global_position.distance_to(enemy.global_position))
	return closest_enemy


func _distance_to_segment(point: Vector2, seg_a: Vector2, seg_b: Vector2) -> float:
	var segment := seg_b - seg_a
	var length_sq := segment.length_squared()
	if length_sq < 0.01:
		return point.distance_to(seg_a)
	var t := clampf((point - seg_a).dot(segment) / length_sq, 0.0, 1.0)
	return point.distance_to(seg_a + segment * t)


func _get_team_presser(team_id: int) -> CharacterBody2D:
	var closest_player: CharacterBody2D = null
	var closest_distance := INF
	for player in get_tree().get_nodes_in_group("players"):
		if player.team_id != team_id or player.is_goalkeeper or player.is_knocked_down:
			continue
		var distance: float = player.global_position.distance_to(ball.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_player = player
	return closest_player


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
	if human_player != null and not human_player.is_knocked_down:
		var human_distance: float = human_player.global_position.distance_to(ball.global_position)
		if human_distance <= POSSESSION_RADIUS:
			return human_player
		if active_controller == human_player and human_distance <= POSSESSION_RELEASE_RADIUS:
			return human_player

	var candidates: Array[CharacterBody2D] = []

	for player in get_tree().get_nodes_in_group("players"):
		if player.is_knocked_down or player.is_human_controlled:
			continue
		if player.is_goalkeeper and not _goalkeeper_can_control_ball(player):
			continue
		var distance: float = player.global_position.distance_to(ball.global_position)
		if distance > player.BALL_CONTROL_RADIUS:
			continue
		candidates.append(player)

	if candidates.is_empty():
		return null

	if ball.last_touch_by_team >= 0:
		for player in candidates:
			if player.team_id == ball.last_touch_by_team:
				return player

	var closest_player: CharacterBody2D = candidates[0]
	var closest_distance: float = closest_player.global_position.distance_to(ball.global_position)
	for player in candidates:
		var distance: float = player.global_position.distance_to(ball.global_position)
		if distance < closest_distance:
			closest_player = player
			closest_distance = distance
	return closest_player


func _goalkeeper_can_control_ball(gk: CharacterBody2D) -> bool:
	var box: Rect2 = FieldScript.get_penalty_box(gk.team_id)
	return box.has_point(ball.global_position) or box.has_point(gk.global_position)


func _handle_dribbling() -> void:
	if ball.is_kick_locked():
		ball.release_from_player()
		active_controller = null
		return

	var controller := _get_ball_controller()
	if controller == null:
		ball.release_from_player()
		active_controller = null
		return

	active_controller = controller

	var facing: Vector2 = controller.facing_direction.normalized()
	if facing.length_squared() < 0.01:
		facing = Vector2.RIGHT if controller.team_id == 0 else Vector2.LEFT

	ball.stick_to_player(controller, controller.team_id, facing * 6.0)


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
