class_name UnitCatalog

const PRODUCE_AT_CITY: String = "city"
const PRODUCE_AT_AIRFIELD: String = "airfield"

const ENTRIES: Array[Dictionary] = [
	{
		"id": "infantry",
		"name": "歩兵",
		"type": Unit.UnitType.INFANTRY,
		"cost": 300,
		"move": 3,
		"range": 1,
		"atk": 3,
		"def": 1,
		"hp": 10,
		"produce_at": PRODUCE_AT_CITY,
	},
	{
		"id": "tank",
		"name": "戦車",
		"type": Unit.UnitType.TANK,
		"cost": 600,
		"move": 4,
		"range": 1,
		"atk": 5,
		"def": 2,
		"hp": 10,
		"produce_at": PRODUCE_AT_CITY,
	},
	{
		"id": "artillery",
		"name": "砲兵",
		"type": Unit.UnitType.ARTILLERY,
		"cost": 500,
		"move": 2,
		"range": 2,
		"atk": 4,
		"def": 0,
		"hp": 10,
		"produce_at": PRODUCE_AT_CITY,
	},
	{
		"id": "aa_gun",
		"name": "対空砲",
		"type": Unit.UnitType.AA_GUN,
		"cost": 600,
		"move": 3,
		"range": 2,
		"atk": 5,
		"def": 1,
		"hp": 10,
		"produce_at": PRODUCE_AT_CITY,
	},
	{
		"id": "attack_heli",
		"name": "攻撃ヘリ",
		"type": Unit.UnitType.ATTACK_HELI,
		"cost": 800,
		"move": 6,
		"range": 1,
		"atk": 4,
		"def": 0,
		"hp": 10,
		"produce_at": PRODUCE_AT_AIRFIELD,
		"uses_fuel": true,
		"fuel_max": 99,
	},
]


static func get_entry(catalog_id: String) -> Dictionary:
	for entry: Dictionary in ENTRIES:
		if entry.id == catalog_id:
			return entry
	return {}


static func get_affordable_entries(funds: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in ENTRIES:
		if entry.cost <= funds:
			result.append(entry)
	return result


static func get_producible_entries(funds: int, base_type: BaseInfo.BaseType) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in ENTRIES:
		if entry.cost > funds:
			continue
		if _matches_base(entry, base_type):
			result.append(entry)
	return result


static func can_produce_at_base(catalog_id: String, base_type: BaseInfo.BaseType) -> bool:
	var entry: Dictionary = get_entry(catalog_id)
	if entry.is_empty():
		return false
	return _matches_base(entry, base_type)


static func _matches_base(entry: Dictionary, base_type: BaseInfo.BaseType) -> bool:
	var produce_at: String = entry.get("produce_at", PRODUCE_AT_CITY)
	if base_type == BaseInfo.BaseType.AIRFIELD:
		return produce_at == PRODUCE_AT_AIRFIELD
	return produce_at == PRODUCE_AT_CITY
