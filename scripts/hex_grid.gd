class_name HexGrid
extends RefCounted

const HEX_SIZE := 32.0

static func axial_to_world(q: int, r: int) -> Vector2:
	var x := HEX_SIZE * sqrt(3.0) * (q + r / 2.0)
	var y := HEX_SIZE * 1.5 * r
	return Vector2(x, y)

static func world_to_axial(world_pos: Vector2) -> Vector2i:
	var q := ((sqrt(3.0) / 3.0) * world_pos.x - (1.0 / 3.0) * world_pos.y) / HEX_SIZE
	var r := ((2.0 / 3.0) * world_pos.y) / HEX_SIZE
	return _round_axial(q, r)

static func neighbors(q: int, r: int) -> Array[Vector2i]:
	return [
		Vector2i(q + 1, r),
		Vector2i(q - 1, r),
		Vector2i(q, r + 1),
		Vector2i(q, r - 1),
		Vector2i(q + 1, r - 1),
		Vector2i(q - 1, r + 1)
	]

static func _round_axial(q: float, r: float) -> Vector2i:
	var x := q
	var z := r
	var y := -x - z
	var rx := round(x)
	var ry := round(y)
	var rz := round(z)

	var x_diff := abs(rx - x)
	var y_diff := abs(ry - y)
	var z_diff := abs(rz - z)

	if x_diff > y_diff and x_diff > z_diff:
		rx = -ry - rz
	elif y_diff > z_diff:
		ry = -rx - rz
	else:
		rz = -rx - ry

	return Vector2i(int(rx), int(rz))
