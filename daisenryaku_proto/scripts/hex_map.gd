class_name HexMap
extends Node2D

signal tile_clicked(tile: HexTile, mouse_button: int)
signal tile_hovered(tile: HexTile)
signal tile_unhovered(tile: HexTile)

const HEX_TILE_SCENE: PackedScene = preload("res://scenes/hex_tile.tscn")
const UNIT_SCENE: PackedScene = preload("res://scenes/unit.tscn")

@export var hex_size: float = 28.0

var tiles: Dictionary = {}
var units: Array[Unit] = []
var player_funds: int = 0
var enemy_funds: int = 0

@onready var tiles_root: Node2D = $Tiles
@onready var units_root: Node2D = $Units


func _ready() -> void:
	if not GameSession.has_resume_save():
		setup_map(GameSession.get_map_data())


func setup_map(map_data: MapData) -> void:
	_clear_map()
	player_funds = map_data.player_funds
	enemy_funds = map_data.enemy_funds
	generate_map(map_data.terrain)
	_spawn_bases_from_data(map_data.bases)
	_spawn_units_from_data(map_data.player_units, Unit.Faction.PLAYER)
	_spawn_units_from_data(map_data.enemy_units, Unit.Faction.ENEMY)


func _clear_map() -> void:
	for child: Node in tiles_root.get_children():
		child.queue_free()
	for child: Node in units_root.get_children():
		child.queue_free()
	tiles.clear()
	units.clear()


func rebuild_from_data(map_data: MapData) -> void:
	setup_map(map_data)


func generate_map(map_data: Array) -> void:
	tiles.clear()

	for r in map_data.size():
		var row: Array = map_data[r]
		for q in row.size():
			var terrain_value: int = row[q]
			var coord := Vector2i(q, r)
			var tile: HexTile = HEX_TILE_SCENE.instantiate()
			tile.setup(coord, terrain_value as Terrain.Type)
			tile.position = HexCoord.axial_to_pixel(q, r, hex_size)
			tile.clicked.connect(_on_tile_clicked)
			tile.hovered.connect(_on_tile_hovered)
			tile.unhovered.connect(_on_tile_unhovered)
			tiles_root.add_child(tile)
			tiles[coord] = tile


func _spawn_bases_from_data(base_entries: Array) -> void:
	for config: Dictionary in base_entries:
		var coord: Vector2i = config.coord
		if not tiles.has(coord):
			push_error("Missing tile for base: %s" % coord)
			continue

		var info := BaseInfo.new()
		info.base_name = config.name
		info.owner = config.owner
		info.income = config.income
		info.produced_this_turn = config.get("produced_this_turn", false)
		tiles[coord].set_base(info)


func _spawn_units_from_data(unit_entries: Array, faction: Unit.Faction) -> void:
	for config: Dictionary in unit_entries:
		_spawn_unit_from_config(config, faction)


func _spawn_unit_from_config(config: Dictionary, faction: Unit.Faction) -> Unit:
	var max_hp: int = config.get("max_hp", config.hp)
	var unit: Unit = spawn_unit(
		config.coord,
		faction,
		config.color,
		config.move,
		config.range,
		config.atk,
		config.def,
		max_hp,
		config.name,
		config.type,
	)
	if unit == null:
		return null

	unit.hp = clampi(config.get("hp", max_hp), 0, max_hp)
	if config.get("has_acted", false):
		unit.mark_acted()
	else:
		unit.reset_turn()
	return unit


func spawn_unit(
	coord: Vector2i,
	faction: Unit.Faction,
	color: Color,
	move_range: int,
	attack_range: int = 1,
	attack_power: int = 3,
	defense: int = 1,
	max_hp: int = 10,
	unit_name: String = "ユニット",
	unit_type: Unit.UnitType = Unit.UnitType.INFANTRY,
) -> Unit:
	if not tiles.has(coord):
		push_error("Cannot spawn unit at missing tile: %s" % coord)
		return null

	var tile: HexTile = tiles[coord]
	if tile.unit != null:
		push_error("Tile already occupied: %s" % coord)
		return null

	var unit: Unit = UNIT_SCENE.instantiate()
	unit.unit_name = unit_name
	unit.unit_type = unit_type
	unit.faction = faction
	unit.faction_color = color
	unit.move_range = move_range
	unit.attack_range = attack_range
	unit.attack_power = attack_power
	unit.defense = defense
	unit.max_hp = max_hp
	unit.hp = max_hp
	unit.coord = coord
	unit.position = tile.position
	tile.unit = unit
	units_root.add_child(unit)
	units.append(unit)
	return unit


