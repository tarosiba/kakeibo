class_name CombatResolver

const AA_HELI_ATTACK_BONUS: int = 2
const AA_HELI_DEFENSE_PENALTY: int = 1


static func calculate_damage(
	attacker: Unit,
	defender: Unit,
	defender_tile: HexTile,
) -> int:
	if not attacker.can_attack_unit_type(defender.unit_type):
		return 0

	var attack_power: int = _get_attack_power(attacker, defender)
	var defense_power: int = _get_defense_power(defender, attacker)
	var terrain_def: int = Terrain.DEFENSE_BONUS.get(defender_tile.terrain, 0)
	return maxi(1, attack_power - defense_power - terrain_def)


static func apply_attack(
	attacker: Unit,
	defender: Unit,
	defender_tile: HexTile,
) -> int:
	var damage: int = calculate_damage(attacker, defender, defender_tile)
	if damage <= 0:
		return 0
	defender.take_damage(damage)
	return damage


static func can_attack(attacker: Unit, defender: Unit) -> bool:
	return attacker.can_attack_unit_type(defender.unit_type)


static func can_counterattack(
	attacker: Unit,
	defender: Unit,
) -> bool:
	if not defender.is_alive():
		return false
	if not can_attack(defender, attacker):
		return false
	return HexCoord.distance(defender.coord, attacker.coord) <= defender.attack_range


static func predict_exchange(
	attacker: Unit,
	defender: Unit,
	defender_tile: HexTile,
	attacker_tile: HexTile,
) -> Dictionary:
	if not can_attack(attacker, defender):
		return {}

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


static func _get_attack_power(attacker: Unit, defender: Unit) -> int:
	var power: int = attacker.attack_power
	if attacker.is_aa_gun() and defender.is_air_unit():
		power += AA_HELI_ATTACK_BONUS
	return power


static func _get_defense_power(defender: Unit, attacker: Unit) -> int:
	var defense: int = defender.defense
	if defender.is_air_unit() and attacker.is_aa_gun():
		defense = maxi(0, defense - AA_HELI_DEFENSE_PENALTY)
	return defense
