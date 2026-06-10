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


static func can_counterattack(
	attacker: Unit,
	defender: Unit,
) -> bool:
	if not defender.is_alive():
		return false
	return HexCoord.distance(defender.coord, attacker.coord) <= defender.attack_range


static func predict_exchange(
	attacker: Unit,
	defender: Unit,
	defender_tile: HexTile,
	attacker_tile: HexTile,
) -> Dictionary:
	var outgoing_damage: int = calculate_damage(attacker, defender, defender_tile)
	var defender_hp_after: int = defender.hp - outgoing_damage
	var will_kill_defender: bool = defender_hp_after <= 0

	var counter_possible: bool = false
	var counter_damage: int = 0
	var attacker_hp_after: int = attacker.hp
	var will_kill_attacker: bool = false

	if not will_kill_defender and can_counterattack(attacker, defender):
		counter_possible = true
		counter_damage = calculate_damage(defender, attacker, attacker_tile)
		attacker_hp_after = attacker.hp - counter_damage
		will_kill_attacker = attacker_hp_after <= 0

	return {
		"outgoing_damage": outgoing_damage,
		"defender_hp_after": maxi(0, defender_hp_after),
		"will_kill_defender": will_kill_defender,
		"counter_possible": counter_possible,
		"counter_damage": counter_damage,
		"attacker_hp_after": maxi(0, attacker_hp_after),
		"will_kill_attacker": will_kill_attacker,
	}
