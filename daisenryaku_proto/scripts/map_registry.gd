class_name MapRegistry

const MAPS: Array[Dictionary] = [
	{
		"id": "map_01",
		"name": "作戦地域 α",
		"size": "12×10",
		"description": "基本の小規模マップ",
	},
	{
		"id": "map_02",
		"name": "作戦地域 β",
		"size": "18×14",
		"description": "拠点と部隊が増えた広域マップ",
	},
	{
		"id": "map_03",
		"name": "作戦地域 γ",
		"size": "20×16",
		"description": "飛行場・攻撃ヘリ・対空砲ありの広域マップ",
	},
	{
		"id": "custom",
		"name": "カスタムマップ",
		"size": "可変",
		"description": "マップエディタで作成したマップ",
	},
]


static func get_map_ids() -> Array[String]:
	var ids: Array[String] = []
	for entry: Dictionary in MAPS:
		ids.append(entry.id)
	return ids


static func get_entry(map_id: String) -> Dictionary:
	for entry: Dictionary in MAPS:
		if entry.id == map_id:
			return entry
	return MAPS[0]


static func get_display_name(map_id: String) -> String:
	var entry: Dictionary = get_entry(map_id)
	return "%s (%s)" % [entry.name, entry.size]


static func is_custom(map_id: String) -> bool:
	return map_id == "custom"
