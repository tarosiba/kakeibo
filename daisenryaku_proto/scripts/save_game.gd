class_name SaveGame

const LEGACY_SAVE_PATH: String = "user://saves/game_save.json"
const VERSION: int = 1
const MAX_SLOTS: int = 3


static func get_slot_path(slot: int) -> String:
	return "user://saves/slot_%d.json" % clampi(slot, 1, MAX_SLOTS)


static func is_valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= MAX_SLOTS


static func migrate_legacy_save() -> void:
	if exists(1):
		return
	if not FileAccess.file_exists(LEGACY_SAVE_PATH):
		return

	var legacy_data: Dictionary = _load_file(LEGACY_SAVE_PATH)
	if legacy_data.is_empty():
		return

	legacy_data["slot"] = 1
	save_snapshot(1, legacy_data)


static func exists(slot: int) -> bool:
	if not is_valid_slot(slot):
		return false
	return FileAccess.file_exists(get_slot_path(slot))


static func any_exists() -> bool:
	for slot in range(1, MAX_SLOTS + 1):
		if exists(slot):
			return true
	return false


static func get_summary(slot: int) -> Dictionary:
	if not exists(slot):
		return {}

	var data: Dictionary = load_slot(slot)
	if data.is_empty():
		return {}

	return {
		"slot": slot,
		"turn_number": data.get("turn_number", 1),
		"map_name": data.get("map", {}).get("map_name", "unknown"),
		"saved_at": data.get("saved_at", ""),
		"game_result": data.get("game_result", 0),
	}


static func get_slot_label(slot: int) -> String:
	if not exists(slot):
		return "スロット%d: 空" % slot

	var summary: Dictionary = get_summary(slot)
	var turn_number: int = summary.get("turn_number", 1)
	var saved_at: String = summary.get("saved_at", "")
	if saved_at != "":
		return "スロット%d: ターン%d (%s)" % [slot, turn_number, saved_at]
	return "スロット%d: ターン%d" % [slot, turn_number]


static func save_snapshot(slot: int, snapshot: Dictionary) -> bool:
	if not is_valid_slot(slot):
		return false

	var dir := DirAccess.open("user://")
	if dir != null:
		dir.make_dir_recursive("saves")

	snapshot["slot"] = slot
	var file := FileAccess.open(get_slot_path(slot), FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(JSON.stringify(snapshot, "\t"))
	return true


static func load_slot(slot: int) -> Dictionary:
	if not is_valid_slot(slot):
		return {}

	return _load_file(get_slot_path(slot))


static func delete_save(slot: int) -> bool:
	if not exists(slot):
		return true
	var dir := DirAccess.open("user://saves")
	if dir == null:
		return false
	return dir.remove("slot_%d.json" % slot) == OK


static func _load_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}

	if parsed.get("version", 0) != VERSION:
		return {}

	return parsed


static func build_snapshot(
	hex_map: HexMap,
	turn_number: int,
	turn_phase: int,
	game_result: int,
	map_source: int,
	slot: int = 1,
) -> Dictionary:
	return {
		"version": VERSION,
		"slot": slot,
		"saved_at": Time.get_datetime_string_from_system(),
		"map_source": map_source,
		"turn_number": turn_number,
		"turn_phase": turn_phase,
		"game_result": game_result,
		"map": hex_map.capture_runtime_state(),
	}
