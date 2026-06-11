extends Control

@onready var slot_buttons: VBoxContainer = %SlotButtons


func _ready() -> void:
	SaveGame.migrate_legacy_save()
	_build_slot_buttons()


func _build_slot_buttons() -> void:
	for child: Node in slot_buttons.get_children():
		child.queue_free()

	for slot in range(1, SaveGame.MAX_SLOTS + 1):
		var button := Button.new()
		button.text = SaveGame.get_slot_label(slot)
		button.disabled = not SaveGame.exists(slot)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_slot_pressed.bind(slot))
		slot_buttons.add_child(button)


func _on_slot_pressed(slot: int) -> void:
	var save_data: Dictionary = SaveGame.load_slot(slot)
	if save_data.is_empty():
		_build_slot_buttons()
		return

	GameSession.set_resume_from_save(save_data, slot)
	get_tree().change_scene_to_file("res://scenes/main.tscn")


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
