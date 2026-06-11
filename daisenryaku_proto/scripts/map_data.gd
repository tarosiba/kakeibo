class_name MapData
extends RefCounted

const CUSTOM_MAP_USER_PATH: String = "user://maps/custom_map.json"
const CUSTOM_MAP_RES_PATH: String = "res://data/maps/custom_map.json"

var map_name: String = "custom"
var terrain: Array = []
var bases: Array = []
var player_units: Array = []
var enemy_units: Array = []
var player_funds: int = 800
var enemy_funds: int = 800


static func from_map01() -> MapData:
	return _from_map_constants(
		"map_01",
		Map01.DATA,
		Map01.BASES,
		Map01.PLAYER_UNITS,
		Map01.ENEMY_UNITS,
		Map01.INITIAL_PLAYER_FUNDS,
		Map01.INITIAL_ENEMY_FUNDS,
	)


static func from_map02() -> MapData:
	return _from_map_constants(
		"map_02",
		Map02.DATA,
		Map02.BASES,
		Map02.PLAYER_UNITS,
		Map02.ENEMY_UNITS,
		Map02.INITIAL_PLAYER_FUNDS,
		Map02.INITIAL_ENEMY_FUNDS,
	)


static func from_id(map_id: String) -> MapData:
	match map_id:
		"map_02":
			return from_map02()
		"map_01":
			return from_map01()
		_:
			return from_map01()


static func _from_map_constants(
	map_name: String,
	terrain_data: Array,
	bases: Array,
	player_units: Array,
	enemy_units: Array,
	player_funds: int,
	enemy_funds: int,
) -> MapData:
	var data := MapData.new()
	data.map_name = map_name
	data.terrain = _clone_grid(terrain_data)
	data.bases = _clone_entries(bases)
	data.player_units = _clone_entries(player_units)
	data.enemy_units = _clone_entries(enemy_units)
	data.player_funds = player_funds
	data.enemy_funds = enemy_funds
	return data


static func create_empty(width: int, height: int) -> MapData:
	var data := MapData.new()
	data.map_name = "new_map"
	for _r in height:
		var row: Array = []
		row.resize(width)
		row.fill(Terrain.Type.PLAIN)
		data.terrain.append(row)
	return data


static func load_from_file(path: String) -> MapData:
	if not FileAccess.file_exists(path):
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return null

	return from_dict(parsed)


static func load_custom_map() -> MapData:
	if FileAccess.file_exists(CUSTOM_MAP_USER_PATH):
		var user_map: MapData = load_from_file(CUSTOM_MAP_USER_PATH)
		if user_map != null:
			return user_map
	if FileAccess.file_exists(CUSTOM_MAP_RES_PATH):
		return load_from_file(CUSTOM_MAP_RES_PATH)
	return null


static func from_dict(source: Dictionary) -> MapData:
	var data := MapData.new()
	data.map_name = source.get("map_name", "custom")
	data.terrain = source.get("terrain", [])
	data.player_funds = source.get("player_funds", 800)
	data.enemy_funds = source.get("enemy_funds", 800)
	data.bases = _decode_bases(source.get("bases", []))
	data.player_units = _decode_units(source.get("player_units", []))
	data.enemy_units = _decode_units(source.get("enemy_units", []))
	return data


func to_dict() -> Dictionary:
	return {
		"map_name": map_name,
		"terrain": terrain,
		"player_funds": player_funds,
		"enemy_funds": enemy_funds,
		"bases": _encode_bases(),
		"player_units": _encode_units(player_units),
		"enemy_units": _encode_units(enemy_units),
	}


func save_to_file(path: String) -> bool:
	if path.begins_with("user://"):
		var dir := DirAccess.open("user://")
		if dir != null:
			dir.make_dir_recursive("maps")

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(JSON.stringify(to_dict(), "\t"))
	return true


func save_custom_map() -> bool:
	return save_to_file(CUSTOM_MAP_USER_PATH)


func duplicate_data() -> MapData:
	return MapData.from_dict(to_dict())


func get_width() -> int:
	if terrain.is_empty():
		return 0
	return terrain[0].size()


func get_height() -> int:
	return terrain.size()


func get_terrain_at(coord: Vector2i) -> int:
	if coord.y < 0 or coord.y >= terrain.size():
		return Terrain.Type.PLAIN
	var row: Array = terrain[coord.y]
	if coord.x < 0 or coord.x >= row.size():
		return Terrain.Type.PLAIN
	return row[coord.x]


func set_terrain_at(coord: Vector2i, terrain_type: int) -> void:
	if coord.y < 0 or coord.y >= terrain.size():
		return
	var row: Array = terrain[coord.y]
	if coord.x < 0 or coord.x >= row.size():
		return
	row[coord.x] = terrain_type


func find_base_at(coord: Vector2i) -> Dictionary:
	for base: Dictionary in bases:
		if base.coord == coord:
			return base
	return {}


func remove_base_at(coord: Vector2i) -> void:
	for i in range(bases.size() - 1, -1, -1):
		if bases[i].coord == coord:
			bases.remove_at(i)


