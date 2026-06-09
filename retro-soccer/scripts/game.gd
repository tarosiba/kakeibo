extends Node
## Global match state and field constants.

enum Team { HOME, AWAY }

const FIELD_RECT := Rect2(40, 40, 560, 280)
const GOAL_WIDTH := 120.0
const GOAL_DEPTH := 20.0

var score_home: int = 0
var score_away: int = 0
var ball: Node2D = null

signal score_changed(home: int, away: int)
signal match_reset()


func register_ball(b: Node2D) -> void:
	ball = b


func clamp_to_field(pos: Vector2) -> Vector2:
	return Vector2(
		clampf(pos.x, FIELD_RECT.position.x, FIELD_RECT.end.x),
		clampf(pos.y, FIELD_RECT.position.y, FIELD_RECT.end.y)
	)


func depth_scale(y: float) -> float:
	var t := inverse_lerp(FIELD_RECT.position.y, FIELD_RECT.end.y, y)
	return lerpf(0.65, 1.0, t)


func goal_rect_for_team(team: Team) -> Rect2:
	if team == Team.HOME:
		# HOME attacks the top goal.
		var cx := FIELD_RECT.position.x + FIELD_RECT.size.x * 0.5
		return Rect2(cx - GOAL_WIDTH * 0.5, FIELD_RECT.position.y - GOAL_DEPTH, GOAL_WIDTH, GOAL_DEPTH)
	var cx := FIELD_RECT.position.x + FIELD_RECT.size.x * 0.5
	return Rect2(cx - GOAL_WIDTH * 0.5, FIELD_RECT.end.y, GOAL_WIDTH, GOAL_DEPTH)


func defending_team_at_position(pos: Vector2) -> Team:
	return Team.HOME if pos.y < FIELD_RECT.get_center().y else Team.AWAY


func add_goal(scoring_team: Team) -> void:
	if scoring_team == Team.HOME:
		score_home += 1
	else:
		score_away += 1
	score_changed.emit(score_home, score_away)


func reset_match() -> void:
	score_home = 0
	score_away = 0
	score_changed.emit(score_home, score_away)
	match_reset.emit()
