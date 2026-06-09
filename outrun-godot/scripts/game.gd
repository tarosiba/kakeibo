extends Node2D
## OutRun風疑似3Dレトロレース — のんびり走行モード

const SEG_LEN := 200.0
const ROAD_W := 2000.0
const CAM_H := 1000.0
const CAM_DEPTH := 0.84
const DRAW_DIST := 200
const MAX_SPEED := 6000.0
const ACCEL := 1200.0
const BRAKE := 3000.0
const DECEL := 400.0
const OFF_ROAD_DECEL := 2500.0
const OFF_ROAD_LIMIT := 3000.0
const CENTRIFUGAL := 0.0004
const GAME_TIME := 60.0

const COL_SKY := [Color("#4ab4f0"), Color("#7ec8f8"), Color("#b8e4ff")]
const COL_GRASS := [Color("#2d8a2d"), Color("#3aaa3a")]
const COL_RUMBLE := [Color("#cc3333"), Color("#ffffff")]
const COL_ROAD := [Color("#666666"), Color("#5a5a5a")]
const COL_LANE := Color.WHITE

var segments: Array = []
var track_len: float = 0.0
var position_z: float = 0.0
var player_x: float = 0.0
var speed: float = 0.0
var start_time: float = 0.0
var record_time: float = 49.1
var stage: int = 1

var traffic: Array = []

var viewport_size: Vector2


func _ready() -> void:
	viewport_size = get_viewport_rect().size
	_build_road()
	traffic = [
		{"offset": 0.3, "speed": 3500.0, "type": "car", "color": Color("#4488cc"), "z": 8000.0},
		{"offset": -0.2, "speed": 2800.0, "type": "bike", "color": Color("#ffcc00"), "z": 25000.0},
	]
	start_time = Time.get_ticks_msec() / 1000.0


func _process(delta: float) -> void:
	_update(delta)
	queue_redraw()


func _update(dt: float) -> void:
	var dx := dt * 4.0
	var accel := Input.is_action_pressed("accelerate")
	var brake := Input.is_action_pressed("brake")
	var left := Input.is_action_pressed("steer_left")
	var right := Input.is_action_pressed("steer_right")

	var seg_idx := int(position_z / SEG_LEN) % segments.size()
	var player_seg: Dictionary = segments[seg_idx]
	var speed_pct := speed / MAX_SPEED
	player_x -= dx * speed_pct * player_seg["curve"] * CENTRIFUGAL

	if left:
		player_x -= dx * 2.0
	if right:
		player_x += dx * 2.0

	if accel:
		speed = minf(speed + ACCEL * dt, MAX_SPEED)
	elif brake:
		speed = maxf(speed - BRAKE * dt, 0.0)
	else:
		speed = maxf(speed - DECEL * dt, 0.0)

	var off := ROAD_W / 2.0 * 0.9
	if player_x < -off or player_x > off:
		speed = maxf(speed - OFF_ROAD_DECEL * dt, OFF_ROAD_LIMIT)

	position_z = fposmod(position_z + speed * dt, track_len)

	for t in traffic:
		t["z"] += t["speed"] * dt
		if t["z"] > track_len:
			t["z"] -= track_len


# ── road building ──────────────────────────────────────────

func _build_road() -> void:
	segments.clear()
	_add_straight(80)
	_add_curve(60, 2.0, 0.0)
	_add_straight(50)
	_add_curve(60, -2.0, 0.0)
	_add_straight(80)
	_add_curve(40, 3.0, 800.0)
	_add_straight(60)
	_add_curve(40, -3.0, -800.0)
	_add_straight(100)
	_add_curve(50, 1.5, 0.0)
	_add_straight(120)
	_add_curve(50, -1.5, 0.0)
	_add_straight(200)

	track_len = segments.size() * SEG_LEN

	for n in range(20, segments.size() - 20, 6):
		if n % 12 == 0:
			segments[n]["sprites"].append({"type": "palm", "offset": -1.4})
			segments[n]["sprites"].append({"type": "palm", "offset": 1.4})
		if n % 8 == 0:
			segments[n]["sprites"].append({"type": "crowd", "offset": -1.8})
			segments[n]["sprites"].append({"type": "crowd", "offset": 1.8})