func get_tile(coord: Vector2i) -> HexTile:
	return tiles.get(coord)


func capture_runtime_state() -> Dictionary:
	var map_bounds: Vector2i = _get_map_bounds()
	var width: int = map_bounds.x
	var height: int = map_bounds.y
	var terrain_grid: Array = []

	for r in height:
		var row: Array = []
		for q in width:
			var coord := Vector2i(q, r)
			if tiles.has(coord):
				row.append(tiles[coord].terrain)
			else:
				row.append(Terrain.Type.PLAIN)
		terrain_grid.append(row)

	var base_entries: Array = []
	for tile: HexTile in tiles.values():
		if tile.base_info == null:
			continue
		base_entries.append({
			"coord": tile.coord,
			"name": tile.base_info.base_name,
			"owner": tile.base_info.owner,
			"income": tile.base_info.income,
			"produced_this_turn": tile.base_info.produced_this_turn,
		})

	var player_unit_entries: Array = []
	var enemy_unit_entries: Array = []
	for unit: Unit in units:
		if not unit.is_alive():
			continue
		var entry: Dictionary = _encode_runtime_unit(unit)
		if unit.faction == Unit.Faction.PLAYER:
			player_unit_entries.append(entry)
		else:
			enemy_unit_entries.append(entry)

	var map_data := MapData.new()
	map_data.map_name = "runtime"
	map_data.terrain = terrain_grid
	map_data.bases = base_entries
	map_data.player_units = player_unit_entries
	map_data.enemy_units = enemy_unit_entries
	map_data.player_funds = player_funds
	map_data.enemy_funds = enemy_funds
	return map_data.to_dict()


func restore_runtime_state(snapshot: Dictionary) -> void:
	var map_data: MapData = MapData.from_dict(snapshot)
	setup_map(map_data)


func _get_map_bounds() -> Vector2i:
	var max_q: int = 0
	var max_r: int = 0
	for coord: Vector2i in tiles.keys():
		max_q = maxi(max_q, coord.x + 1)
		max_r = maxi(max_r, coord.y + 1)
	return Vector2i(max_q, max_r)


func _encode_runtime_unit(unit: Unit) -> Dictionary:
	var catalog_id: String = "infantry"
	match unit.unit_type:
		Unit.UnitType.TANK:
			catalog_id = "tank"
		Unit.UnitType.ARTILLERY:
			catalog_id = "artillery"

	return {
		"coord": unit.coord,
		"name": unit.unit_name,
		"type": unit.unit_type,
		"move": unit.move_range,
		"range": unit.attack_range,
		"atk": unit.attack_power,
		"def": unit.defense,
		"hp": unit.hp,
		"max_hp": unit.max_hp,
		"has_acted": unit.has_acted,
		"color": unit.faction_color,
		"catalog_id": catalog_id,
	}


func get_units_by_faction(faction: Unit.Faction) -> Array[Unit]:
	var result: Array[Unit] = []
	for unit: Unit in units:
		if unit.is_alive() and unit.faction == faction:
			result.append(unit)
	return result


func get_idle_units_by_faction(faction: Unit.Faction) -> Array[Unit]:
	var result: Array[Unit] = []
	for unit: Unit in units:
		if unit.is_alive() and unit.faction == faction and not unit.has_acted:
			result.append(unit)
	return result


func count_idle_units(faction: Unit.Faction) -> int:
	return get_idle_units_by_faction(faction).size()


func reset_all_unit_turns() -> void:
	for unit: Unit in units:
		if unit.is_alive():
			unit.reset_turn()


func has_living_units(faction: Unit.Faction) -> bool:
	return not get_units_by_faction(faction).is_empty()


func get_funds(faction: Unit.Faction) -> int:
	match faction:
		Unit.Faction.PLAYER:
			return player_funds
		Unit.Faction.ENEMY:
			return enemy_funds
		_:
			return 0


func can_afford(faction: Unit.Faction, cost: int) -> bool:
	return get_funds(faction) >= cost