func upsert_base(config: Dictionary) -> void:
	remove_base_at(config.coord)
	bases.append(config)


func remove_unit_at(coord: Vector2i) -> void:
	for i in range(player_units.size() - 1, -1, -1):
		if player_units[i].coord == coord:
			player_units.remove_at(i)
	for i in range(enemy_units.size() - 1, -1, -1):
		if enemy_units[i].coord == coord:
			enemy_units.remove_at(i)


static func _clone_grid(grid: Array) -> Array:
	var copy: Array = []
	for row: Array in grid:
		copy.append(row.duplicate())
	return copy


static func _clone_entries(entries: Array) -> Array:
	var copy: Array = []
	for entry: Dictionary in entries:
		var item: Dictionary = entry.duplicate(true)
		copy.append(item)
	return copy


static func _decode_bases(raw_bases: Array) -> Array:
	var result: Array = []
	for item: Dictionary in raw_bases:
		var coord_value: Array = item.get("coord", [0, 0])
		result.append({
			"coord": Vector2i(coord_value[0], coord_value[1]),
			"name": item.get("name", "基地"),
			"owner": _decode_owner(item.get("owner", "NEUTRAL")),
			"income": item.get("income", 250),
			"produced_this_turn": item.get("produced_this_turn", false),
		})
	return result


static func _decode_units(raw_units: Array) -> Array:
	var result: Array = []
	for item: Dictionary in raw_units:
		var coord_value: Array = item.get("coord", [0, 0])
		var catalog_id: String = item.get("catalog_id", "infantry")
		var entry: Dictionary = UnitCatalog.get_entry(catalog_id)
		result.append({
			"coord": Vector2i(coord_value[0], coord_value[1]),
			"name": item.get("name", entry.get("name", "ユニット")),
			"type": _decode_unit_type(item.get("type", entry.get("type", Unit.UnitType.INFANTRY))),
			"move": item.get("move", entry.get("move", 3)),
			"range": item.get("range", entry.get("range", 1)),
			"atk": item.get("atk", entry.get("atk", 3)),
			"def": item.get("def", entry.get("def", 1)),
			"hp": item.get("hp", entry.get("hp", 8)),
			"max_hp": item.get("max_hp", item.get("hp", entry.get("hp", 8))),
			"has_acted": item.get("has_acted", false),
			"color": _decode_color(item.get("color", Color.WHITE)),
			"catalog_id": catalog_id,
		})
	return result


func _encode_bases() -> Array:
	var result: Array = []
	for base: Dictionary in bases:
		var entry: Dictionary = {
			"coord": [base.coord.x, base.coord.y],
			"name": base.name,
			"owner": _encode_owner(base.owner),
			"income": base.income,
		}
		if base.get("produced_this_turn", false):
			entry["produced_this_turn"] = true
		result.append(entry)
	return result


func _encode_units(units: Array) -> Array:
	var result: Array = []
	for unit: Dictionary in units:
		var entry: Dictionary = {
			"coord": [unit.coord.x, unit.coord.y],
			"name": unit.name,
			"type": _encode_unit_type(unit.type),
			"catalog_id": unit.get("catalog_id", "infantry"),
			"move": unit.move,
			"range": unit.range,
			"atk": unit.atk,
			"def": unit.def,
			"hp": unit.hp,
			"max_hp": unit.get("max_hp", unit.hp),
			"color": [unit.color.r, unit.color.g, unit.color.b, unit.color.a],
		}
		if unit.get("has_acted", false):
			entry["has_acted"] = true
		result.append(entry)
	return result


static func _decode_owner(value: Variant) -> BaseInfo.Owner:
	if typeof(value) == TYPE_INT:
		return value as BaseInfo.Owner
	match str(value):
		"PLAYER":
			return BaseInfo.Owner.PLAYER
		"ENEMY":
			return BaseInfo.Owner.ENEMY
		_:
			return BaseInfo.Owner.NEUTRAL


static func _encode_owner(owner: BaseInfo.Owner) -> String:
	match owner:
		BaseInfo.Owner.PLAYER:
			return "PLAYER"
		BaseInfo.Owner.ENEMY:
			return "ENEMY"
		_:
			return "NEUTRAL"


static func _decode_unit_type(value: Variant) -> Unit.UnitType:
	if typeof(value) == TYPE_INT:
		return value as Unit.UnitType
	match str(value):
		"TANK":
			return Unit.UnitType.TANK
		"ARTILLERY":
			return Unit.UnitType.ARTILLERY
		_:
			return Unit.UnitType.INFANTRY


static func _encode_unit_type(unit_type: Unit.UnitType) -> String:
	match unit_type:
		Unit.UnitType.TANK:
			return "TANK"
		Unit.UnitType.ARTILLERY:
			return "ARTILLERY"
		_:
			return "INFANTRY"


static func _decode_color(value: Variant) -> Color:
	if typeof(value) == TYPE_ARRAY and value.size() >= 3:
		return Color(value[0], value[1], value[2], value[3] if value.size() > 3 else 1.0)
	return Color.WHITE
