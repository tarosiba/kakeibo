extends Control
## Wireframe out-the-window view with FS1/FS4-style terrain grid.

const SKY_TOP := Color("0a1020")
const SKY_HORIZON := Color("1a2840")
const LINE_NEAR := Color("7cff9a")
const LINE_FAR := Color("3a6a48")
const RUNWAY := Color("9affc8")
const GRID_SIZE := 9
const TILE_SPACING := 420.0

var model: FlightModel
var _heights: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	_build_terrain()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), SKY_TOP)

	if model == null:
		return

	var horizon_y := _project_horizon()
	var grad_steps := 8
	for i in grad_steps:
		var t := float(i) / float(grad_steps)
		var y0 := horizon_y * t
		var y1 := horizon_y * (float(i + 1) / float(grad_steps))
		var c := SKY_TOP.lerp(SKY_HORIZON, t)
		draw_rect(Rect2(0.0, y0, size.x, y1 - y0 + 1.0), c)

	_draw_terrain_lines()
	_draw_runway()
	_draw_crosshair()


func _project_horizon() -> float:
	var pitch_factor := clampf(model.pitch * 0.9, -30.0, 30.0)
	return size.y * 0.5 + pitch_factor * 2.2


func _build_terrain() -> void:
	_heights.resize(GRID_SIZE * GRID_SIZE)
	var center := GRID_SIZE / 2
	for z in GRID_SIZE:
		for x in GRID_SIZE:
			var dx := float(x - center)
			var dz := float(z - center)
			var dist := sqrt(dx * dx + dz * dz)
			var hill := maxf(0.0, 3.8 - dist * 0.9)
			hill += sin(dx * 1.7) * cos(dz * 1.3) * 1.4
			_heights[z * GRID_SIZE + x] = maxf(hill, 0.0) * 55.0


func _terrain_height_at(gx: int, gz: int) -> float:
	gx = clampi(gx, 0, GRID_SIZE - 1)
	gz = clampi(gz, 0, GRID_SIZE - 1)
	return _heights[gz * GRID_SIZE + gx]


func _draw_terrain_lines() -> void:
	var segments: Array = []
	for gz in GRID_SIZE - 1:
		for gx in GRID_SIZE - 1:
			var p00 := _world_to_screen(_grid_point(gx, gz))
			var p10 := _world_to_screen(_grid_point(gx + 1, gz))
			var p01 := _world_to_screen(_grid_point(gx, gz + 1))
			var p11 := _world_to_screen(_grid_point(gx + 1, gz + 1))
			segments.append({"a": p00, "b": p10, "depth": _grid_depth(gx, gz)})
			segments.append({"a": p00, "b": p01, "depth": _grid_depth(gx, gz)})
			segments.append({"a": p00, "b": p11, "depth": _grid_depth(gx, gz)})
			segments.append({"a": p10, "b": p11, "depth": _grid_depth(gx + 1, gz)})
			segments.append({"a": p01, "b": p11, "depth": _grid_depth(gx, gz + 1)})

	segments.sort_custom(func(a, b): return a.depth > b.depth)

	for seg in segments:
		var a: Vector2 = seg.a
		var b: Vector2 = seg.b
		if a.y > size.y + 40.0 and b.y > size.y + 40.0:
			continue
		var depth_t := clampf(1.0 - seg.depth / 9000.0, 0.0, 1.0)
		var col := LINE_FAR.lerp(LINE_NEAR, depth_t)
		draw_line(a, b, col, 1.0)


func _grid_depth(gx: int, gz: int) -> float:
	var world := _grid_point(gx, gz)
	return (world - model.position).length()


func _grid_point(gx: int, gz: int) -> Vector3:
	var offset_x := (float(gx) - GRID_SIZE * 0.5) * TILE_SPACING
	var offset_z := float(gz) * TILE_SPACING
	return Vector3(offset_x, _terrain_height_at(gx, gz), offset_z)


func _draw_runway() -> void:
	var half_w := 28.0
	var start := Vector3(-half_w, 0.5, 200.0)
	var end := Vector3(-half_w, 0.5, -3200.0)
	var start_r := Vector3(half_w, 0.5, 200.0)
	var end_r := Vector3(half_w, 0.5, -3200.0)

	var lines := [
		[start, end],
		[start_r, end_r],
		[Vector3(-6.0, 0.6, 0.0), Vector3(6.0, 0.6, 0.0)],
		[Vector3(0.0, 0.6, -400.0), Vector3(0.0, 0.6, -420.0)],
		[Vector3(0.0, 0.6, -800.0), Vector3(0.0, 0.6, -820.0)],
	]

	for pair in lines:
		var a := _world_to_screen(pair[0])
		var b := _world_to_screen(pair[1])
		draw_line(a, b, RUNWAY, 2.0)


func _draw_crosshair() -> void:
	var c := size * 0.5
	draw_line(c + Vector2(-16.0, 0.0), c + Vector2(-4.0, 0.0), LINE_NEAR, 1.0)
	draw_line(c + Vector2(4.0, 0.0), c + Vector2(16.0, 0.0), LINE_NEAR, 1.0)
	draw_line(c + Vector2(0.0, -10.0), c + Vector2(0.0, -3.0), LINE_NEAR, 1.0)


func _world_to_screen(world: Vector3) -> Vector2:
	var rel := world - model.position
	var basis := _camera_basis()
	var cam_space := Vector3(
		rel.dot(basis.x),
		rel.dot(basis.y),
		rel.dot(basis.z)
	)

	if cam_space.z >= -5.0:
		return Vector2(-9999.0, -9999.0)

	var fov := 68.0
	var scale := (size.y * 0.5) / tan(deg_to_rad(fov * 0.5))
	var sx := size.x * 0.5 + (cam_space.x / -cam_space.z) * scale
	var sy := size.y * 0.5 - (cam_space.y / -cam_space.z) * scale
	return Vector2(sx, sy)


func _camera_basis() -> Basis:
	var pitch_rad := deg_to_rad(model.pitch)
	var heading_rad := deg_to_rad(model.heading)
	var roll_rad := deg_to_rad(model.roll)

	var forward := Vector3(
		sin(heading_rad),
		-sin(pitch_rad),
		-cos(heading_rad)
	).normalized()
	var right := forward.cross(Vector3.UP).normalized()
	if right.length_squared() < 0.001:
		right = Vector3.RIGHT
	var up := right.cross(forward).normalized()

	var basis := Basis(right, up, -forward)
	return basis.rotated(right, roll_rad)