func spend_funds(faction: Unit.Faction, amount: int) -> bool:
	if not can_afford(faction, amount):
		return false

	match faction:
		Unit.Faction.PLAYER:
			player_funds -= amount
		Unit.Faction.ENEMY:
			enemy_funds -= amount
		_:
			return false
	return true


func collect_income(faction: Unit.Faction) -> int:
	var total: int = 0
	for tile: HexTile in tiles.values():
		if tile.base_info != null and tile.base_info.is_owned_by(faction):
			total += tile.base_info.income
	match faction:
		Unit.Faction.PLAYER:
			player_funds += total
		Unit.Faction.ENEMY:
			enemy_funds += total
	return total


func reset_base_production(faction: Unit.Faction) -> void:
	for tile: HexTile in tiles.values():
		if tile.base_info != null and tile.base_info.is_owned_by(faction):
			tile.base_info.produced_this_turn = false


func get_bases_owned_by(faction: Unit.Faction) -> Array[HexTile]:
	var result: Array[HexTile] = []
	for tile: HexTile in tiles.values():
		if tile.base_info != null and tile.base_info.is_owned_by(faction):
			result.append(tile)
	return result


func try_capture_base(tile: HexTile, faction: Unit.Faction) -> Dictionary:
	if tile.base_info == null:
		return {"captured": false}
	if tile.base_info.is_owned_by(faction):
		return {"captured": false}

	var base_name: String = tile.base_info.base_name
	var old_owner: BaseInfo.Owner = tile.base_info.owner
	tile.base_info.set_owner_from_faction(faction)
	tile._update_base_display()
	return {
		"captured": true,
		"base_name": base_name,
		"old_owner": old_owner,
	}


func can_produce_at(tile: HexTile, faction: Unit.Faction) -> bool:
	if tile.base_info == null:
		return false
	if not tile.base_info.is_owned_by(faction):
		return false
	if tile.base_info.produced_this_turn:
		return false
	return tile.unit == null


func produce_unit(tile: HexTile, faction: Unit.Faction, catalog_id: String) -> Dictionary:
	if not can_produce_at(tile, faction):
		return {"success": false, "reason": "生産できません"}

	var entry: Dictionary = UnitCatalog.get_entry(catalog_id)
	if entry.is_empty():
		return {"success": false, "reason": "不明なユニット"}

	if not spend_funds(faction, entry.cost):
		return {"success": false, "reason": "資金が足りません"}

	var color: Color = entry.color
	if faction == Unit.Faction.ENEMY:
		color = color.darkened(0.25)

	var unit: Unit = spawn_unit(
		tile.coord,
		faction,
		color,
		entry.move,
		entry.range,
		entry.atk,
		entry.def,
		entry.hp,
		entry.name,
		entry.type,
	)
	if unit == null:
		match faction:
			Unit.Faction.PLAYER:
				player_funds += entry.cost
			Unit.Faction.ENEMY:
				enemy_funds += entry.cost
		return {"success": false, "reason": "配置に失敗しました"}

	tile.base_info.produced_this_turn = true
	return {
		"success": true,
		"unit": unit,
		"cost": entry.cost,
		"unit_name": entry.name,
	}


func get_reachable(from: Vector2i, move_points: int) -> Dictionary:
	var result: Dictionary = {}
	var frontier: Array = [[from, move_points]]

	while not frontier.is_empty():
		var current: Array = frontier.pop_front()
		var coord: Vector2i = current[0]
		var cost_left: int = current[1]

		for offset in HexCoord.NEIGHBORS:
			var next_coord: Vector2i = coord + offset
			if not tiles.has(next_coord):
				continue

			var tile: HexTile = tiles[next_coord]
			var step_cost: int = tile.get_move_cost()
			if step_cost > cost_left:
				continue

			if tile.unit != null and next_coord != from:
				continue

			var remaining: int = cost_left - step_cost
			if result.has(next_coord) and result[next_coord] >= remaining:
				continue

			result[next_coord] = remaining
			frontier.append([next_coord, remaining])

	return result


func get_attack_targets(attacker: Unit) -> Array[HexTile]:
	var targets: Array[HexTile] = []

	for coord: Vector2i in tiles.keys():
		if HexCoord.distance(attacker.coord, coord) > attacker.attack_range:
			continue

		var tile: HexTile = tiles[coord]
		if tile.unit == null or tile.unit.faction == attacker.faction:
			continue

		targets.append(tile)

	return targets


