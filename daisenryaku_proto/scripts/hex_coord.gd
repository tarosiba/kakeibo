class_name HexCoord

const SQRT3: float = 1.7320508075688772

const NEIGHBORS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(1, -1),
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
]


static func axial_to_pixel(q: int, r: int, size: float) -> Vector2:
	var x: float = size * (SQRT3 * q + SQRT3 * 0.5 * r)
	var y: float = size * 1.5 * r
	return Vector2(x, y)


static func distance(a: Vector2i, b: Vector2i) -> int:
	var dq: int = a.x - b.x
	var dr: int = a.y - b.y
	var ds: int = -dq - dr
	return maxi(absi(dq), maxi(absi(dr), absi(ds)))


static func pixel_to_axial(pos: Vector2, size: float) -> Vector2i:
	var q: float = (SQRT3 / 3.0 * pos.x - 1.0 / 3.0 * pos.y) / size
	var r: float = (2.0 / 3.0 * pos.y) / size
	return _cube_round(q, -q - r, r)


static func polygon_points(size: float) -> PackedVector2Array:
	var half_width: float = SQRT3 * 0.5 * size
	return PackedVector2Array([
		Vector2(0.0, -size),
		Vector2(half_width, -size * 0.5),
		Vector2(half_width, size * 0.5),
		Vector2(0.0, size),
		Vector2(-half_width, size * 0.5),
		Vector2(-half_width, -size * 0.5),
	])


static func _cube_round(fx: float, fy: float, fz: float) -> Vector2i:
	var rx: int = roundi(fx)
	var ry: int = roundi(fy)
	var rz: int = roundi(fz)

	var x_diff: float = absf(rx - fx)
	var y_diff: float = absf(ry - fy)
	var z_diff: float = absf(rz - fz)

	if x_diff > y_diff and x_diff > z_diff:
		rx = -ry - rz
	elif y_diff > z_diff:
		ry = -rx - rz
	else:
		rz = -rx - ry

	return Vector2i(rx, rz)
