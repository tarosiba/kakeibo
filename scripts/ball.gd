extends CharacterBody2D

const FRICTION := 7.5
const MAX_SPEED := 190.0
const BOUNCE := 0.72
const BALL_TEXTURE: Texture2D = preload("res://assets/sprites/ball.png")

var last_touch_by_team: int = -1


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
	velocity = velocity.lerp(Vector2.ZERO, FRICTION * delta)
	if velocity.length() > MAX_SPEED:
		velocity = velocity.normalized() * MAX_SPEED
	move_and_slide()

	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		velocity = velocity.bounce(collision.get_normal()) * BOUNCE


func kick(direction: Vector2, power: float, team_id: int) -> void:
	var kick_dir := direction.normalized()
	if kick_dir.length_squared() < 0.01:
		kick_dir = Vector2.RIGHT
	velocity = kick_dir * power
	last_touch_by_team = team_id


func absorb_dribble(dribble_velocity: Vector2) -> void:
	if dribble_velocity.length_squared() < 1.0:
		return
	velocity = velocity.lerp(dribble_velocity, 0.35)


func reset_to(position: Vector2) -> void:
	global_position = position
	velocity = Vector2.ZERO