func attack_unit(
	attacker: Unit,
	target_tile: HexTile,
	allow_counter: bool = true,
) -> Dictionary:
	var defender: Unit = target_tile.unit
	if defender == null or defender.faction == attacker.faction:
		return {"success": false}

	if HexCoord.distance(attacker.coord, target_tile.coord) > attacker.attack_range:
		return {"success": false}

	var damage: int = CombatResolver.apply_attack(attacker, defender, target_tile)
	var killed: bool = not defender.is_alive()
	if killed:
		remove_unit(defender)

	var counter: Dictionary = {}
	if allow_counter and CombatResolver.can_counterattack(attacker, defender):
		counter = _resolve_counterattack(defender, attacker)

	return {
		"success": true,
		"damage": damage,
		"killed": killed,
		"defender_hp": defender.hp if not killed else 0,
		"counter": counter,
	}


func _resolve_counterattack(defender: Unit, attacker: Unit) -> Dictionary:
	if not tiles.has(attacker.coord):
		return {"occurred": false}

	var attacker_tile: HexTile = tiles[attacker.coord]
	var counter_damage: int = CombatResolver.apply_attack(defender, attacker, attacker_tile)
	var attacker_killed: bool = not attacker.is_alive()
	if attacker_killed:
		remove_unit(attacker)

	return {
		"occurred": true,
		"damage": counter_damage,
		"killed": attacker_killed,
		"attacker_hp": attacker.hp if not attacker_killed else 0,
		"counter_attacker": defender,
		"counter_victim": attacker,
	}


func remove_unit(unit: Unit) -> void:
	if not tiles.has(unit.coord):
		return

	var tile: HexTile = tiles[unit.coord]
	if tile.unit == unit:
		tile.unit = null

	units.erase(unit)
	unit.queue_free()


func move_unit(unit: Unit, target: HexTile) -> Dictionary:
	var from_coord: Vector2i = unit.coord
	var to_coord: Vector2i = target.coord

	if from_coord == to_coord:
		return {"success": false}

	var from_tile: HexTile = tiles[from_coord]
	if from_tile.unit != unit:
		return {"success": false}

	if target.unit != null:
		return {"success": false}

	from_tile.unit = null
	target.unit = unit
	unit.coord = to_coord
	unit.position = target.position
	var capture: Dictionary = try_capture_base(target, unit.faction)
	return {
		"success": true,
		"capture": capture,
	}


func predict_attack(attacker: Unit, target_tile: HexTile) -> Dictionary:
	var defender: Unit = target_tile.unit
	if defender == null or defender.faction == attacker.faction:
		return {}

	if not tiles.has(attacker.coord):
		return {}

	var attacker_tile: HexTile = tiles[attacker.coord]
	return CombatResolver.predict_exchange(
		attacker,
		defender,
		target_tile,
		attacker_tile,
	)


func clear_highlights() -> void:
	for tile: HexTile in tiles.values():
		tile.set_highlight("")
		tile.set_damage_preview("")


func show_reachable(reachable: Dictionary) -> void:
	for coord: Vector2i in reachable.keys():
		var tile: HexTile = tiles[coord]
		tile.set_highlight("reachable")


func show_selected(tile: HexTile) -> void:
	tile.set_highlight("selected")


func show_base_selected(tile: HexTile) -> void:
	tile.set_highlight("base")


func show_attackable(targets: Array[HexTile]) -> void:
	for tile: HexTile in targets:
		tile.set_highlight("attackable")


func show_attack_predictions(attacker: Unit, targets: Array[HexTile]) -> void:
	for tile: HexTile in targets:
		var preview: Dictionary = predict_attack(attacker, tile)
		tile.set_damage_preview(_format_tile_preview(preview))


func _format_tile_preview(preview: Dictionary) -> String:
	if preview.is_empty():
		return ""

	if preview.will_kill_defender:
		return "%d KO" % preview.outgoing_damage

	if preview.counter_possible:
		return "%d/%d" % [preview.outgoing_damage, preview.counter_damage]

	return "%d" % preview.outgoing_damage


func _on_tile_clicked(tile: HexTile, mouse_button: int) -> void:
	tile_clicked.emit(tile, mouse_button)


func _on_tile_hovered(tile: HexTile) -> void:
	tile_hovered.emit(tile)


func _on_tile_unhovered(tile: HexTile) -> void:
	tile_unhovered.emit(tile)