func _add_segment(curve: float, y: float) -> void:
	segments.append({
		"index": segments.size(),
		"curve": curve,
		"y": y,
		"sprites": [],
	})


func _ease_in(a: float, b: float, t: float) -> float:
	return a + (b - a) * t * t


func _ease_out(a: float, b: float, t: float) -> float:
	return a + (b - a) * (1.0 - (1.0 - t) * (1.0 - t))


func _add_road(enter: int, hold: int, leave: int, curve: float, y: float) -> void:
	var start := segments.size()
	var end_i := start + enter + hold + leave
	for i in range(start, end_i):
		var c := 0.0
		var h := 0.0
		if i < start + enter:
			var t := float(i - start) / float(enter)
			c = _ease_in(0.0, curve, t)
			h = _ease_in(0.0, y, t)
		elif i < start + enter + hold:
			c = curve
			h = y
		else:
			var t := float(i - (start + enter + hold)) / float(leave)
			c = _ease_out(curve, 0.0, t)
			h = _ease_out(y, 0.0, t)
		_add_segment(c, h)


func _add_straight(n: int) -> void:
	_add_road(n, n, n, 0.0, 0.0)


func _add_curve(n: int, curve: float, y: float) -> void:
	_add_road(n, n, n, curve, y)


# ── projection ─────────────────────────────────────────────

func _project(world: Vector3, cam_x: float, cam_y: float, cam_z: float) -> Dictionary:
	var cx := world.x - cam_x
	var cy := world.y - cam_y
	var cz := world.z - cam_z
	var scale := CAM_DEPTH / cz if cz > 0.001 else 0.0
	var w := viewport_size.x
	var h := viewport_size.y
	return {
		"cam_z": cz,
		"x": int(w / 2.0 + scale * cx * w / 2.0),
		"y": int(h / 2.0 - scale * cy * h / 2.0),
		"scale": scale,
		"w": int(scale * ROAD_W * w / 2.0),
	}


func _segment_x(seg_idx: int) -> float:
	var x := 0.0
	var dx := 0.0
	for i in range(seg_idx):
		x += dx
		dx += segments[i % segments.size()]["curve"]
	return x


func _find_segment(z: float) -> Dictionary:
	return segments[int(z / SEG_LEN) % segments.size()]


# ── drawing ────────────────────────────────────────────────

func _draw() -> void:
	var w := viewport_size.x
	var h := viewport_size.y
	_draw_background(w, h)

	var base_seg := int(position_z / SEG_LEN)
	var cam_h: float = CAM_H + float(_find_segment(position_z)["y"])
	var max_y := h
	var visible: Array = []

	for n in range(DRAW_DIST):
		var seg_idx := (base_seg + n) % segments.size()
		var seg: Dictionary = segments[seg_idx]
		var looped := seg_idx < base_seg
		var cam_z := position_z - (track_len if looped else 0.0)

		var wx1 := _segment_x(seg["index"])
		var wx2 := _segment_x(seg["index"] + 1)
		var p1 := _project(Vector3(wx1, seg["y"], seg["index"] * SEG_LEN), player_x * ROAD_W, cam_h, cam_z)
		var p2 := _project(Vector3(wx2, seg["y"], (seg["index"] + 1) * SEG_LEN), player_x * ROAD_W, cam_h, cam_z)

		var color_i := int(seg["index"] / 3) % 2
		visible.append({"seg": seg, "p1": p1, "p2": p2, "cam_z": cam_z, "color_i": color_i, "road_x": wx1})

	for v in visible:
		var p1: Dictionary = v["p1"]
		var p2: Dictionary = v["p2"]
		if p1["cam_z"] <= CAM_DEPTH:
			continue
		if p2["y"] >= max_y:
			continue
		_draw_segment(p1, p2, v["color_i"])
		max_y = p2["y"]

	for i in range(visible.size() - 1, -1, -1):
		var v: Dictionary = visible[i]
		var seg: Dictionary = v["seg"]
		var cam_z: float = v["cam_z"]
		var road_x: float = v["road_x"]

		for sp in seg["sprites"]:
			var sp_pos := _project(
				Vector3(road_x + sp["offset"] * ROAD_W, seg["y"], seg["index"] * SEG_LEN),
				player_x * ROAD_W, cam_h, cam_z
			)
			if sp_pos["cam_z"] <= CAM_DEPTH:
				continue
			if sp["type"] == "palm":
				_draw_palm(sp_pos["x"], sp_pos["y"], sp_pos["scale"])
			elif sp["type"] == "crowd":
				_draw_crowd(sp_pos["x"], sp_pos["y"], sp_pos["scale"])

		for t in traffic:
			var t_seg := int(t["z"] / SEG_LEN) % segments.size()
			if t_seg != seg["index"]:
				continue
			var tx: float = _segment_x(t_seg) + float(t["offset"]) * ROAD_W * 0.5
			var tp := _project(Vector3(tx, 0.0, t["z"]), player_x * ROAD_W, cam_h, cam_z)
			if tp["cam_z"] <= CAM_DEPTH:
				continue
			_draw_traffic(tp["x"], tp["y"], tp["scale"], t["type"], t["color"])

	_draw_player_car(w, h)
	_draw_hud(w, h)


