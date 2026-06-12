class_name Course
extends RefCounted

const HOLE_NUMBER := 17
const PAR := 5
const LENGTH_YARDS := 663
const CUP_RADIUS_YARDS := 2.5

# Elevation samples from tee (0) to green (1), in arbitrary meters.
static func elevation_profile() -> PackedFloat32Array:
	return PackedFloat32Array([
		0.0, 1.2, 2.8, 4.5, 6.0, 5.2, 3.8, 2.0, 0.5, -0.5, 0.0
	])

static func terrain_at(distance_yards: float, lateral_yards: float) -> String:
	var progress := distance_yards / float(LENGTH_YARDS)
	if distance_yards >= LENGTH_YARDS - 28.0:
		return "green"
	if progress < 0.08:
		return "tee"
	# Bunker left of fairway mid-hole.
	if progress > 0.42 and progress < 0.52 and lateral_yards < -14.0:
		return "bunker"
	# Water along the left edge on the opening stretch.
	if progress < 0.35 and lateral_yards < -22.0:
		return "water"
	if absf(lateral_yards) <= 18.0:
		return "fairway"
	return "rough"

static func lie_penalty(terrain: String) -> float:
	match terrain:
		"tee", "fairway", "green":
			return 1.0
		"rough":
			return 0.82
		"bunker":
			return 0.62
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
	# Normalized top-down polyline for minimap rendering.
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

static func map_position(distance_yards: float, lateral_yards: float) -> Vector2:
	var points := map_points()
	var progress := clampf(distance_yards / float(LENGTH_YARDS), 0.0, 1.0)
	var scaled := progress * float(points.size() - 1)
	var idx := int(floor(scaled))
	var frac := scaled - float(idx)
	var center: Vector2
	if idx >= points.size() - 1:
		center = points[points.size() - 1]
	else:
		center = points[idx].lerp(points[idx + 1], frac)
	var lateral_norm := clampf(lateral_yards / 30.0, -1.0, 1.0)
	return center + Vector2(lateral_norm * 0.06, 0.0)
