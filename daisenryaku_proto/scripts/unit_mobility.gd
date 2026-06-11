class_name UnitMobility

enum Class {
	LAND,
	AIR,
}


static func get_class(unit_type: Unit.UnitType) -> Class:
	match unit_type:
		Unit.UnitType.ATTACK_HELI:
			return Class.AIR
		_:
			return Class.LAND


static func is_air_unit(unit_type: Unit.UnitType) -> bool:
	return get_class(unit_type) == Class.AIR


static func get_move_cost(tile: HexTile, unit_type: Unit.UnitType) -> int:
	if is_air_unit(unit_type):
		return _air_move_cost(tile.terrain)
	return tile.get_move_cost()


static func _air_move_cost(terrain: Terrain.Type) -> int:
	match terrain:
		Terrain.Type.FOREST:
			return 2
		Terrain.Type.MOUNTAIN:
			return 2
		Terrain.Type.SEA:
			return 1
		_:
			return 1
