class_name MapBuilder
extends RefCounted

static func build_tile_map(map_data: Dictionary) -> Dictionary:
	var width: int = int(map_data.get("width", 20))
	var height: int = int(map_data.get("height", 14))
	var default_terrain: String = str(map_data.get("default_terrain", "sea"))
	var tiles: Dictionary = {}

	for r in range(height):
		for q in range(width):
			var key: String = _key(q, r)
			tiles[key] = {
				"q": q,
				"r": r,
				"terrain": default_terrain,
				"owner": "",
				"city_name": ""
			}

	_apply_regions(tiles, map_data.get("regions", []))
	_apply_features(tiles, map_data.get("features", []))
	_apply_explicit_tiles(tiles, map_data.get("tiles", []))

	return tiles


static func _apply_regions(tiles: Dictionary, regions: Variant) -> void:
	if typeof(regions) != TYPE_ARRAY:
		return
	for region_variant in regions:
		if typeof(region_variant) != TYPE_DICTIONARY:
			continue
		var region: Dictionary = region_variant
		var terrain: String = str(region.get("terrain", "clear"))
		var owner: String = str(region.get("owner", ""))
		var q1: int = int(region.get("q1", 0))
		var r1: int = int(region.get("r1", 0))
		var q2: int = int(region.get("q2", q1))
		var r2: int = int(region.get("r2", r1))
		for r in range(mini(r1, r2), maxi(r1, r2) + 1):
			for q in range(mini(q1, q2), maxi(q1, q2) + 1):
				var key: String = _key(q, r)
				if not tiles.has(key):
					continue
				var tile: Dictionary = tiles[key]
				tile["terrain"] = terrain
				if owner != "":
					tile["owner"] = owner


static func _apply_features(tiles: Dictionary, features: Variant) -> void:
	if typeof(features) != TYPE_ARRAY:
		return
	for feature_variant in features:
		if typeof(feature_variant) != TYPE_DICTIONARY:
			continue
		var feature: Dictionary = feature_variant
		var q: int = int(feature.get("q", 0))
		var r: int = int(feature.get("r", 0))
		var key: String = _key(q, r)
		if not tiles.has(key):
			continue
		var tile: Dictionary = tiles[key]
		if feature.has("terrain"):
			tile["terrain"] = str(feature.get("terrain"))
		if feature.has("owner"):
			tile["owner"] = str(feature.get("owner"))
		if feature.has("city_name"):
			tile["city_name"] = str(feature.get("city_name"))


static func _apply_explicit_tiles(tiles: Dictionary, explicit_tiles: Variant) -> void:
	if typeof(explicit_tiles) != TYPE_ARRAY:
		return
	for tile_variant in explicit_tiles:
		if typeof(tile_variant) != TYPE_DICTIONARY:
			continue
		var src: Dictionary = tile_variant
		var q: int = int(src.get("q", 0))
		var r: int = int(src.get("r", 0))
		var key: String = _key(q, r)
		if not tiles.has(key):
			tiles[key] = {"q": q, "r": r, "terrain": "clear", "owner": "", "city_name": ""}
		var tile: Dictionary = tiles[key]
		if src.has("terrain"):
			tile["terrain"] = str(src.get("terrain"))
		if src.has("owner"):
			tile["owner"] = str(src.get("owner"))
		if src.has("city_name"):
			tile["city_name"] = str(src.get("city_name"))


static func _key(q: int, r: int) -> String:
	return "%d,%d" % [q, r]
