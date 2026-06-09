extends Area2D
class_name MatchBall

@export var friction: float = 220.0
@export var max_speed: float = 340.0
@export var pickup_radius: float = 14.0

var velocity: Vector2 = Vector2.ZERO
var carrier: Player = null
var is_loose: bool = true


func _ready() -> void:
	Game.register_ball(self)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if carrier != null:
		global_position = carrier.get_ball_anchor()
		velocity = Vector2.ZERO
		return

	if velocity.length() > 0.0:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		global_position += velocity * delta
		global_position = Game.clamp_to_field(global_position)
		_check_goal()


func kick(direction: Vector2, power: float) -> void:
	carrier = null
	is_loose = true
	var dir := direction.normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.UP
	velocity = dir * power
	velocity = velocity.limit_length(max_speed)


func try_give_to(player: Player) -> bool:
	if carrier != null:
		return false
	if global_position.distance_to(player.global_position) > pickup_radius:
		return false
	carrier = player
	is_loose = false
	player.receive_ball(self)
	return true


func release_from(player: Player) -> void:
	if carrier == player:
		carrier = null
		is_loose = true


func _on_body_entered(body: Node2D) -> void:
	if body is Player and carrier == null:
		body.try_claim_ball(self)


func _check_goal() -> void:
	for team in [Game.Team.HOME, Game.Team.AWAY]:
		var goal := Game.goal_rect_for_team(team)
		if goal.has_point(global_position):
			Game.add_goal(team)
			_reset_after_goal()
			return


func _reset_after_goal() -> void:
	velocity = Vector2.ZERO
	carrier = null
	is_loose = true
	global_position = Game.FIELD_RECT.get_center()
