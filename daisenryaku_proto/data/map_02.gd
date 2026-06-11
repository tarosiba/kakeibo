class_name Map02

const PLAYER_COLOR: Color = Color(0.28, 0.52, 0.92)
const ENEMY_COLOR: Color = Color(0.88, 0.22, 0.22)

# 0=plain, 1=forest, 2=sea, 3=mountain — 18×14
const DATA: Array = [
	[0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0],
	[0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0],
	[0, 1, 1, 0, 0, 0, 0, 2, 2, 2, 0, 0, 0, 0, 0, 1, 1, 0],
	[0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 3, 3, 2, 2, 2, 2, 2, 3, 3, 0, 0, 0, 0, 0],
	[0, 0, 1, 0, 3, 3, 0, 0, 0, 0, 0, 3, 3, 0, 1, 0, 0, 0],
	[0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0],
	[0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0],
	[0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 1, 0, 0, 0, 2, 2, 2, 2, 2, 0, 0, 0, 1, 0, 0, 0],
	[0, 1, 1, 1, 0, 0, 0, 2, 2, 2, 0, 0, 0, 1, 1, 1, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
]

const INITIAL_PLAYER_FUNDS: int = 800
const INITIAL_ENEMY_FUNDS: int = 800

const BASES: Array[Dictionary] = [
	{
		"coord": Vector2i(2, 12),
		"name": "自軍基地",
		"owner": BaseInfo.Owner.PLAYER,
		"income": 250,
	},
	{
		"coord": Vector2i(16, 1),
		"name": "敵基地",
		"owner": BaseInfo.Owner.ENEMY,
		"income": 250,
	},
	{
		"coord": Vector2i(8, 6),
		"name": "中立都市",
		"owner": BaseInfo.Owner.NEUTRAL,
		"income": 300,
	},
	{
		"coord": Vector2i(11, 7),
		"name": "中立港",
		"owner": BaseInfo.Owner.NEUTRAL,
		"income": 280,
	},
]

const PLAYER_UNITS: Array[Dictionary] = [
	{
		"coord": Vector2i(2, 10),
		"name": "戦車",
		"type": Unit.UnitType.TANK,
		"move": 4,
		"range": 1,
		"atk": 5,
		"def": 2,
		"hp": 12,
		"color": PLAYER_COLOR,
	},
	{
		"coord": Vector2i(1, 11),
		"name": "歩兵",
		"type": Unit.UnitType.INFANTRY,
		"move": 3,
		"range": 1,
		"atk": 3,
		"def": 1,
		"hp": 8,
		"color": PLAYER_COLOR,
	},
	{
		"coord": Vector2i(3, 11),
		"name": "砲兵",
		"type": Unit.UnitType.ARTILLERY,
		"move": 2,
		"range": 2,
		"atk": 4,
		"def": 0,
		"hp": 6,
		"color": PLAYER_COLOR,
	},
	{
		"coord": Vector2i(4, 12),
		"name": "歩兵",
		"type": Unit.UnitType.INFANTRY,
		"move": 3,
		"range": 1,
		"atk": 3,
		"def": 1,
		"hp": 8,
		"color": PLAYER_COLOR,
	},
]

const ENEMY_UNITS: Array[Dictionary] = [
	{
		"coord": Vector2i(15, 2),
		"name": "敵戦車",
		"type": Unit.UnitType.TANK,
		"move": 4,
		"range": 1,
		"atk": 5,
		"def": 2,
		"hp": 12,
		"color": ENEMY_COLOR,
	},
	{
		"coord": Vector2i(16, 3),
		"name": "敵歩兵",
		"type": Unit.UnitType.INFANTRY,
		"move": 3,
		"range": 1,
		"atk": 3,
		"def": 1,
		"hp": 8,
		"color": ENEMY_COLOR,
	},
	{
		"coord": Vector2i(14, 1),
		"name": "敵砲兵",
		"type": Unit.UnitType.ARTILLERY,
		"move": 2,
		"range": 2,
		"atk": 4,
		"def": 0,
		"hp": 6,
		"color": ENEMY_COLOR,
	},
	{
		"coord": Vector2i(13, 2),
		"name": "敵歩兵",
		"type": Unit.UnitType.INFANTRY,
		"move": 3,
		"range": 1,
		"atk": 3,
		"def": 1,
		"hp": 8,
		"color": ENEMY_COLOR,
	},
]
