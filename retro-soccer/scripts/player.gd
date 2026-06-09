extends CharacterBody2D
class_name Player

@export var team: Game.Team = Game.Team.HOME
@export var is_human: bool = false
@export var move_speed: float = 110.0
@export var sprint_multiplier: float = 1.25
@export var home_position: Vector2 = Vector2.ZERO

var held_ball: MatchBall = null
var _ai_target: Vector2 = Vector2.ZERO
var _ai_retarget_timer: float = 0.0

@onready var sprite: ColorRect = $Sprite
@onready var shadow: ColorRect = $Shadow


func _ready() -> void:
	_update_team_color()
	_ai_target = global_position


func _physics_process(delta: float) -> void:
	var input_dir := _get_move_input()
	if not is_human:
		input_dir = _get_ai_direction(delta)

	if input_dir != Vector2.ZERO:
		var speed := move_speed
		if is_human and held_ball == null and Input.is_action_pressed("shoot"):
			speed *= sprint_multiplier
		velocity = input_dir.normalized() * speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 480.0 * delta)

	move_and_slide()
	global_position = Game.clamp_to_field(global_position)
	_apply_depth_scale()

	if held_ball == null and Game.ball is MatchBall:
		var loose_ball := Game.ball as MatchBall
		if loose_ball.carrier == null:
			try_claim_ball(loose_ball)

	if is_human:
		_handle_human_actions()


func get_ball_anchor() -> Vector2:
	var facing := velocity.normalized()
	if facing == Vector2.ZERO:
		facing = Vector2.UP if team == Game.Team.HOME else Vector2.DOWN
	return global_position + facing * 10.0


func receive_ball(ball: MatchBall) -> void:
	held_ball = ball


func try_claim_ball(ball: MatchBall) -> void:
	if held_ball != null:
		return
	if ball.try_give_to(self):
		held_ball = ball


func pass_ball() -> void:
	if held_ball == null:
		return
	var target := _find_pass_target()
	var dir := (target.global_position - global_position)
	held_ball.release_from(self)
	held_ball.kick(dir, 220.0)
	held_ball = null


func shoot_ball() -> void:
	if held_ball == null:
		return
	var goal_y := Game.FIELD_RECT.position.y if team == Game.Team.HOME else Game.FIELD_RECT.end.y
	var goal_x := Game.FIELD_RECT.position.x + Game.FIELD_RECT.size.x * 0.5
	var dir := Vector2(goal_x, goal_y) - global_position
	held_ball.release_from(self)
	held_ball.kick(dir, 300.0)
	held_ball = null


func _get_move_input() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func _handle_human_actions() -> void:
	if Input.is_action_just_pressed("pass"):
		pass_ball()
	elif Input.is_action_just_pressed("shoot") and held_ball != null:
		shoot_ball()


func _get_ai_direction(delta: float) -> Vector2:
	_ai_retarget_timer -= delta
	if _ai_retarget_timer <= 0.0:
		_ai_retarget_timer = 0.35
		_ai_target = _choose_ai_target()

	return (_ai_target - global_position).normalized()


func _choose_ai_target() -> Vector2:
	var ball := Game.ball as MatchBall
	if ball == null:
		return home_position

	if held_ball != null:
		return _get_attack_target()

	if ball.carrier != null:
		if ball.carrier.team == team:
			return home_position + (ball.carrier.global_position - home_position) * 0.35
		return ball.global_position

	if ball.is_loose:
		return ball.global_position

	return home_position


func _get_attack_target() -> Vector2:
	var goal_y := Game.FIELD_RECT.position.y if team == Game.Team.HOME else Game.FIELD_RECT.end.y
	var goal_x := Game.FIELD_RECT.position.x + Game.FIELD_RECT.size.x * 0.5
	return Vector2(goal_x, goal_y)


func _find_pass_target() -> Player:
	var best: Player = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("players"):
		var p := node as Player
		if p == null or p == self or p.team != team:
			continue
		var d := global_position.distance_squared_to(p.global_position)
		if d < best_dist:
			best_dist = d
			best = p
	return best if best != null else self


func _apply_depth_scale() -> void:
	var s := Game.depth_scale(global_position.y)
	sprite.scale = Vector2(s, s)
	shadow.scale = Vector2(s, s)
	z_index = int(global_position.y)


func _update_team_color() -> void:
	var color := Color(0.25, 0.55, 1.0) if team == Game.Team.HOME else Color(1.0, 0.35, 0.35)
	sprite.color = color
