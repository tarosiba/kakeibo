extends CharacterBody2D

signal ball_kicked(ball: Node2D, direction: Vector2, power: float)

const MOVE_SPEED := 68.0
const DRIBBLE_SPEED := 58.0
const KICK_POWER := 145.0
const PASS_POWER := 95.0
const TACKLE_SPEED := 110.0
const BALL_CONTROL_RADIUS := 9.0
const KNOCKDOWN_DURATION := 1.8
const TACKLE_REACH := 16.0

@export var team_id: int = 0
@export var is_human_controlled: bool = false
@export var is_goalkeeper: bool = false
@export var team_color: Color = Color("#2563eb")

@onready var visual: Node2D = $Visual
@onready var kick_origin: Marker2D = $KickOrigin

var facing_direction := Vector2.RIGHT
var is_knocked_down := false
var knockdown_timer := 0.0
var tackle_cooldown := 0.0
var super_shots_left := 5
var cpu_pass_cooldown := 0.0


func _ready() -> void:
	z_index = 1
	visual.set_team_color(team_color)
	if visual.has_method("set_goalkeeper"):
		visual.set_goalkeeper(is_goalkeeper)
	collision_layer = 1
	collision_mask = 5


func _physics_process(delta: float) -> void:
	if is_knocked_down:
		knockdown_timer -= delta
		velocity = velocity.lerp(Vector2.ZERO, 8.0 * delta)
		move_and_slide()
		if knockdown_timer <= 0.0:
			is_knocked_down = false
			if visual.has_method("recover_from_knockdown"):
				visual.recover_from_knockdown()
		return

	if tackle_cooldown > 0.0:
		tackle_cooldown -= delta
	if cpu_pass_cooldown > 0.0:
		cpu_pass_cooldown -= delta

	var input_dir := _get_input_direction()
	if input_dir.length_squared() > 0.01:
		facing_direction = input_dir.normalized()
		velocity = input_dir.normalized() * MOVE_SPEED
		if visual.has_method("set_pose"):
			visual.set_pose(visual.Pose.RUN)
	elif is_human_controlled:
		velocity = velocity.lerp(Vector2.ZERO, 10.0 * delta)
		if visual.has_method("set_pose") and visual.pose != visual.Pose.KICK:
			visual.set_pose(visual.Pose.IDLE)

	if visual.has_method("set_facing"):
		visual.set_facing(facing_direction)

	if is_human_controlled:
		_handle_human_actions()

	move_and_slide()


func _get_input_direction() -> Vector2:
	if not is_human_controlled:
		return Vector2.ZERO

	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func _handle_human_actions() -> void:
	if Input.is_action_just_pressed("pass") and Input.is_action_pressed("shoot"):
		_try_super_shot()
	elif Input.is_action_just_pressed("pass"):
		_try_pass()
	elif Input.is_action_just_pressed("shoot"):
		_try_tackle_or_shoot(false)


func _try_pass() -> void:
	var ball := _find_nearby_ball()
	if ball == null:
		return
	var pass_dir := _get_pass_direction()
	if visual.has_method("trigger_kick"):
		visual.trigger_kick()
	ball_kicked.emit(ball, pass_dir, PASS_POWER)


func _get_pass_direction() -> Vector2:
	var best_teammate: CharacterBody2D = null
	var best_score := -INF
	for player in get_tree().get_nodes_in_group("players"):
		if player == self or player.team_id != team_id or player.is_goalkeeper:
			continue
		var to_teammate: Vector2 = global_position.direction_to(player.global_position)
		var alignment := to_teammate.dot(facing_direction.normalized())
		if alignment < -0.35:
			continue
		var distance := global_position.distance_to(player.global_position)
		if distance < 14.0 or distance > 90.0:
			continue
		var score := alignment * 40.0 - distance * 0.12
		if score > best_score:
			best_score = score
			best_teammate = player
	if best_teammate != null:
		return global_position.direction_to(best_teammate.global_position)
	return facing_direction


func cpu_try_pass(direction: Vector2) -> bool:
	if cpu_pass_cooldown > 0.0:
		return false
	var ball := _find_nearby_ball()
	if ball == null:
		return false
	if visual.has_method("trigger_kick"):
		visual.trigger_kick()
	ball_kicked.emit(ball, direction, PASS_POWER)
	cpu_pass_cooldown = 0.75
	return true


func _try_tackle_or_shoot(_super: bool) -> void:
	var ball := _find_nearby_ball()
	if ball != null and _can_shoot_ball(ball):
		if visual.has_method("trigger_kick"):
			visual.trigger_kick()
		ball_kicked.emit(ball, facing_direction, KICK_POWER)
		return

	_perform_tackle()


func _can_shoot_ball(ball: Node2D) -> bool:
	return ball.last_touch_by_team == team_id or ball.last_touch_by_team < 0


func _perform_tackle() -> void:
	if tackle_cooldown > 0.0:
		return

	if visual.has_method("set_pose"):
		visual.set_pose(visual.Pose.TACKLE)
		visual.kick_progress = 0.0

	velocity = facing_direction * TACKLE_SPEED
	tackle_cooldown = 0.45
	_apply_tackle_hit()


func _try_super_shot() -> void:
	if super_shots_left <= 0:
		_try_tackle_or_shoot(false)
		return

	var ball := _find_nearby_ball()
	if ball == null or not _can_shoot_ball(ball):
		return

	super_shots_left -= 1
	if visual.has_method("trigger_kick"):
		visual.trigger_kick()
	ball_kicked.emit(ball, facing_direction, KICK_POWER * 1.8)


func _find_nearby_ball() -> Node2D:
	for ball in get_tree().get_nodes_in_group("ball"):
		if global_position.distance_to(ball.global_position) <= BALL_CONTROL_RADIUS:
			return ball
	return null


func _apply_tackle_hit() -> void:
	for opponent in get_tree().get_nodes_in_group("players"):
		if opponent == self or opponent.team_id == team_id or opponent.is_goalkeeper:
			continue
		if global_position.distance_to(opponent.global_position) > TACKLE_REACH:
			continue
		if _attempt_ball_steal(opponent):
			return
		if opponent.has_method("receive_tackle"):
			opponent.receive_tackle(facing_direction)


func _attempt_ball_steal(opponent: CharacterBody2D) -> bool:
	for ball_node in get_tree().get_nodes_in_group("ball"):
		if opponent.global_position.distance_to(ball_node.global_position) > opponent.BALL_CONTROL_RADIUS + 2.0:
			continue
		if ball_node.last_touch_by_team != opponent.team_id:
			continue
		if ball_node.has_method("release_to_tackle"):
			ball_node.release_to_tackle(self)
		opponent.receive_tackle(facing_direction)
		return true
	return false


func receive_tackle(from_direction: Vector2) -> void:
	if is_goalkeeper:
		return
	if is_knocked_down:
		return
	is_knocked_down = true
	knockdown_timer = KNOCKDOWN_DURATION
	velocity = from_direction * 40.0
	if visual.has_method("set_knocked_down"):
		visual.set_knocked_down()


func recover_for_new_half() -> void:
	is_knocked_down = false
	knockdown_timer = 0.0
	super_shots_left = 5
	if visual.has_method("recover_from_knockdown"):
		visual.recover_from_knockdown()


func get_dribble_velocity() -> Vector2:
	if is_knocked_down:
		return Vector2.ZERO
	if velocity.length_squared() < 1.0:
		return facing_direction * DRIBBLE_SPEED * 0.35
	return velocity
