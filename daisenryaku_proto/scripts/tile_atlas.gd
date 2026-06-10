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


static func get_base_texture(owner: BaseInfo.Owner) -> Texture2D:
	if _base_cache.has(owner):
		return _base_cache[owner]

	var texture: Texture2D = _build_base_texture(owner)
	_base_cache[owner] = texture
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


static func _build_base_texture(owner: BaseInfo.Owner) -> Texture2D:
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
