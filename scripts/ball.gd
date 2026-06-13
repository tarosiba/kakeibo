extends CharacterBody2D

const MAX_SPEED := 360.0
const FRICTION := 520.0
const MIN_SPEED := 8.0
const BALL_TEXTURE: Texture2D = preload("res://assets/sprites/ball.png")

var last_touch_by_team: int = -1
var kick_lock_time: float = 0.0
var is_stuck_to_player: bool = false
var dribble_controller: CharacterBody2D = null
var dribble_offset: Vector2 = Vector2(6, 0)


func _ready() -> void:
	z_index = 2
	process_physics_priority = 20
	add_to_group("ball")
	collision_layer = 2
	collision_mask = 5

	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = BALL_TEXTURE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = true
	add_child(sprite)


func _physics_process(delta: float) -> void:
	if kick_lock_time > 0.0:
		kick_lock_time = maxf(0.0, kick_lock_time - delta)

	if is_stuck_to_player and dribble_controller != null and is_instance_valid(dribble_controller):
		global_position = dribble_controller.global_position + dribble_offset
		velocity = dribble_controller.velocity
		last_touch_by_team = dribble_controller.team_id
		return

	is_stuck_to_player = false
	dribble_controller = null

	if velocity.length() > MIN_SPEED:
		var drop := FRICTION * delta
		if velocity.length() <= drop:
			velocity = Vector2.ZERO
		else:
			velocity = velocity.move_toward(Vector2.ZERO, drop)
	else:
		velocity = Vector2.ZERO

	move_and_slide()


func stick_to_player(player_node: CharacterBody2D, team_id: int, offset: Vector2) -> void:
	dribble_controller = player_node
	dribble_offset = offset
	last_touch_by_team = team_id
	is_stuck_to_player = true
	velocity = player_node.velocity


func release_from_player() -> void:
	is_stuck_to_player = false
	dribble_controller = null


func kick(direction: Vector2, power: float, team_id: int) -> void:
	release_from_player()
	var dir := direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT
	global_position += dir * 3.0
	velocity = dir * clampf(power, 80.0, MAX_SPEED)
	last_touch_by_team = team_id
	kick_lock_time = 0.25


func release_to_tackle(tackler: CharacterBody2D) -> void:
	var steal_dir: Vector2 = tackler.facing_direction.normalized()
	if steal_dir.length_squared() < 0.01:
		steal_dir = Vector2.RIGHT if tackler.team_id == 0 else Vector2.LEFT
	release_from_player()
	last_touch_by_team = tackler.team_id
	global_position = tackler.global_position + steal_dir * 4.0
	velocity = steal_dir * 35.0
	kick_lock_time = 0.12


func reset_to(position: Vector2) -> void:
	global_position = position
	velocity = Vector2.ZERO
	release_from_player()
	kick_lock_time = 0.0
	last_touch_by_team = -1


func is_kick_locked() -> bool:
	return kick_lock_time > 0.0
