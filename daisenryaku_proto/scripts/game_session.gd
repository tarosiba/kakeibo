extends Node

enum MapSource {
	DEFAULT,
	CUSTOM,
	EDITOR_TEST,
}

var map_source: MapSource = MapSource.DEFAULT
var editor_map_data: MapData = null


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


func set_custom_map() -> void:
	map_source = MapSource.CUSTOM
	editor_map_data = null


func set_editor_test_map(data: MapData) -> void:
	map_source = MapSource.EDITOR_TEST
	editor_map_data = data
