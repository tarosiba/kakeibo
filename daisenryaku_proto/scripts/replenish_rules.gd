class_name ReplenishRules

const MAX_STRENGTH: int = 10


static func supports_unit_type(unit_type: Unit.UnitType) -> bool:
	return unit_type in [
		Unit.UnitType.INFANTRY,
		Unit.UnitType.TANK,
		Unit.UnitType.ARTILLERY,
	]


static func get_required_turns(strength: int) -> int:
	if strength <= 5:
		return 2
	return 1


static func is_in_supply_zone(hex_map: HexMap, coord: Vector2i, faction: Unit.Faction) -> bool:
	for base_tile: HexTile in hex_map.get_bases_owned_by(faction):
		if HexCoord.distance(coord, base_tile.coord) <= 1:
			return true
	return false


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
	return is_in_supply_zone(hex_map, unit.coord, unit.faction)
