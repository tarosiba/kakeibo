class_name GameDifficulty

enum Level {
	EASY,
	NORMAL,
	DIFFICULT,
}

const LABELS: Dictionary = {
	Level.EASY: "Easy（易しい）",
	Level.NORMAL: "Usually（ふつう）",
	Level.DIFFICULT: "Difficult（難しい）",
}

const DESCRIPTIONS: Dictionary = {
	Level.EASY: "自軍に資金・戦力ボーナス、敵は弱体化",
	Level.NORMAL: "標準バランス",
	Level.DIFFICULT: "敵に資金・戦力ボーナス、自軍は不利",
}


static func get_label(level: Level) -> String:
	return LABELS.get(level, "Usually（ふつう）")


static func get_description(level: Level) -> String:
	return DESCRIPTIONS.get(level, "")


static func apply(map_data: MapData, difficulty: Level) -> MapData:
	if difficulty == Level.NORMAL:
		return map_data.duplicate_data()

	var result: MapData = map_data.duplicate_data()
	match difficulty:
		Level.EASY:
			_apply_easy(result)
		Level.DIFFICULT:
			_apply_difficult(result)
	return result


static func _apply_easy(map_data: MapData) -> void:
	map_data.player_funds = int(map_data.player_funds * 1.5)
	map_data.enemy_funds = int(map_data.enemy_funds * 0.75)

	for unit: Dictionary in map_data.player_units:
		unit.atk += 1
		unit.hp = mini(ReplenishRules.MAX_STRENGTH, unit.hp + 2)
		unit.max_hp = ReplenishRules.MAX_STRENGTH

	for unit: Dictionary in map_data.enemy_units:
		unit.atk = maxi(1, unit.atk - 1)
		unit.hp = maxi(1, unit.hp - 1)
		unit.max_hp = ReplenishRules.MAX_STRENGTH

	for base: Dictionary in map_data.bases:
		if base.owner == BaseInfo.Owner.NEUTRAL:
			base.owner = BaseInfo.Owner.PLAYER
			base.name = "占領都市"


static func _apply_difficult(map_data: MapData) -> void:
	map_data.player_funds = int(map_data.player_funds * 0.75)
	map_data.enemy_funds = int(map_data.enemy_funds * 1.5)

	for unit: Dictionary in map_data.player_units:
		unit.atk = maxi(1, unit.atk - 1)

	for unit: Dictionary in map_data.enemy_units:
		unit.atk += 1
		unit.hp = mini(ReplenishRules.MAX_STRENGTH, unit.hp + 2)
		unit.max_hp = ReplenishRules.MAX_STRENGTH
