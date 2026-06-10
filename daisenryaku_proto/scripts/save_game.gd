class_name SaveGame

const SAVE_PATH: String = "user://saves/game_save.json"
const VERSION: int = 1


static func exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


static func get_summary() -> Dictionary:
	if not exists():
		return {}

	var data: Dictionary = load()
	if data.is_empty():
		return {}

	return {
		"turn_number": data.get("turn_number", 1),
		"map_name": data.get("map", {}).get("map_name", "unknown"),
		"saved_at": data.get("saved_at", ""),
	}


static func save_snapshot(snapshot: Dictionary) -> bool:
	var dir := DirAccess.open("user://")
	if dir != null:
		dir.make_dir_recursive("saves")

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(JSON.stringify(snapshot, "\t"))
	return true


static func load() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}

	if parsed.get("version", 0) != VERSION:
		return {}

	return parsed


static func delete_save() -> bool:
	if not exists():
		return true
	var dir := DirAccess.open("user://saves")
	if dir == null:
		return false
	return dir.remove("game_save.json") == OK


static func build_snapshot(
	hex_map: HexMap,
	turn_number: int,
	turn_phase: int,
	game_result: int,
	map_source: int,
) -> Dictionary:
	return {
		"version": VERSION,
		"saved_at": Time.get_datetime_string_from_system(),
		"map_source": map_source,
		"turn_number": turn_number,
		"turn_phase": turn_phase,
		"game_result": game_result,
		"map": hex_map.capture_runtime_state(),
	}
