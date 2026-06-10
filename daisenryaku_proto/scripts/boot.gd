extends Control

@onready var continue_button: Button = %ContinueButton


func _ready() -> void:
	_update_continue_button()


func _update_continue_button() -> void:
	if not SaveGame.exists():
		continue_button.disabled = true
		continue_button.text = "続きから (セーブなし)"
		return

	var summary: Dictionary = SaveGame.get_summary()
	if summary.is_empty():
		continue_button.disabled = true
		continue_button.text = "続きから (読込不可)"
		return

	continue_button.disabled = false
	continue_button.text = "続きから (ターン %d)" % summary.get("turn_number", 1)


func _on_play_default_pressed() -> void:
	GameSession.set_default_map()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_play_custom_pressed() -> void:
	GameSession.set_custom_map()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_continue_pressed() -> void:
	var save_data: Dictionary = SaveGame.load()
	if save_data.is_empty():
		_update_continue_button()
		return

	GameSession.set_resume_from_save(save_data)
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_map_editor_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/map_editor.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
