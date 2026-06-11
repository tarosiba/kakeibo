extends Node

enum MapSource {
	DEFAULT,
	CUSTOM,
	EDITOR_TEST,
}

var map_source: MapSource = MapSource.DEFAULT
var map_id: String = "map_01"
var difficulty: GameDifficulty.Level = GameDifficulty.Level.NORMAL
var editor_map_data: MapData = null
var pending_save_data: Dictionary = {}
var resume_slot: int = 0


func get_map_data() -> MapData:
	var base_data: MapData = _load_base_map_data()
	if base_data == null:
		base_data = MapData.from_map01()
	return GameDifficulty.apply(base_data, difficulty)


func _load_base_map_data() -> MapData:
	match map_source:
		MapSource.CUSTOM:
			return MapData.load_custom_map()
		MapSource.EDITOR_TEST:
			if editor_map_data != null:
				return editor_map_data
			return null
		_:
			return MapData.from_id(map_id)


func set_new_game(selected_map_id: String, selected_difficulty: GameDifficulty.Level) -> void:
	map_id = selected_map_id
	difficulty = selected_difficulty
	editor_map_data = null
	pending_save_data = {}
	resume_slot = 0

	if MapRegistry.is_custom(selected_map_id):
		map_source = MapSource.CUSTOM
	else:
		map_source = MapSource.DEFAULT


func set_default_map() -> void:
	set_new_game("map_01", GameDifficulty.Level.NORMAL)


func set_custom_map() -> void:
	set_new_game("custom", GameDifficulty.Level.NORMAL)


func set_editor_test_map(data: MapData) -> void:
	map_source = MapSource.EDITOR_TEST
	editor_map_data = data
	pending_save_data = {}
	resume_slot = 0


func set_resume_from_save(save_data: Dictionary, slot: int = 0) -> void:
	pending_save_data = save_data
	resume_slot = slot
	map_source = save_data.get("map_source", MapSource.DEFAULT)
	map_id = save_data.get("map_id", "map_01")
	difficulty = save_data.get("difficulty", GameDifficulty.Level.NORMAL)


func has_resume_save() -> bool:
	return not pending_save_data.is_empty()


func take_resume_save() -> Dictionary:
	var data: Dictionary = pending_save_data
	pending_save_data = {}
	return data
