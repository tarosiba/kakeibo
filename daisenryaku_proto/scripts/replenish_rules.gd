class_name ReplenishRules

const MAX_STRENGTH: int = 10


static func supports_unit_type(unit_type: Unit.UnitType) -> bool:
	return unit_type in [
		Unit.UnitType.INFANTRY,
		Unit.UnitType.TANK,
		Unit.UnitType.ARTILLERY,
		Unit.UnitType.ATTACK_HELI,
		Unit.UnitType.AA_GUN,
	]


static func get_required_turns(strength: int) -> int:
	if strength <= 5:
		return 2
	return 1


static func is_in_supply_zone(
	hex_map: HexMap,
	coord: Vector2i,
	faction: Unit.Faction,
	unit_type: Unit.UnitType,
) -> bool:
	for base_tile: HexTile in hex_map.get_bases_owned_by(faction):
		if not _is_occupied_base(base_tile, faction):
			continue
		if not _base_matches_unit_supply(base_tile.base_info, unit_type):
			continue
		if HexCoord.distance(coord, base_tile.coord) <= 1:
			return true
	return false


static func can_replenish_at_coord(hex_map: HexMap, coord: Vector2i, unit: Unit) -> bool:
	if not is_in_supply_zone(hex_map, coord, unit.faction, unit.unit_type):
		return false

	var tile: HexTile = hex_map.get_tile(coord)
	if tile == null:
		return false

	if tile.base_info != null and not tile.base_info.is_owned_by(unit.faction):
		return false

	return true


static func can_start(unit: Unit, hex_map: HexMap) -> bool:
	if not unit.is_alive():
		return false
	if not supports_unit_type(unit.unit_type):
		return false
	if unit.is_replenishing():
		return false
	if unit.has_acted:
		return false
	if unit.hp >= MAX_STRENGTH:
		return false
	return can_replenish_at_coord(hex_map, unit.coord, unit)


static func _base_matches_unit_supply(base_info: BaseInfo, unit_type: Unit.UnitType) -> bool:
	if UnitMobility.is_air_unit(unit_type):
		return base_info.is_airfield()
	return base_info.is_city()


static func _is_occupied_base(base_tile: HexTile, faction: Unit.Faction) -> bool:
	if base_tile.base_info == null:
		return false
	return base_tile.base_info.is_owned_by(faction)
