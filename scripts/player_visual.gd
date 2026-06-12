extends Node2D

enum Pose { IDLE, RUN, KICK, TACKLE, DOWN }

@export var team_color: Color = Color("#2563eb")
@export var skin_color: Color = Color("#f5d0a9")

var facing: float = 1.0
var pose: Pose = Pose.IDLE
var run_phase: float = 0.0
var kick_progress: float = 0.0


func set_facing(direction: Vector2) -> void:
	if absf(direction.x) > 0.05:
		facing = signf(direction.x)


func set_pose(new_pose: Pose) -> void:
	if pose == Pose.DOWN:
		return
	if new_pose == Pose.KICK and pose != Pose.KICK:
		kick_progress = 0.0
	pose = new_pose


func trigger_kick() -> void:
	if pose == Pose.DOWN:
		return
	pose = Pose.KICK
	kick_progress = 0.0


func set_knocked_down() -> void:
	pose = Pose.DOWN
	kick_progress = 0.0
	run_phase = 0.0


func recover_from_knockdown() -> void:
	if pose == Pose.DOWN:
		pose = Pose.IDLE


func _process(delta: float) -> void:
	match pose:
		Pose.RUN:
			run_phase += delta * 14.0
		Pose.KICK:
			kick_progress += delta * 10.0
			if kick_progress >= 1.0:
				pose = Pose.IDLE
				kick_progress = 0.0
		Pose.TACKLE:
			kick_progress += delta * 8.0
			if kick_progress >= 1.0:
				pose = Pose.IDLE
				kick_progress = 0.0
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))

	var leg_swing := 0.0
	var arm_swing := 0.0
	var body_tilt := 0.0
	var head_offset := Vector2.ZERO

	match pose:
		Pose.RUN:
			leg_swing = sin(run_phase) * 0.55
			arm_swing = sin(run_phase) * 0.45
		Pose.KICK:
			leg_swing = lerpf(0.0, -1.0, minf(kick_progress * 1.4, 1.0))
			arm_swing = 0.75
			body_tilt = -0.08
			head_offset = Vector2(0.0, 0.5)
		Pose.TACKLE:
			leg_swing = 0.9
			arm_swing = 0.2
			body_tilt = 0.35
			head_offset = Vector2(1.5, 1.0)
		Pose.DOWN:
			draw_set_transform(Vector2(0.0, 4.0), PI * 0.5 * facing, Vector2(facing, 1.0))
			_draw_limb(Vector2(-2.0, 0.0), Vector2(2.0, 5.0), 0.4, team_color)
			_draw_limb(Vector2(2.0, 0.0), Vector2(2.0, 5.0), -0.2, team_color)
			draw_rect(Rect2(-4.0, -3.0, 8.0, 7.0), team_color)
			_draw_limb(Vector2(-5.0, -2.0), Vector2(2.0, 4.0), -0.8, team_color)
			_draw_limb(Vector2(5.0, -2.0), Vector2(2.0, 4.0), 0.5, team_color)
			draw_circle(Vector2(0.0, -7.0), 3.0, skin_color)
			draw_circle(Vector2(1.0, -8.0), 1.0, Color.BLACK)
			draw_circle(Vector2(-4.0, -9.0), 1.2, Color("#facc15"))
			return

	_draw_limb(Vector2(-2.0, 4.0), Vector2(2.0, 5.0), leg_swing + 0.15, team_color)
	_draw_limb(Vector2(2.0, 4.0), Vector2(2.0, 5.0), -leg_swing - 0.15, team_color)

	draw_set_transform(Vector2.ZERO, body_tilt, Vector2(facing, 1.0))
	draw_rect(Rect2(-4.0, -2.0, 8.0, 7.0), team_color)
	_draw_limb(Vector2(-5.0, -1.0), Vector2(2.0, 4.0), -arm_swing, team_color)
	_draw_limb(Vector2(5.0, -1.0), Vector2(2.0, 4.0), arm_swing, team_color)

	var head_pos := Vector2(0.0, -6.0) + head_offset
	draw_circle(head_pos, 3.0, skin_color)
	draw_circle(head_pos + Vector2(1.0, -1.0), 1.0, Color.BLACK)


func _draw_limb(origin: Vector2, size: Vector2, angle: float, color: Color) -> void:
	var half := size * 0.5
	draw_set_transform(origin, angle, Vector2(facing, 1.0))
	draw_rect(Rect2(-half.x, -half.y, size.x, size.y), color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))
