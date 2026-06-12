extends Node

const MATCH_SCENE := preload("res://scenes/match.tscn")
const TITLE_SCENE := preload("res://scenes/title.tscn")

var home_score: int = 0
var away_score: int = 0


func reset_match() -> void:
	home_score = 0
	away_score = 0


func go_to_title() -> void:
	get_tree().change_scene_to_packed(TITLE_SCENE)


func go_to_match() -> void:
	reset_match()
	get_tree().change_scene_to_packed(MATCH_SCENE)