func _draw_poly(pts: PackedVector2Array, color: Color) -> void:
	draw_colored_polygon(pts, color)


func _draw_segment(p1: Dictionary, p2: Dictionary, color_i: int) -> void:
	var w := viewport_size.x
	var x1: float = p1["x"]
	var y1: float = p1["y"]
	var x2: float = p2["x"]
	var y2: float = p2["y"]
	var w1: float = p1["w"]
	var w2: float = p2["w"]

	var l1 := x1 - w1
	var r1 := x1 + w1
	var l2 := x2 - w2
	var r2 := x2 + w2

	_draw_poly(PackedVector2Array([Vector2(0, y2), Vector2(w, y2), Vector2(w, y1), Vector2(0, y1)]), COL_GRASS[color_i])
	_draw_poly(PackedVector2Array([Vector2(l1 - w1 * 0.1, y1), Vector2(l1, y1), Vector2(l2, y2), Vector2(l2 - w2 * 0.1, y2)]), COL_RUMBLE[color_i])
	_draw_poly(PackedVector2Array([Vector2(r1, y1), Vector2(r1 + w1 * 0.1, y1), Vector2(r2 + w2 * 0.1, y2), Vector2(r2, y2)]), COL_RUMBLE[color_i])
	_draw_poly(PackedVector2Array([Vector2(l1, y1), Vector2(r1, y1), Vector2(r2, y2), Vector2(l2, y2)]), COL_ROAD[color_i])

	if color_i == 1:
		var lane_w1 := w1 * 0.02
		var lane_w2 := w2 * 0.02
		var lx1 := x1 - w1 / 3.0
		var lx2 := x2 - w2 / 3.0
		_draw_poly(PackedVector2Array([Vector2(lx1 - lane_w1, y1), Vector2(lx1 + lane_w1, y1), Vector2(lx2 + lane_w2, y2), Vector2(lx2 - lane_w2, y2)]), COL_LANE)
		var bx1 := x1 + w1 / 3.0
		var bx2 := x2 + w2 / 3.0
		_draw_poly(PackedVector2Array([Vector2(bx1 - lane_w1, y1), Vector2(bx1 + lane_w1, y1), Vector2(bx2 + lane_w2, y2), Vector2(bx2 - lane_w2, y2)]), COL_LANE)


func _draw_background(w: float, h: float) -> void:
	for i in range(int(h * 0.55)):
		var t := float(i) / (h * 0.55)
		var c := COL_SKY[0].lerp(COL_SKY[2], t)
		draw_line(Vector2(0, i), Vector2(w, i), c, 1.0)

	draw_rect(Rect2(0, h * 0.42, w, h * 0.08), Color("#3388cc"))
	draw_rect(Rect2(0, h * 0.48, w, h * 0.07), Color("#44aa44"))

	var cloud_data := [[100, 60, 40], [300, 40, 30], [500, 70, 35]]
	for c in cloud_data:
		draw_circle(Vector2(c[0], c[1]), c[2], Color(1, 1, 1, 0.8))
		draw_circle(Vector2(c[0] + c[2] * 0.8, c[1] - c[2] * 0.2), c[2] * 0.7, Color(1, 1, 1, 0.8))
		draw_circle(Vector2(c[0] + c[2] * 1.5, c[1]), c[2] * 0.6, Color(1, 1, 1, 0.8))


