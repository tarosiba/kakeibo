class_name HexGrid
extends RefCounted

const HEX_SIZE: float = 32.0

static func axial_to_world(q: int, r: int) -> Vector2:
	var x: float = HEX_SIZE * sqrt(3.0) * (q + r / 2.0)
	var y: float = HEX_SIZE * 1.5 * r
	return Vector2(x, y)

static func world_to_axial(world_pos: Vector2) -> Vector2i:
	var q: float = ((sqrt(3.0) / 3.0) * world_pos.x - (1.0 / 3.0) * world_pos.y) / HEX_SIZE
	var r: float = ((2.0 / 3.0) * world_pos.y) / HEX_SIZE
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


static func hex_corners() -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(6):
		var angle_rad: float = deg_to_rad(60.0 * float(i) - 30.0)
		points.append(
			Vector2(cos(angle_rad), sin(angle_rad)) * HEX_SIZE
		)
	return points


static func distance(a: Vector2i, b: Vector2i) -> int:
	var aq: int = a.x
	var ar: int = a.y
	var bq: int = b.x
	var br: int = b.y
	return int(
		(abs(aq - bq) + abs(aq + ar - bq - br) + abs(ar - br)) / 2
	)

static func _round_axial(q: float, r: float) -> Vector2i:
	var x: float = q
	var z: float = r
	var y: float = -x - z
	var rx: float = round(x)
	var ry: float = round(y)
	var rz: float = round(z)

	var x_diff: float = abs(rx - x)
	var y_diff: float = abs(ry - y)
	var z_diff: float = abs(rz - z)

	if x_diff > y_diff and x_diff > z_diff:
		rx = -ry - rz
	elif y_diff > z_diff:
		ry = -rx - rz
	else:
		rz = -rx - ry

	return Vector2i(int(rx), int(rz))
