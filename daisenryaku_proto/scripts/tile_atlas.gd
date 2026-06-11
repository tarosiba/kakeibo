class_name TileAtlas

const TILE_WIDTH: int = 56
const TILE_HEIGHT: int = 64

static var _terrain_cache: Dictionary = {}
static var _base_cache: Dictionary = {}


static func get_terrain_texture(terrain: Terrain.Type) -> Texture2D:
	if _terrain_cache.has(terrain):
		return _terrain_cache[terrain]

	var texture: Texture2D = _build_terrain_texture(terrain)
	_terrain_cache[terrain] = texture
	return texture


static func get_base_texture(owner: BaseInfo.Owner, base_type: BaseInfo.BaseType = BaseInfo.BaseType.CITY) -> Texture2D:
	var key: String = "%d_%d" % [owner, base_type]
	if _base_cache.has(key):
		return _base_cache[key]

	var texture: Texture2D
	if base_type == BaseInfo.BaseType.AIRFIELD:
		texture = _build_airfield_texture(owner)
	else:
		texture = _build_city_texture(owner)
	_base_cache[key] = texture
	return texture


static func _build_terrain_texture(terrain: Terrain.Type) -> Texture2D:
	var palette: Dictionary = _terrain_palette(terrain)
	var image := Image.create(TILE_WIDTH, TILE_HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	var center := Vector2(TILE_WIDTH * 0.5, TILE_HEIGHT * 0.5)
	var radius: float = 27.0

	for y in TILE_HEIGHT:
		for x in TILE_WIDTH:
			if not _point_in_hex(Vector2(x, y), center, radius):
				continue

			var base: Color = palette.base
			var accent: Color = palette.accent
			var shade: Color = palette.shade
			var color: Color = base

			if (x + y) % 3 == 0:
				color = accent
			elif (x * y) % 5 == 0:
				color = shade

			if terrain == Terrain.Type.SEA and (x + y) % 4 == 0:
				color = accent.lightened(0.08)
			if terrain == Terrain.Type.FOREST and (x + y * 2) % 7 == 0:
				color = shade.darkened(0.1)
			if terrain == Terrain.Type.MOUNTAIN and (x % 5 == 0 or y % 4 == 0):
				color = accent

			image.set_pixel(x, y, color)

	_draw_hex_outline(image, center, radius, palette.outline)
	return ImageTexture.create_from_image(image)


static func _build_city_texture(owner: BaseInfo.Owner) -> Texture2D:
	var image := Image.create(20, 18, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	var roof: Color
	var wall: Color
	match owner:
		BaseInfo.Owner.PLAYER:
			roof = Color(0.85, 0.30, 0.25)
			wall = Color(0.65, 0.20, 0.18)
		BaseInfo.Owner.ENEMY:
			roof = Color(0.30, 0.50, 0.85)
			wall = Color(0.20, 0.35, 0.65)
		_:
			roof = Color(0.70, 0.70, 0.72)
			wall = Color(0.50, 0.50, 0.52)

	for y in 18:
		for x in 20:
			if y >= 8 and y < 16 and x >= 3 and x < 17:
				image.set_pixel(x, y, wall)
			elif y >= 2 and y < 9 and x >= 5 and x < 15:
				image.set_pixel(x, y, roof)
			elif y >= 14 and x >= 8 and x < 12:
				image.set_pixel(x, y, Color(0.15, 0.10, 0.08))

	return ImageTexture.create_from_image(image)


static func _build_airfield_texture(owner: BaseInfo.Owner) -> Texture2D:
	var image := Image.create(24, 20, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	var concrete: Color = Color(0.42, 0.44, 0.48)
	var stripe: Color = Color(0.95, 0.82, 0.18)
	var tower: Color
	var accent: Color
	match owner:
		BaseInfo.Owner.PLAYER:
			tower = Color(0.82, 0.28, 0.24)
			accent = Color(0.95, 0.35, 0.30)
		BaseInfo.Owner.ENEMY:
			tower = Color(0.28, 0.48, 0.82)
			accent = Color(0.35, 0.55, 0.95)
		_:
			tower = Color(0.62, 0.64, 0.68)
			accent = Color(0.78, 0.80, 0.84)

	for y in 20:
		for x in 24:
			if y >= 11 and y < 18 and x >= 2 and x < 22:
				image.set_pixel(x, y, concrete)
			elif y >= 4 and y < 12 and x >= 16 and x < 20:
				image.set_pixel(x, y, tower)
			elif y >= 2 and y < 5 and x >= 17 and x < 19:
				image.set_pixel(x, y, accent)

	for x in range(4, 20, 3):
		for y in range(13, 17):
			image.set_pixel(x, y, stripe)

	for y in range(14, 16):
		for x in range(8, 14):
			image.set_pixel(x, y, Color(0.95, 0.95, 0.98))

	_draw_circle_mark(image, Vector2i(11, 15), 2, stripe)
	_set_px(image, 10, 14, stripe)
	_set_px(image, 12, 14, stripe)
	_set_px(image, 11, 13, stripe)
	_set_px(image, 11, 16, stripe)

	return ImageTexture.create_from_image(image)


static func _draw_circle_mark(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			if Vector2i(x, y).distance_to(center) <= float(radius) + 0.4:
				_set_px(image, x, y, color)


static func _set_px(image: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
		image.set_pixel(x, y, color)


static func _terrain_palette(terrain: Terrain.Type) -> Dictionary:
	match terrain:
		Terrain.Type.FOREST:
			return {
				"base": Color(0.20, 0.44, 0.18),
				"accent": Color(0.28, 0.56, 0.22),
				"shade": Color(0.12, 0.30, 0.10),
				"outline": Color(0.08, 0.18, 0.06),
			}
		Terrain.Type.SEA:
			return {
				"base": Color(0.18, 0.38, 0.72),
				"accent": Color(0.30, 0.52, 0.86),
				"shade": Color(0.10, 0.26, 0.52),
				"outline": Color(0.06, 0.16, 0.34),
			}
		Terrain.Type.MOUNTAIN:
			return {
				"base": Color(0.50, 0.38, 0.30),
				"accent": Color(0.66, 0.54, 0.44),
				"shade": Color(0.34, 0.26, 0.20),
				"outline": Color(0.20, 0.14, 0.10),
			}
		_:
			return {
				"base": Color(0.42, 0.62, 0.32),
				"accent": Color(0.52, 0.72, 0.40),
				"shade": Color(0.30, 0.48, 0.24),
				"outline": Color(0.16, 0.28, 0.10),
			}


static func _point_in_hex(point: Vector2, center: Vector2, radius: float) -> bool:
	var dx: float = absf(point.x - center.x)
	var dy: float = absf(point.y - center.y)
	var half_w: float = radius * 0.8660254
	if dx > half_w or dy > radius:
		return false
	return half_w * radius - half_w * dy - radius * 0.5 * dx >= 0.0


static func _draw_hex_outline(
	image: Image,
	center: Vector2,
	radius: float,
	outline: Color,
) -> void:
	var points: PackedVector2Array = HexCoord.polygon_points(radius)
	for i in points.size():
		var a: Vector2 = center + points[i]
		var b: Vector2 = center + points[(i + 1) % points.size()]
		_draw_line(image, a, b, outline)


static func _draw_line(image: Image, from: Vector2, to: Vector2, color: Color) -> void:
	var delta: Vector2 = to - from
	var steps: int = maxi(absi(int(delta.x)), absi(int(delta.y)))
	if steps == 0:
		return
	for step in steps + 1:
		var t: float = float(step) / float(steps)
		var point: Vector2 = from.lerp(to, t)
		var x: int = int(point.x)
		var y: int = int(point.y)
		if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
			image.set_pixel(x, y, color)
