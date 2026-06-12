extends Node

enum GameMode { VS, TOURNAMENT }

const TEAMS_PATH := "res://data/teams.json"
const TOURNAMENT_PATH := "res://data/tournament.json"
const MATCH_SCENE := preload("res://scenes/match.tscn")
const TITLE_SCENE := preload("res://scenes/title.tscn")
const TEAM_SELECT_SCENE := preload("res://scenes/team_select.tscn")
const MATCH_RESULT_SCENE := preload("res://scenes/match_result.tscn")

var teams: Array[Dictionary] = []
var tournament_rounds: Array[Dictionary] = []
var tournament_draw_means_loss: bool = true

var game_mode: GameMode = GameMode.VS
var home_team_index: int = 0
var away_team_index: int = 1
var player_team_index: int = 0
var tournament_round: int = 0
var tournament_active: bool = false

var home_score: int = 0
var away_score: int = 0


func _ready() -> void:
	_load_teams()
	_load_tournament()


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


func _load_tournament() -> void:
	var file := FileAccess.open(TOURNAMENT_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open tournament data: %s" % TOURNAMENT_PATH)
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid tournament JSON")
		return

	tournament_draw_means_loss = parsed.get("draw_means_loss", true)
	for round_data in parsed.get("rounds", []):
		tournament_rounds.append(round_data)


func reset_match() -> void:
	home_score = 0
	away_score = 0


func reset_team_selection() -> void:
	home_team_index = 0
	away_team_index = 1


func set_game_mode(mode: GameMode) -> void:
	game_mode = mode
	tournament_active = false
	tournament_round = 0


func get_team(index: int) -> Dictionary:
	if teams.is_empty():
		return {}
	return teams[clampi(index, 0, teams.size() - 1)]


func get_team_index_by_id(team_id: String) -> int:
	for index in teams.size():
		if teams[index].get("id", "") == team_id:
			return index
	return 0


func get_home_team() -> Dictionary:
	return get_team(home_team_index)


func get_away_team() -> Dictionary:
	return get_team(away_team_index)


func get_player_team() -> Dictionary:
	return get_team(player_team_index)


func get_team_color(team: Dictionary) -> Color:
	return Color.from_string(team.get("color", "#ffffff"), Color.WHITE)


func set_home_team_index(index: int) -> void:
	home_team_index = _normalize_index(index)
	if game_mode == GameMode.VS and home_team_index == away_team_index:
		away_team_index = _normalize_index(home_team_index + 1)


func set_away_team_index(index: int) -> void:
	away_team_index = _normalize_index(index)
	if game_mode == GameMode.VS and away_team_index == home_team_index:
		home_team_index = _normalize_index(away_team_index + 1)


func set_player_team_index(index: int) -> void:
	player_team_index = _normalize_index(index)
	if game_mode == GameMode.TOURNAMENT:
		home_team_index = player_team_index
		away_team_index = get_tournament_opponent_index(tournament_round)


func _normalize_index(index: int) -> int:
	if teams.is_empty():
		return 0
	return posmod(index, teams.size())


func get_tournament_opponent_index(round: int) -> int:
	if tournament_rounds.is_empty():
		return _normalize_index(player_team_index + round + 1)

	var round_data := tournament_rounds[clampi(round, 0, tournament_rounds.size() - 1)]
	var opponent_id: String = round_data.get("opponent_id", "")
	var opponent_index := get_team_index_by_id(opponent_id)
	if opponent_index == player_team_index:
		opponent_index = _normalize_index(opponent_index + 1)
	return opponent_index


func get_current_round_name() -> String:
	if tournament_rounds.is_empty():
		return "MATCH"
	return tournament_rounds[clampi(tournament_round, 0, tournament_rounds.size() - 1)].get("name", "MATCH")


func get_tournament_route_text() -> String:
	var parts: PackedStringArray = []
	for round_index in tournament_rounds.size():
		var opponent := get_team(get_tournament_opponent_index(round_index))
		parts.append(opponent.get("abbr", "---"))
	return " -> ".join(parts)


func start_tournament(selected_team_index: int) -> void:
	game_mode = GameMode.TOURNAMENT
	tournament_active = true
	tournament_round = 0
	player_team_index = _normalize_index(selected_team_index)
	configure_tournament_match()


func configure_tournament_match() -> void:
	home_team_index = player_team_index
	away_team_index = get_tournament_opponent_index(tournament_round)
	reset_match()


func is_tournament_mode() -> bool:
	return game_mode == GameMode.TOURNAMENT


func is_tournament_complete() -> bool:
	return tournament_round >= tournament_rounds.size()


func is_on_final_round() -> bool:
	return tournament_round >= tournament_rounds.size() - 1


func get_match_outcome_for_player() -> String:
	if home_score > away_score:
		return "win"
	if home_score < away_score:
		return "loss"
	return "draw"


func player_survives_match() -> bool:
	var outcome := get_match_outcome_for_player()
	if outcome == "win":
		return true
	if outcome == "draw" and not tournament_draw_means_loss:
		return true
	return false


func advance_tournament_after_win() -> bool:
	tournament_round += 1
	if is_tournament_complete():
		tournament_active = false
		return false

	configure_tournament_match()
	return true


func go_to_title() -> void:
	tournament_active = false
	get_tree().change_scene_to_packed(TITLE_SCENE)


func go_to_team_select() -> void:
	get_tree().change_scene_to_packed(TEAM_SELECT_SCENE)


func go_to_match() -> void:
	if game_mode == GameMode.VS:
		reset_match()
	get_tree().change_scene_to_packed(MATCH_SCENE)


func go_to_match_result() -> void:
	get_tree().change_scene_to_packed(MATCH_RESULT_SCENE)
