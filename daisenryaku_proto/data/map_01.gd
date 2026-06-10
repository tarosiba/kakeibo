class_name Map01

# 0=plain, 1=forest, 2=sea, 3=mountain
const DATA: Array = [
	[0, 0, 0, 1, 1, 0, 0, 0, 2, 2, 0, 0],
	[0, 0, 1, 1, 0, 0, 0, 2, 2, 2, 0, 0],
	[0, 1, 1, 0, 0, 0, 0, 0, 2, 0, 0, 0],
	[0, 0, 0, 0, 0, 3, 3, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 3, 3, 3, 3, 0, 0, 1, 0],
	[0, 0, 0, 0, 0, 3, 3, 0, 0, 1, 1, 0],
	[0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0],
	[0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 1, 0, 0, 0, 2, 2, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 2, 2, 2, 2, 0, 0, 0],
]

const PLAYER_UNITS: Array[Dictionary] = [
	{
		"coord": Vector2i(1, 3),
		"name": "戦車",
		"type": Unit.UnitType.TANK,
		"move": 4,
		"range": 1,
		"atk": 5,
		"def": 2,
		"hp": 12,
		"color": Color(0.85, 0.20, 0.20),
	},
	{
		"coord": Vector2i(2, 5),
		"name": "歩兵",
		"type": Unit.UnitType.INFANTRY,
		"move": 3,
		"range": 1,
		"atk": 3,
		"def": 1,
		"hp": 8,
		"color": Color(0.95, 0.45, 0.15),
	},
	{
		"coord": Vector2i(0, 4),
		"name": "砲兵",
		"type": Unit.UnitType.ARTILLERY,
		"move": 2,
		"range": 2,
		"atk": 4,
		"def": 0,
		"hp": 6,
		"color": Color(0.75, 0.25, 0.55),
	},
]

const ENEMY_UNITS: Array[Dictionary] = [
	{
		"coord": Vector2i(4, 3),
		"name": "敵戦車",
		"type": Unit.UnitType.TANK,
		"move": 3,
		"range": 1,
		"atk": 4,
		"def": 1,
		"hp": 10,
		"color": Color(0.25, 0.45, 0.90),
	},
	{
		"coord": Vector2i(8, 6),
		"name": "敵歩兵",
		"type": Unit.UnitType.INFANTRY,
		"move": 3,
		"range": 1,
		"atk": 3,
		"def": 1,
		"hp": 8,
		"color": Color(0.35, 0.60, 0.95),
	},
	{
		"coord": Vector2i(6, 2),
		"name": "敵砲兵",
		"type": Unit.UnitType.ARTILLERY,
		"move": 2,
		"range": 2,
		"atk": 3,
		"def": 0,
		"hp": 6,
		"color": Color(0.20, 0.35, 0.75),
	},
]