func _draw_palm(x: float, y: float, scale: float) -> void:
	var s := scale * viewport_size.x
	if s < 4.0:
		return
	draw_rect(Rect2(x - s * 0.03, y - s * 0.5, s * 0.06, s * 0.5), Color("#8B5A2B"))
	for i in range(6):
		var a := float(i) / 6.0 * TAU
		draw_set_transform(Vector2(x + cos(a) * s * 0.15, y - s * 0.5 + sin(a) * s * 0.05), a, Vector2(s * 0.2, s * 0.06))
		draw_circle(Vector2.ZERO, 1.0, COL_GRASS[0])
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_crowd(x: float, y: float, scale: float) -> void:
	var s := scale * viewport_size.x
	if s < 3.0:
		return
	var colors := [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.MAGENTA, Color.WHITE]
	for i in range(8):
		var px := x + (i - 4) * s * 0.06
		draw_rect(Rect2(px, y - s * 0.12, s * 0.04, s * 0.12), colors[i % colors.size()])
		draw_rect(Rect2(px, y - s * 0.16, s * 0.04, s * 0.04), Color("#ffcc99"))


func _draw_traffic(x: float, y: float, scale: float, type: String, color: Color) -> void:
	var s := scale * viewport_size.x
	if s < 6.0:
		return
	if type == "bike":
		draw_rect(Rect2(x - s * 0.04, y - s * 0.2, s * 0.08, s * 0.15), color)
		draw_circle(Vector2(x - s * 0.05, y - s * 0.05), s * 0.05, Color("#333"))
		draw_circle(Vector2(x + s * 0.05, y - s * 0.05), s * 0.05, Color("#333"))
	else:
		draw_rect(Rect2(x - s * 0.1, y - s * 0.18, s * 0.2, s * 0.14), color)
		draw_rect(Rect2(x - s * 0.08, y - s * 0.22, s * 0.16, s * 0.05), Color("#88ccff"))
		draw_rect(Rect2(x - s * 0.11, y - s * 0.06, s * 0.04, s * 0.04), Color("#222"))
		draw_rect(Rect2(x + s * 0.07, y - s * 0.06, s * 0.04, s * 0.04), Color("#222"))


func _draw_player_car(w: float, h: float) -> void:
	var cx := w / 2.0
	var cy := h - 90.0

	draw_circle(Vector2(cx, cy + 30), 12.0, Color(0, 0, 0, 0.3))

	var body := PackedVector2Array([
		Vector2(cx - 50, cy + 10), Vector2(cx - 45, cy - 20),
		Vector2(cx - 20, cy - 35), Vector2(cx + 20, cy - 35),
		Vector2(cx + 45, cy - 20), Vector2(cx + 50, cy + 10),
	])
	_draw_poly(body, Color("#cc2222"))
	draw_rect(Rect2(cx - 18, cy - 32, 36, 14), Color("#6699cc"))
	draw_rect(Rect2(cx - 12, cy - 28, 10, 10), Color("#ffcc99"))
	draw_rect(Rect2(cx + 4, cy - 28, 10, 10), Color("#ffdd55"))
	draw_rect(Rect2(cx - 48, cy + 2, 14, 10), Color("#222"))
	draw_rect(Rect2(cx + 34, cy + 2, 14, 10), Color("#222"))

	if Input.is_action_pressed("accelerate"):
		_draw_poly(PackedVector2Array([Vector2(cx, cy + 12), Vector2(cx - 6, cy + 28), Vector2(cx + 6, cy + 28)]), Color("#ff8800"))
		_draw_poly(PackedVector2Array([Vector2(cx, cy + 12), Vector2(cx - 3, cy + 22), Vector2(cx + 3, cy + 22)]), Color("#ffcc00"))


