extends Node2D

const PlayerScene := preload("res://scenes/player.tscn")
const BallScene := preload("res://scenes/ball.tscn")

@onready var players_root: Node2D = $Players
@onready var entities_root: Node2D = $Entities
@onready var score_label: Label = $UI/ScoreLabel
@onready var hint_label: Label = $UI/HintLabel


func _ready() -> void:
	Game.reset_match()
	Game.score_changed.connect(_on_score_changed)
	Game.match_reset.connect(_on_match_reset)
	_spawn_match()
	_update_score_label()
	queue_redraw()


func _draw() -> void:
	_draw_field()


func _spawn_match() -> void:
	for child in players_root.get_children():
		child.queue_free()

	var home_spawns := [
		Vector2(220, 250),
		Vector2(320, 270),
		Vector2(420, 250),
	]
	var away_spawns := [
		Vector2(220, 110),
		Vector2(320, 90),
		Vector2(420, 110),
	]

	for i in home_spawns.size():
		_spawn_player(Game.Team.HOME, home_spawns[i], i == 1)

	for i in away_spawns.size():
		_spawn_player(Game.Team.AWAY, away_spawns[i], false)

	var ball := BallScene.instantiate() as MatchBall
	ball.global_position = Game.FIELD_RECT.get_center()
	entities_root.add_child(ball)


func _spawn_player(team: Game.Team, pos: Vector2, human: bool) -> void:
	var player := PlayerScene.instantiate() as Player
	player.team = team
	player.is_human = human
	player.home_position = pos
	player.global_position = pos
	player.add_to_group("players")
	players_root.add_child(player)


func _draw_field() -> void:
	var r := Game.FIELD_RECT
	draw_rect(r, Color(0.18, 0.55, 0.22))
	draw_rect(r, Color(0.95, 0.95, 0.9), false, 2.0)

	var mid_y := r.position.y + r.size.y * 0.5
	draw_line(Vector2(r.position.x, mid_y), Vector2(r.end.x, mid_y), Color(0.95, 0.95, 0.9), 2.0)
	draw_arc(r.get_center(), 48.0, 0.0, TAU, 32, Color(0.95, 0.95, 0.9), 2.0)

	_draw_goal(Game.goal_rect_for_team(Game.Team.HOME), Color(0.9, 0.9, 1.0))
	_draw_goal(Game.goal_rect_for_team(Game.Team.AWAY), Color(1.0, 0.9, 0.9))


func _draw_goal(goal: Rect2, color: Color) -> void:
	draw_rect(goal, color, false, 3.0)


func _on_score_changed(home: int, away: int) -> void:
	_update_score_label(home, away)


func _on_match_reset() -> void:
	_update_score_label()


func _update_score_label(home: int = Game.score_home, away: int = Game.score_away) -> void:
	score_label.text = "%d - %d" % [home, away]
