class_name ScenarioLoader
extends RefCounted

static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Scenario file not found: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open scenario file: %s" % path)
		return {}

	var raw := file.get_as_text()
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Scenario JSON is not a dictionary: %s" % path)
		return {}
	return parsed
