extends Control
## 擬似3Dレイキャストビュー（Ultima Underworld / Wolfenstein風）

const DungeonDataScript = preload("res://scripts/dungeon_data.gd")

const FOV := 1.0
const MAX_DEPTH := 20.0
const WALL_HEIGHT := 1.0

var player_pos := Vector2(2.5, 2.5)
var player_angle := 0.0
var door_open := false

var npcs: Array = []
var items: Array = []

var _crosshair := true


func _ready() -> void:
	custom_minimum_size = Vector2(400, 280)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 10 or h < 10:
		return

	# ceiling & floor
	draw_rect(Rect2(0, 0, w, h / 2.0), Color("#1a1820"))
	draw_rect(Rect2(0, h / 2.0, w, h / 2.0), Color("#2a2018"))

	# walls via raycasting
	var strip_w := 2.0
	var num_rays := int(w / strip_w)
	for i in range(num_rays):
		var ray_angle := player_angle - FOV / 2.0 + FOV * float(i) / float(num_rays)
		var result: Dictionary = _cast_ray(ray_angle)
		var dist: float = result["dist"]
		var side: int = result["side"]
		var wall_h: float = (WALL_HEIGHT / dist) * (w / 2.0)
		var shade := clampf(1.0 - dist / MAX_DEPTH, 0.15, 1.0)
		if side == 1:
			shade *= 0.7
		var base := Color("#6a6a70") if side == 0 else Color("#5a5a60")
		var col := base * shade
		var x := float(i) * strip_w
		draw_rect(Rect2(x, h / 2.0 - wall_h / 2.0, strip_w + 1, wall_h), col)

	# sprite billboards (NPCs & items)
	var sprites: Array = []
	for n in npcs:
		if n.get("talked_away", false):
			continue
		sprites.append({"pos": Vector2(n["x"], n["y"]), "type": "npc", "data": n})
	for it in items:
		if it.get("taken", false):
			continue
		sprites.append({"pos": Vector2(it["x"], it["y"]), "type": "item", "data": it})

	sprites.sort_custom(func(a, b): return _sprite_dist(b) < _sprite_dist(a))

	for sp in sprites:
		_draw_sprite(sp, w, h)

	if _crosshair:
		draw_line(Vector2(w / 2 - 6, h / 2), Vector2(w / 2 + 6, h / 2), Color.RED, 1.0)
		draw_line(Vector2(w / 2, h / 2 - 6), Vector2(w / 2, h / 2 + 6), Color.RED, 1.0)


func _sprite_dist(sp: Dictionary) -> float:
	return player_pos.distance_to(sp["pos"])


func _cast_ray(angle: float) -> Dictionary:
	var sin_a := sin(angle)
	var cos_a := cos(angle)
	var depth := 0.05
	while depth < MAX_DEPTH:
		var tx := int(player_pos.x + sin_a * depth)
		var ty := int(player_pos.y + cos_a * depth)
		if DungeonDataScript.is_wall(tx, ty, door_open):
			var side := 0
			var fx := player_pos.x + sin_a * depth
			var fy := player_pos.y + cos_a * depth
			if absf(fx - roundf(fx)) < 0.05 or absf(fy - roundf(fy)) < 0.05:
				side = 1
			return {"dist": depth, "side": side}
		depth += 0.05
	return {"dist": MAX_DEPTH, "side": 0}


func _draw_sprite(sp: Dictionary, w: float, h: float) -> void:
	var spos: Vector2 = sp["pos"]
	var dx := spos.x - player_pos.x + 0.5
	var dy := spos.y - player_pos.y + 0.5
	var inv_det := cos(player_angle) * sin(player_angle) - sin(player_angle) * cos(player_angle)
	# transform to camera space
	var transform_x := cos(player_angle)
	var transform_y := -sin(player_angle)
	var transform_x2 := sin(player_angle)
	var transform_y2 := cos(player_angle)

	var rel_x := dx * transform_x + dy * transform_y
	var rel_y := dx * transform_x2 + dy * transform_y2
	if rel_y <= 0.1:
		return

	var sprite_screen_x := int((w / 2.0) * (1.0 + rel_x / rel_y / (FOV / 2.0)))
	var sprite_h := absf(int(h / rel_y))
	var sprite_w := sprite_h
	var draw_x := sprite_screen_x - sprite_w / 2
	var draw_y := int(h / 2.0 - sprite_h / 2.0)

	if draw_x + sprite_w < 0 or draw_x > w:
		return

	# wall occlusion check
	var angle_to := atan2(dx, dy) - player_angle
	while angle_to > PI: angle_to -= TAU
	while angle_to < -PI: angle_to += TAU
	if absf(angle_to) > FOV / 2.0 + 0.2:
		return
	var wall_dist: float = _cast_ray(player_angle + angle_to)["dist"]
	if rel_y > wall_dist:
		return

	var shade := clampf(1.0 - rel_y / MAX_DEPTH, 0.2, 1.0)
	if sp["type"] == "npc":
		var n: Dictionary = sp["data"]
		var col: Color = n.get("color", Color("#aaddff")) * shade
		_draw_npc_figure(draw_x, draw_y, sprite_w, sprite_h, col, n.get("name", ""))
	elif sp["type"] == "item":
		var col: Color = Color("#ffdd44") * shade
		draw_rect(Rect2(draw_x + sprite_w * 0.3, draw_y + sprite_h * 0.5, sprite_w * 0.4, sprite_h * 0.3), col)


func _draw_npc_figure(x: float, y: float, sw: float, sh: float, col: Color, _name: String) -> void:
	# ghostly figure
	draw_rect(Rect2(x + sw * 0.25, y + sh * 0.15, sw * 0.5, sh * 0.55), col)
	draw_circle(Vector2(x + sw * 0.5, y + sh * 0.12), sw * 0.18, col)
	# wavy bottom
	for i in range(4):
		var wx := x + sw * (0.2 + i * 0.15)
		draw_circle(Vector2(wx, y + sh * 0.72), sw * 0.1, col * Color(1, 1, 1, 0.6))
