class_name Course
extends RefCounted

const HOLE_NUMBER := 17
const PAR := 5
const LENGTH_METERS := 600.0
const CUP_RADIUS_METERS := 3.0

static func elevation_profile() -> PackedFloat32Array:
	return PackedFloat32Array([
		0.0, 1.2, 2.8, 4.5, 6.0, 5.2, 3.8, 2.0, 0.5, -0.5, 0.0
	])

static func terrain_at(distance_meters: float, lateral_meters: float) -> String:
	var progress := distance_meters / LENGTH_METERS
	if distance_meters >= LENGTH_METERS - 25.0:
		return "green"
	if progress < 0.08:
		return "tee"
	if progress > 0.42 and progress < 0.52 and lateral_meters < -12.0:
		return "bunker"
	if progress < 0.35 and lateral_meters < -18.0:
		return "water"
	if absf(lateral_meters) <= 15.0:
		return "fairway"
	return "rough"

static func terrain_label(terrain: String) -> String:
	match terrain:
		"tee":
			return "スタート地点"
		"fairway":
			return "打ちやすい道"
		"rough":
			return "草むら（打ちにくい）"
		"bunker":
			return "砂場（打ちにくい）"
		"green":
			return "カップのある広場"
		"water":
			return "池（さけよう）"
		_:
			return terrain

static func terrain_hint(terrain: String) -> String:
	match terrain:
		"tee", "fairway", "green":
			return "このまま打てます"
		"rough":
			return "飛距離が少し落ちます"
		"bunker":
			return "飛距離がかなり落ちます"
		"water":
			return "入るとやり直しになります"
		_:
			return ""

static func lie_penalty(terrain: String) -> float:
	match terrain:
		"tee", "fairway", "green":
			return 1.0
		"rough":
			return 0.88
		"bunker":
			return 0.75
		"water":
			return 0.0
		_:
			return 1.0

static func elevation_at(progress: float) -> float:
	var profile := elevation_profile()
	var scaled := clampf(progress, 0.0, 1.0) * float(profile.size() - 1)
	var idx := int(floor(scaled))
	var frac := scaled - float(idx)
	if idx >= profile.size() - 1:
		return profile[profile.size() - 1]
	return lerpf(profile[idx], profile[idx + 1], frac)

static func map_points() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.12, 0.88),
		Vector2(0.18, 0.72),
		Vector2(0.28, 0.58),
		Vector2(0.40, 0.48),
		Vector2(0.55, 0.40),
		Vector2(0.68, 0.32),
		Vector2(0.82, 0.22),
		Vector2(0.90, 0.14),
	])

static func map_position(distance_meters: float, lateral_meters: float) -> Vector2:
	var points := map_points()
	var progress := clampf(distance_meters / LENGTH_METERS, 0.0, 1.0)
	var scaled := progress * float(points.size() - 1)
	var idx := int(floor(scaled))
	var frac := scaled - float(idx)
	var center: Vector2
	if idx >= points.size() - 1:
		center = points[points.size() - 1]
	else:
		center = points[idx].lerp(points[idx + 1], frac)
	var lateral_norm := clampf(lateral_meters / 25.0, -1.0, 1.0)
	return center + Vector2(lateral_norm * 0.06, 0.0)
