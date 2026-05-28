class_name CombatResolver
extends RefCounted

static func resolve(attacker_attack: int, defender_defense: int) -> Dictionary:
	var damage_to_defender := max(1, attacker_attack - defender_defense + randi_range(-1, 1))
	var damage_to_attacker := max(0, int(floor(float(defender_defense) / 2.0)) + randi_range(0, 1))
	return {
		"to_defender": damage_to_defender,
		"to_attacker": damage_to_attacker
	}
