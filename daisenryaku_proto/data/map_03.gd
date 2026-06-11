class_name Map03

const PLAYER_COLOR: Color = Color(0.28, 0.52, 0.92)
const ENEMY_COLOR: Color = Color(0.88, 0.22, 0.22)

# 0=plain, 1=forest, 2=sea, 3=mountain — 20×16
const DATA: Array = [
	[0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0],
	[0, 0, 1, 1, 0, 0, 0, 2, 2, 2, 2, 0, 0, 1, 1, 0, 0, 0, 1, 0],
	[0, 1, 0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 1, 1, 0, 0],
	[0, 0, 0, 0, 3, 3, 2, 2, 2, 2, 2, 2, 3, 3, 0, 0, 0, 0, 0, 0],
	[0, 0, 1, 0, 3, 3, 0, 0, 0, 0, 0, 0, 3, 3, 0, 1, 0, 0, 0, 0],
	[0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0],
	[0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0],
	[0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 1, 0, 0, 0, 2, 2, 2, 2, 2, 2, 0, 0, 0, 1, 0, 0, 1, 0],
	[0, 1, 1, 0, 0, 0, 0, 2, 2, 2, 2, 0, 0, 0, 0, 1, 1, 0, 1, 0],
	[0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0],
	[0, 1, 0, 0, 0, 0, 0, 3, 3, 3, 3, 0, 0, 0, 0, 0, 1, 0, 0, 0],
	[0, 1, 1, 0, 0, 0, 3, 3, 0, 0, 3, 3, 0, 0, 0, 1, 1, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
]

const INITIAL_PLAYER_FUNDS: int = 900
const INITIAL_ENEMY_FUNDS: int = 900

const BASES: Array[Dictionary] = [
	{
		"coord": Vector2i(2, 14),
		"name": "自軍都市",
		"owner": BaseInfo.Owner.PLAYER,
		"base_type": BaseInfo.BaseType.CITY,
		"income": 250,
	},
	{
		"coord": Vector2i(5, 15),
		"name": "自軍飛行場",
		"owner": BaseInfo.Owner.PLAYER,
		"base_type": BaseInfo.BaseType.AIRFIELD,
		"income": 200,
	},
	{
		"coord": Vector2i(17, 1),
		"name": "敵都市",
		"owner": BaseInfo.Owner.ENEMY,
		"base_type": BaseInfo.BaseType.CITY,
		"income": 250,
	},
	{
		"coord": Vector2i(14, 0),
		"name": "敵飛行場",
		"owner": BaseInfo.Owner.ENEMY,
		"base_type": BaseInfo.BaseType.AIRFIELD,
		"income": 200,
	},
	{
		"coord": Vector2i(9, 7),
		"name": "中立都市",
		"owner": BaseInfo.Owner.NEUTRAL,
		"base_type": BaseInfo.BaseType.CITY,
		"income": 300,
	},
	{
		"coord": Vector2i(10, 8),
		"name": "中立飛行場",
		"owner": BaseInfo.Owner.NEUTRAL,
		"base_type": BaseInfo.BaseType.AIRFIELD,
		"income": 280,
	},
]

const PLAYER_UNITS: Array[Dictionary] = [
	{
		"coord": Vector2i(2, 12),
		"name": "戦車",
		"type": Unit.UnitType.TANK,
		"move": 4,
		"range": 1,
		"atk": 5,
		"def": 2,
		"hp": 10,
		"color": PLAYER_COLOR,
	},
	{
		"coord": Vector2i(1, 13),
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
		"coord": Vector2i(3, 13),
		"name": "対空砲",
		"type": Unit.UnitType.AA_GUN,
		"move": 3,
		"range": 2,
		"atk": 5,
		"def": 1,
		"hp": 9,
		"color": PLAYER_COLOR,
		"catalog_id": "aa_gun",
	},
	{
		"coord": Vector2i(5, 14),
		"name": "攻撃ヘリ",
		"type": Unit.UnitType.ATTACK_HELI,
		"move": 6,
		"range": 1,
		"atk": 4,
		"def": 0,
		"hp": 10,
		"color": PLAYER_COLOR,
		"catalog_id": "attack_heli",
	},
]

const ENEMY_UNITS: Array[Dictionary] = [
	{
		"coord": Vector2i(16, 2),
		"name": "敵戦車",
		"type": Unit.UnitType.TANK,
		"move": 4,
		"range": 1,
		"atk": 5,
		"def": 2,
		"hp": 9,
		"color": ENEMY_COLOR,
	},
	{
		"coord": Vector2i(17, 3),
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
		"coord": Vector2i(15, 1),
		"name": "敵砲兵",
		"type": Unit.UnitType.ARTILLERY,
		"move": 2,
		"range": 2,
		"atk": 4,
		"def": 0,
		"hp": 7,
		"color": ENEMY_COLOR,
	},
	{
		"coord": Vector2i(14, 1),
		"name": "敵攻撃ヘリ",
		"type": Unit.UnitType.ATTACK_HELI,
		"move": 6,
		"range": 1,
		"atk": 4,
		"def": 0,
		"hp": 9,
		"color": ENEMY_COLOR,
		"catalog_id": "attack_heli",
	},
]
