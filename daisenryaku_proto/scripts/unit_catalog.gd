class_name UnitCatalog

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
		"hp": 8,
		"color": Color(0.95, 0.45, 0.15),
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
		"hp": 12,
		"color": Color(0.85, 0.20, 0.20),
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
		"hp": 6,
		"color": Color(0.75, 0.25, 0.55),
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
