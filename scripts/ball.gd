extends CharacterBody2D

const FRICTION := 7.5
const MAX_SPEED := 190.0
const BOUNCE := 0.72
const BALL_TEXTURE: Texture2D = preload("res://assets/sprites/ball.png")

var last_touch_by_team: int = -1
var control_lock_time := 0.0


func _ready() -> void:
	z_index = 2
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
	if control_lock_time > 0.0:
		control_lock_time -= delta

	if not is_dribble_attached():
		velocity = velocity.lerp(Vector2.ZERO, FRICTION * delta)

	if velocity.length() > MAX_SPEED:
		velocity = velocity.normalized() * MAX_SPEED
	move_and_slide()

	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		velocity = velocity.bounce(collision.get_normal()) * BOUNCE


func is_dribble_attached() -> bool:
	return control_lock_time > 0.0 and velocity.length() < 120.0


func can_dribble_attach() -> bool:
	return control_lock_time <= 0.0


func attach_dribble(target_position: Vector2, target_velocity: Vector2) -> void:
	global_position = target_position
	velocity = target_velocity
	control_lock_time = 0.05


func kick(direction: Vector2, power: float, team_id: int) -> void:
	var kick_dir := direction.normalized()
	if kick_dir.length_squared() < 0.01:
		kick_dir = Vector2.RIGHT
	global_position += kick_dir * 3.0
	velocity = kick_dir * power
	last_touch_by_team = team_id
	control_lock_time = 0.28


func release_to_tackle(tackler: CharacterBody2D) -> void:
	var steal_dir: Vector2 = tackler.facing_direction.normalized()
	if steal_dir.length_squared() < 0.01:
		steal_dir = Vector2.RIGHT if tackler.team_id == 0 else Vector2.LEFT
	last_touch_by_team = tackler.team_id
	global_position = tackler.global_position + steal_dir * 4.0
	velocity = steal_dir * 35.0
	control_lock_time = 0.12


func reset_to(position: Vector2) -> void:
	global_position = position
	velocity = Vector2.ZERO
	control_lock_time = 0.0
