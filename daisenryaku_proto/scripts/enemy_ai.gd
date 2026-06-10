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
