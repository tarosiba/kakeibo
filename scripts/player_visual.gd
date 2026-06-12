extends Node2D

enum Pose { IDLE, RUN, KICK, TACKLE, DOWN }

const SPRITE_PATHS := {
	"head": "res://assets/sprites/player/head.png",
	"torso": "res://assets/sprites/player/torso.png",
	"sleeve": "res://assets/sprites/player/sleeve.png",
	"hand": "res://assets/sprites/player/hand.png",
	"shorts": "res://assets/sprites/player/shorts.png",
	"shin": "res://assets/sprites/player/shin.png",
	"star": "res://assets/sprites/player/star.png",
}

@export var team_color: Color = Color("#2563eb")

var facing: float = 1.0
var pose: Pose = Pose.IDLE
var run_phase: float = 0.0
var kick_progress: float = 0.0

var _left_leg: Node2D
var _right_leg: Node2D
var _torso: Sprite2D
var _left_arm: Node2D
var _right_arm: Node2D
var _head: Sprite2D
var _star: Sprite2D
var _body_pivot: Node2D


func _ready() -> void:
	_build_sprites()
	_apply_team_colors()


func _build_sprites() -> void:
	_left_leg = _make_leg_pivot("LeftLeg", Vector2(-2.0, 4.0))
	_right_leg = _make_leg_pivot("RightLeg", Vector2(2.0, 4.0))
	_body_pivot = Node2D.new()
	_body_pivot.name = "BodyPivot"
	add_child(_body_pivot)

	_torso = _make_sprite("Torso", SPRITE_PATHS["torso"], Vector2(-5.0, -2.0))
	_body_pivot.add_child(_torso)

	_left_arm = _make_arm_pivot("LeftArm", Vector2(-5.0, -1.0))
	_right_arm = _make_arm_pivot("RightArm", Vector2(5.0, -1.0))
	_body_pivot.add_child(_left_arm)
	_body_pivot.add_child(_right_arm)

	_head = _make_sprite("Head", SPRITE_PATHS["head"], Vector2(-4.0, -10.0))
	_body_pivot.add_child(_head)

	_star = _make_sprite("Star", SPRITE_PATHS["star"], Vector2(-3.0, -14.0))
	_star.visible = false
	add_child(_star)


func _make_sprite(name: String, path: String, offset: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = name
	sprite.texture = load(path)
	sprite.centered = false
	sprite.offset = Vector2.ZERO
	sprite.position = offset
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return sprite


func _make_leg_pivot(name: String, pivot_pos: Vector2) -> Node2D:
	var pivot := Node2D.new()
	pivot.name = name
	pivot.position = pivot_pos
	add_child(pivot)

	var shorts := _make_sprite("Shorts", SPRITE_PATHS["shorts"], Vector2(-3.0, 0.0))
	shorts.name = "ShortsSprite"
	pivot.add_child(shorts)

	var shin := _make_sprite("Shin", SPRITE_PATHS["shin"], Vector2(-2.0, 3.0))
	shin.name = "ShinSprite"
	pivot.add_child(shin)

	return pivot


func _make_arm_pivot(name: String, pivot_pos: Vector2) -> Node2D:
	var pivot := Node2D.new()
	pivot.name = name
	pivot.position = pivot_pos

	var sleeve := _make_sprite("Sleeve", SPRITE_PATHS["sleeve"], Vector2(-2.0, 0.0))
	sleeve.name = "SleeveSprite"
	pivot.add_child(sleeve)

	var hand := _make_sprite("Hand", SPRITE_PATHS["hand"], Vector2(-1.0, 3.0))
	hand.name = "HandSprite"
	pivot.add_child(hand)

	return pivot


func _apply_team_colors() -> void:
	_torso.modulate = team_color
	_tint_children(_left_leg, team_color, ["ShortsSprite"])
	_tint_children(_right_leg, team_color, ["ShortsSprite"])
	_tint_children(_left_arm, team_color, ["SleeveSprite"])
	_tint_children(_right_arm, team_color, ["SleeveSprite"])


func _tint_children(node: Node2D, color: Color, sprite_names: Array) -> void:
	for child in node.get_children():
		if child is Sprite2D and child.name in sprite_names:
			child.modulate = color


func set_team_color(color: Color) -> void:
	team_color = color
	if _torso:
		_apply_team_colors()


func set_facing(direction: Vector2) -> void:
	if absf(direction.x) > 0.05:
		facing = signf(direction.x)
		scale.x = facing


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
		_star.visible = false
		_reset_transform_overrides()


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

	_apply_pose()


func _apply_pose() -> void:
	if pose != Pose.DOWN:
		_reset_transform_overrides()

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
			_apply_down_pose()
			return

	_left_leg.rotation = leg_swing + 0.15
	_right_leg.rotation = -leg_swing - 0.15
	_left_arm.rotation = -arm_swing
	_right_arm.rotation = arm_swing
	_body_pivot.rotation = body_tilt
	_head.position = Vector2(-4.0, -10.0) + head_offset
	_star.visible = false


func _apply_down_pose() -> void:
	position.y = 4.0
	rotation = PI * 0.5 * facing
	_left_leg.rotation = 0.4
	_right_leg.rotation = -0.2
	_body_pivot.rotation = 0.0
	_left_arm.rotation = -0.8
	_right_arm.rotation = 0.5
	_head.position = Vector2(-4.0, -10.0)
	_star.visible = true
	_star.position = Vector2(-4.0 * facing, -14.0)


func _reset_transform_overrides() -> void:
	position.y = 0.0
	rotation = 0.0
