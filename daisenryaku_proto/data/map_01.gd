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

const INITIAL_PLAYER_FUNDS: int = 800
const INITIAL_ENEMY_FUNDS: int = 800

const BASES: Array[Dictionary] = [
	{
		"coord": Vector2i(1, 7),
		"name": "自軍基地",
		"owner": BaseInfo.Owner.PLAYER,
		"income": 250,
	},
	{
		"coord": Vector2i(10, 4),
		"name": "敵基地",
		"owner": BaseInfo.Owner.ENEMY,
		"income": 250,
	},
	{
		"coord": Vector2i(5, 6),
		"name": "中立都市",
		"owner": BaseInfo.Owner.NEUTRAL,
		"income": 300,
	},
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
		"color": Unit.get_faction_color(Unit.Faction.PLAYER),
	},
	{
		"coord": Vector2i(1, 6),
		"name": "歩兵",
		"type": Unit.UnitType.INFANTRY,
		"move": 3,
		"range": 1,
		"atk": 3,
		"def": 1,
		"hp": 8,
		"color": Unit.get_faction_color(Unit.Faction.PLAYER),
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
		"color": Unit.get_faction_color(Unit.Faction.PLAYER),
	},
]

const ENEMY_UNITS: Array[Dictionary] = [
	{
		"coord": Vector2i(7, 4),
		"name": "敵戦車",
		"type": Unit.UnitType.TANK,
		"move": 3,
		"range": 1,
		"atk": 4,
		"def": 1,
		"hp": 10,
		"color": Unit.get_faction_color(Unit.Faction.ENEMY),
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
		"color": Unit.get_faction_color(Unit.Faction.ENEMY),
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
		"color": Unit.get_faction_color(Unit.Faction.ENEMY),
	},
]
