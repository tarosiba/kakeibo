class_name HexGrid
extends RefCounted

const HEX_SIZE := 32.0

static func axial_to_world(q: int, r: int) -> Vector2:
	var x := HEX_SIZE * sqrt(3.0) * (q + r / 2.0)
	var y := HEX_SIZE * 1.5 * r
	return Vector2(x, y)

static func neighbors(q: int, r: int) -> Array[Vector2i]:
	return [
		Vector2i(q + 1, r),
		Vector2i(q - 1, r),
		Vector2i(q, r + 1),
		Vector2i(q, r - 1),
		Vector2i(q + 1, r - 1),
		Vector2i(q - 1, r + 1)
	]
