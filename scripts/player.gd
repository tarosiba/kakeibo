extends CharacterBody2D

signal ball_kicked(ball: Node2D, direction: Vector2, power: float)

const MOVE_SPEED := 68.0
const DRIBBLE_SPEED := 58.0
const KICK_POWER := 145.0
const PASS_POWER := 95.0
const TACKLE_SPEED := 110.0
const BALL_CONTROL_RADIUS := 9.0

@export var team_id: int = 0
@export var is_human_controlled: bool = false
@export var team_color: Color = Color("#2563eb")

@onready var visual: Node2D = $Visual
@onready var kick_origin: Marker2D = $KickOrigin

var facing_direction := Vector2.RIGHT
var is_knocked_down := false
var knockdown_timer := 0.0
var tackle_cooldown := 0.0
var super_shots_left := 5


func _ready() -> void:
	visual.set_team_color(team_color)
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

	var input_dir := _get_input_direction()
	if input_dir.length_squared() > 0.01:
		facing_direction = input_dir.normalized()
		velocity = input_dir.normalized() * MOVE_SPEED
		if visual.has_method("set_pose"):
			visual.set_pose(visual.Pose.RUN)
	else:
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
	if visual.has_method("trigger_kick"):
		visual.trigger_kick()
	ball_kicked.emit(ball, facing_direction, PASS_POWER)


func _try_tackle_or_shoot(_super: bool) -> void:
	var ball := _find_nearby_ball()
	if ball != null:
		if visual.has_method("trigger_kick"):
			visual.trigger_kick()
		ball_kicked.emit(ball, facing_direction, KICK_POWER)
		return

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
	if ball == null:
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
	for player in get_tree().get_nodes_in_group("players"):
		if player == self:
			continue
		if player.global_position.distance_to(global_position) > 14.0:
			continue
		if player.has_method("receive_tackle"):
			player.receive_tackle(facing_direction)


func receive_tackle(from_direction: Vector2) -> void:
	if is_knocked_down:
		return
	is_knocked_down = true
	knockdown_timer = 999.0
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