func _draw_hud(w: float, h: float) -> void:
	var kph := int(speed / 75.0)
	var rpm := mini(10, int(speed / 600.0))
	var gear := 1 if speed < 500 else (2 if speed < 2000 else (3 if speed < 4000 else 4))
	var elapsed := Time.get_ticks_msec() / 1000.0 - start_time
	var mins := int(elapsed / 60.0)
	var secs := int(fmod(elapsed, 60.0))
	var ms := int(fmod(elapsed, 1.0) * 1000.0)
	var time_left := maxi(0, int(GAME_TIME - elapsed))

	draw_rect(Rect2(0, 0, w, 28), Color(0, 0, 0, 0.5))
	_draw_text("POS 1 / 1", Vector2(10, 19), HORIZONTAL_ALIGNMENT_LEFT, 14)
	_draw_text("TIME %d" % time_left, Vector2(w / 2.0, 19), HORIZONTAL_ALIGNMENT_CENTER, 14)
	_draw_text("CHRONO %02d:%02d:%03d" % [mins, secs, ms], Vector2(w - 10, 14), HORIZONTAL_ALIGNMENT_RIGHT, 12)
	_draw_text("RECORD 00:%02d:%03d" % [int(record_time), int(fmod(record_time, 1.0) * 1000)], Vector2(w - 10, 26), HORIZONTAL_ALIGNMENT_RIGHT, 12)

	var prog := fposmod(position_z, track_len) / track_len
	draw_rect(Rect2(60, 32, w - 120, 8), Color("#333"))
	draw_rect(Rect2(60, 32, (w - 120) * prog, 8), Color("#ff4444"))
	_draw_text("S", Vector2(48, 40), HORIZONTAL_ALIGNMENT_LEFT, 10)
	_draw_text("G", Vector2(w - 48, 40), HORIZONTAL_ALIGNMENT_RIGHT, 10)
	var arrow_x := 60 + (w - 120) * prog
	_draw_poly(PackedVector2Array([Vector2(arrow_x, 28), Vector2(arrow_x - 4, 34), Vector2(arrow_x + 4, 34)]), Color.BLACK)

	draw_rect(Rect2(0, h - 70, w, 70), Color(0, 0, 0, 0.6))
	_draw_gauge(80, h - 35, 50, kph, 340, "KPH", false)
	_draw_gauge(180, h - 35, 40, rpm, 10, "x1000", true)
	_draw_gauge(260, h - 35, 30, 80, 120, "TEMP", false)
	_draw_text(str(gear), Vector2(330, h - 25), HORIZONTAL_ALIGNMENT_CENTER, 28, Color.GREEN)

	_draw_text("STAGE %d" % stage, Vector2(w - 20, h - 50), HORIZONTAL_ALIGNMENT_RIGHT, 14)
	for i in range(4):
		draw_rect(Rect2(w - 100 + i * 22, h - 35, 18, 20), Color("#44cc44") if i < 3 else Color("#226622"))


func _draw_text(text: String, pos: Vector2, align: int, size: int, color: Color = Color.WHITE) -> void:
	var font := ThemeDB.fallback_font
	var offset_x := 0.0
	var str_w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		offset_x = -str_w / 2.0
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		offset_x = -str_w
	draw_string(font, pos + Vector2(offset_x, 0), text, align, -1, size, color)


func _draw_gauge(cx: float, cy: float, r: float, value: float, max_val: float, label: String, is_rpm: bool) -> void:
	var start_a := PI * 0.75
	var end_a := PI * 2.25
	var steps := 24
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var a := lerpf(start_a, end_a, t)
		var inner := Vector2(cx + cos(a) * (r - 2), cy + sin(a) * (r - 2))
		var outer := Vector2(cx + cos(a) * r, cy + sin(a) * r)
		draw_line(inner, outer, Color("#888"), 1.0)

	var angle := start_a + (minf(value, max_val) / max_val) * (end_a - start_a)
	var needle_color := Color.RED if is_rpm else Color.GREEN
	draw_line(Vector2(cx, cy), Vector2(cx + cos(angle) * (r - 5), cy + sin(angle) * (r - 5)), needle_color, 2.0)
	_draw_text(label, Vector2(cx, cy + r + 12), HORIZONTAL_ALIGNMENT_CENTER, 9)
	if label == "KPH":
		_draw_text(str(int(value)), Vector2(cx, cy + 4), HORIZONTAL_ALIGNMENT_CENTER, 11)
