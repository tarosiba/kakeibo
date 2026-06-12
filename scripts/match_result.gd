extends Control

@onready var title_label: Label = $MainLayout/TitleLabel
@onready var score_label: Label = $MainLayout/ScoreLabel
@onready var detail_label: Label = $MainLayout/DetailLabel
@onready var hint_label: Label = $MainLayout/HintLabel


func _ready() -> void:
	_refresh_ui()


func _refresh_ui() -> void:
	var home_team := GameManager.get_home_team()
	var away_team := GameManager.get_away_team()
	var home_abbr: String = home_team.get("abbr", "HOM")
	var away_abbr: String = away_team.get("abbr", "AWY")

	score_label.text = "%s %d - %d %s" % [
		home_abbr,
		GameManager.home_score,
		GameManager.away_score,
		away_abbr,
	]

	if GameManager.is_tournament_mode():
		_refresh_tournament_result()
	else:
		_refresh_vs_result()


func _refresh_vs_result() -> void:
	title_label.text = "FULL TIME"
	if GameManager.home_score > GameManager.away_score:
		detail_label.text = "%s WIN" % GameManager.get_home_team().get("name", "")
	elif GameManager.home_score < GameManager.away_score:
		detail_label.text = "%s WIN" % GameManager.get_away_team().get("name", "")
	else:
		detail_label.text = "DRAW"
	hint_label.text = "SPACE: team select  ESC: title"


func _refresh_tournament_result() -> void:
	var outcome := GameManager.get_match_outcome_for_player()
	var round_name := GameManager.get_current_round_name()

	if outcome == "win":
		if GameManager.is_on_final_round():
			title_label.text = "WORLD CHAMPION"
			detail_label.text = "%s WINS THE CUP" % GameManager.get_player_team().get("name", "")
			hint_label.text = "SPACE: title"
		else:
			title_label.text = "YOU WIN"
			detail_label.text = "%s CLEARED" % round_name
			var next_opponent := GameManager.get_team(GameManager.get_tournament_opponent_index(GameManager.tournament_round + 1))
			hint_label.text = "NEXT: %s  SPACE: continue  ESC: title" % next_opponent.get("name", "")
	elif outcome == "draw" and GameManager.tournament_draw_means_loss:
		title_label.text = "DRAW"
		detail_label.text = "NO EXTRA TIME - ELIMINATED"
		hint_label.text = "SPACE: title"
	else:
		title_label.text = "DEFEAT"
		detail_label.text = "%s - ELIMINATED" % round_name
		hint_label.text = "SPACE: title"


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		GameManager.go_to_title()
		return

	if not event.is_action_pressed("start"):
		return

	get_viewport().set_input_as_handled()

	if not GameManager.is_tournament_mode():
		GameManager.go_to_team_select()
		return

	var outcome := GameManager.get_match_outcome_for_player()
	if outcome == "win":
		if GameManager.is_on_final_round():
			GameManager.tournament_active = false
			GameManager.go_to_title()
		else:
			GameManager.advance_tournament_after_win()
			GameManager.go_to_match()
	else:
		GameManager.go_to_title()
