class_name CombatResolver


static func calculate_damage(
	attacker: Unit,
	defender: Unit,
	defender_tile: HexTile,
) -> int:
	var terrain_def: int = Terrain.DEFENSE_BONUS.get(defender_tile.terrain, 0)
	return maxi(1, attacker.attack_power - defender.defense - terrain_def)


static func apply_attack(
	attacker: Unit,
	defender: Unit,
	defender_tile: HexTile,
) -> int:
	var damage: int = calculate_damage(attacker, defender, defender_tile)
	defender.take_damage(damage)
	return damage
