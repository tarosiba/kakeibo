extends Node

const TEAMS_PATH := "res://data/teams.json"
const MATCH_SCENE := preload("res://scenes/match.tscn")
const TITLE_SCENE := preload("res://scenes/title.tscn")
const TEAM_SELECT_SCENE := preload("res://scenes/team_select.tscn")

var teams: Array[Dictionary] = []
var home_team_index: int = 0
var away_team_index: int = 1
var home_score: int = 0
var away_score: int = 0


func _ready() -> void:
	_load_teams()


func _load_teams() -> void:
	var file := FileAccess.open(TEAMS_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open teams data: %s" % TEAMS_PATH)
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid teams JSON")
		return

	for team in parsed.get("teams", []):
		teams.append(team)


func reset_match() -> void:
	home_score = 0
	away_score = 0


func reset_team_selection() -> void:
	home_team_index = 0
	away_team_index = 1


func get_team(index: int) -> Dictionary:
	if teams.is_empty():
		return {}
	return teams[clampi(index, 0, teams.size() - 1)]


func get_home_team() -> Dictionary:
	return get_team(home_team_index)


func get_away_team() -> Dictionary:
	return get_team(away_team_index)


func get_team_color(team: Dictionary) -> Color:
	return Color.from_string(team.get("color", "#ffffff"), Color.WHITE)


func set_home_team_index(index: int) -> void:
	home_team_index = _normalize_index(index)
	if home_team_index == away_team_index:
		away_team_index = _normalize_index(home_team_index + 1)


func set_away_team_index(index: int) -> void:
	away_team_index = _normalize_index(index)
	if away_team_index == home_team_index:
		home_team_index = _normalize_index(away_team_index + 1)


func _normalize_index(index: int) -> int:
	if teams.is_empty():
		return 0
	return posmod(index, teams.size())


func go_to_title() -> void:
	get_tree().change_scene_to_packed(TITLE_SCENE)


func go_to_team_select() -> void:
	get_tree().change_scene_to_packed(TEAM_SELECT_SCENE)


func go_to_match() -> void:
	reset_match()
	get_tree().change_scene_to_packed(MATCH_SCENE)
