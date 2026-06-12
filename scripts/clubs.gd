class_name Clubs
extends RefCounted

const DATA: Array[Dictionary] = [
	{"id": "1W", "label": "1W", "min": 200, "max": 260, "accuracy": 0.68, "loft": 10.5},
	{"id": "3W", "label": "3W", "min": 175, "max": 215, "accuracy": 0.74, "loft": 15.0},
	{"id": "5I", "label": "5I", "min": 150, "max": 185, "accuracy": 0.80, "loft": 27.0},
	{"id": "7I", "label": "7I", "min": 125, "max": 155, "accuracy": 0.86, "loft": 34.0},
	{"id": "PW", "label": "PW", "min": 90, "max": 120, "accuracy": 0.90, "loft": 46.0},
	{"id": "SW", "label": "SW", "min": 55, "max": 85, "accuracy": 0.92, "loft": 56.0},
	{"id": "PT", "label": "PT", "min": 3, "max": 18, "accuracy": 0.97, "loft": 2.0},
]

static func get_club(index: int) -> Dictionary:
	return DATA[clampi(index, 0, DATA.size() - 1)]

static func club_count() -> int:
	return DATA.size()
