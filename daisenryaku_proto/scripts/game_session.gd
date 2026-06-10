extends Node

enum MapSource {
	DEFAULT,
	CUSTOM,
	EDITOR_TEST,
}

var map_source: MapSource = MapSource.DEFAULT
var editor_map_data: MapData = null
var pending_save_data: Dictionary = {}
var resume_slot: int = 0


func get_map_data() -> MapData:
	match map_source:
		MapSource.CUSTOM:
			var custom_map: MapData = MapData.load_custom_map()
			if custom_map != null:
				return custom_map
		MapSource.EDITOR_TEST:
			if editor_map_data != null:
				return editor_map_data
	return MapData.from_map01()


func set_default_map() -> void:
	map_source = MapSource.DEFAULT
	editor_map_data = null
	pending_save_data = {}
	resume_slot = 0


func set_custom_map() -> void:
	map_source = MapSource.CUSTOM
	editor_map_data = null
	pending_save_data = {}
	resume_slot = 0


func set_editor_test_map(data: MapData) -> void:
	map_source = MapSource.EDITOR_TEST
	editor_map_data = data
	pending_save_data = {}
	resume_slot = 0


func set_resume_from_save(save_data: Dictionary, slot: int = 0) -> void:
	pending_save_data = save_data
	resume_slot = slot
	map_source = save_data.get("map_source", MapSource.DEFAULT)


func has_resume_save() -> bool:
	return not pending_save_data.is_empty()


func take_resume_save() -> Dictionary:
	var data: Dictionary = pending_save_data
	pending_save_data = {}
	return data
