class_name Clubs
extends RefCounted

# friendly_name: ゴルフ未経験者向けのわかりやすい名前
# name_ja: 画面に表示する短いラベル
const DATA: Array[Dictionary] = [
	{"id": "1W", "name_ja": "遠く", "friendly_name": "遠く飛ばす", "min": 180, "max": 240, "accuracy": 0.88},
	{"id": "3W", "name_ja": "やや遠く", "friendly_name": "やや遠く飛ばす", "min": 150, "max": 200, "accuracy": 0.90},
	{"id": "5I", "name_ja": "ふつう", "friendly_name": "ふつうの距離", "min": 120, "max": 165, "accuracy": 0.92},
	{"id": "7I", "name_ja": "少し", "friendly_name": "少しだけ飛ばす", "min": 90, "max": 130, "accuracy": 0.94},
	{"id": "PW", "name_ja": "ちかく", "friendly_name": "ちかくまで", "min": 60, "max": 95, "accuracy": 0.95},
	{"id": "SW", "name_ja": "すごくちかく", "friendly_name": "すごくちかく", "min": 30, "max": 55, "accuracy": 0.96},
	{"id": "PT", "name_ja": "カップへ", "friendly_name": "カップへ転がす", "min": 3, "max": 15, "accuracy": 0.98},
]

static func get_club(index: int) -> Dictionary:
	return DATA[clampi(index, 0, DATA.size() - 1)]

static func club_count() -> int:
	return DATA.size()
