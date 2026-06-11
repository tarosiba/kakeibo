class_name EnemyAI


static func decide_action(hex_map: HexMap, unit: Unit) -> Dictionary:
	var attack_targets: Array[HexTile] = hex_map.get_attack_targets(unit)
	if not attack_targets.is_empty():
		return {
			"type": "attack",
			"target": _pick_weakest_target(attack_targets),
		}

	var reachable: Dictionary = hex_map.get_reachable(unit.coord, unit.move_range)
	if reachable.is_empty():
		return {"type": "wait"}

	var player_units: Array[Unit] = hex_map.get_units_by_faction(Unit.Faction.PLAYER)
	if player_units.is_empty():
		return {"type": "wait"}

	var best_tile: HexTile = _find_best_move_tile(hex_map, unit, reachable, player_units)
	if best_tile == null:
		return {"type": "wait"}

	return {
		"type": "move",
		"target": best_tile,
	}


static func _pick_weakest_target(targets: Array[HexTile]) -> HexTile:
	var weakest: HexTile = targets[0]
	for tile: HexTile in targets:
		if tile.unit.hp < weakest.unit.hp:
			weakest = tile
	return weakest


static func _find_best_move_tile(
	hex_map: HexMap,
	unit: Unit,
	reachable: Dictionary,
	player_units: Array[Unit],
) -> HexTile:
	var best_tile: HexTile = null
	var best_distance: int = 9999

	for coord: Vector2i in reachable.keys():
		var tile: HexTile = hex_map.get_tile(coord)
		var nearest_distance: int = _nearest_player_distance(coord, player_units)
		if nearest_distance < best_distance:
			best_distance = nearest_distance
			best_tile = tile

	return best_tile


static func _nearest_player_distance(coord: Vector2i, player_units: Array[Unit]) -> int:
	var nearest: int = 9999
	for player: Unit in player_units:
		nearest = mini(nearest, HexCoord.distance(coord, player.coord))
	return nearest


static func decide_production(hex_map: HexMap, tile: HexTile, funds: int) -> String:
	if not hex_map.can_produce_at(tile, Unit.Faction.ENEMY):
		return ""

	var affordable: Array[Dictionary] = UnitCatalog.get_affordable_entries(funds)
	if affordable.is_empty():
		return ""

	match GameSession.difficulty:
		GameDifficulty.Level.EASY:
			if randf() < 0.45:
				return ""
			return _pick_cheapest(affordable)
		GameDifficulty.Level.DIFFICULT:
			return _pick_preferred(affordable, ["tank", "artillery", "infantry"])
		_:
			return _pick_most_expensive(affordable)


static func _pick_cheapest(entries: Array[Dictionary]) -> String:
	var best_entry: Dictionary = entries[0]
	for entry: Dictionary in entries:
		if entry.cost < best_entry.cost:
			best_entry = entry
	return best_entry.id


static func _pick_most_expensive(entries: Array[Dictionary]) -> String:
	var best_entry: Dictionary = entries[0]
	for entry: Dictionary in entries:
		if entry.cost > best_entry.cost:
			best_entry = entry
	return best_entry.id


static func _pick_preferred(entries: Array[Dictionary], preferred_ids: Array) -> String:
	for preferred_id: String in preferred_ids:
		for entry: Dictionary in entries:
			if entry.id == preferred_id:
				return entry.id
	return _pick_most_expensive(entries)
