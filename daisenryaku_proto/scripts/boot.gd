extends Control


func _on_play_default_pressed() -> void:
	GameSession.set_default_map()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_play_custom_pressed() -> void:
	GameSession.set_custom_map()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_map_editor_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/map_editor.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
