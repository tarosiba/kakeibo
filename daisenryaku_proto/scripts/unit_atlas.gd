class_name UnitAtlas

const CHIP_WIDTH: int = 32
const CHIP_HEIGHT: int = 32

static var _cache: Dictionary = {}


static func get_texture(unit_type: Unit.UnitType, faction: Unit.Faction) -> Texture2D:
	var key: String = "%d_%d" % [unit_type, faction]
	if _cache.has(key):
		return _cache[key]

	var texture: Texture2D = _build_texture(unit_type, faction)
	_cache[key] = texture
	return texture


static func _build_texture(unit_type: Unit.UnitType, faction: Unit.Faction) -> Texture2D:
	var image := Image.create(CHIP_WIDTH, CHIP_HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	var body: Color = Unit.get_faction_color(faction)
	var highlight: Color = body.lightened(0.22)
	var shadow: Color = body.darkened(0.28)
	var outline: Color = Color(0.08, 0.08, 0.10)
	var accent: Color = Color(0.95, 0.95, 0.98)

	match unit_type:
		Unit.UnitType.TANK:
			_draw_tank_chip(image, body, highlight, shadow, outline, accent)
		Unit.UnitType.ARTILLERY:
			_draw_artillery_chip(image, body, highlight, shadow, outline, accent)
		_:
			_draw_infantry_chip(image, body, highlight, shadow, outline, accent)

	return ImageTexture.create_from_image(image)


static func _draw_infantry_chip(
	image: Image,
	body: Color,
	highlight: Color,
	shadow: Color,
	outline: Color,
	accent: Color,
) -> void:
	_fill_rect(image, Rect2i(10, 12, 12, 14), body)
	_fill_rect(image, Rect2i(11, 13, 10, 4), highlight)
	_fill_rect(image, Rect2i(11, 22, 10, 3), shadow)
	_fill_rect(image, Rect2i(13, 8, 6, 6), body)
	_fill_rect(image, Rect2i(14, 9, 4, 2), highlight)
	_set_pixel(image, 15, 10, accent)
	_set_pixel(image, 16, 10, accent)
	_draw_rect_outline(image, Rect2i(10, 12, 12, 14), outline)
	_draw_rect_outline(image, Rect2i(13, 8, 6, 6), outline)
	_set_pixel(image, 9, 18, outline)
	_set_pixel(image, 22, 18, outline)


static func _draw_tank_chip(
	image: Image,
	body: Color,
	highlight: Color,
	shadow: Color,
	outline: Color,
	accent: Color,
) -> void:
	_fill_rect(image, Rect2i(6, 14, 20, 10), body)
	_fill_rect(image, Rect2i(7, 15, 18, 3), highlight)
	_fill_rect(image, Rect2i(7, 20, 18, 3), shadow)
	for track_x in [8, 11, 14, 17, 20, 23]:
		_fill_rect(image, Rect2i(track_x, 22, 2, 2), outline)

	_fill_rect(image, Rect2i(10, 9, 12, 6), body.lightened(0.12))
	_fill_rect(image, Rect2i(11, 10, 10, 2), highlight)
	_fill_rect(image, Rect2i(18, 10, 8, 2), accent)
	_fill_rect(image, Rect2i(25, 10, 2, 2), outline)

	_draw_rect_outline(image, Rect2i(6, 14, 20, 10), outline)
	_draw_rect_outline(image, Rect2i(10, 9, 12, 6), outline)


static func _draw_artillery_chip(
	image: Image,
	body: Color,
	highlight: Color,
	shadow: Color,
	outline: Color,
	accent: Color,
) -> void:
	var center := Vector2i(16, 17)
	for y in range(9, 26):
		for x in range(9, 24):
			if abs(x - center.x) + abs(y - center.y) <= 7:
				var color: Color = body
				if x + y < 25:
					color = highlight
				elif x + y > 31:
					color = shadow
				_set_pixel(image, x, y, color)

	for point: Vector2i in [
		Vector2i(16, 10),
		Vector2i(23, 17),
		Vector2i(16, 24),
		Vector2i(9, 17),
	]:
		_draw_diamond_outline_corner(image, point, outline)

	for x in range(18, 27):
		_set_pixel(image, x, 15, accent)
	_set_pixel(image, 27, 15, outline)
	_set_pixel(image, 28, 15, outline)
	_set_pixel(image, 16, 16, accent)


static func _draw_diamond_outline_corner(image: Image, point: Vector2i, color: Color) -> void:
	for offset: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		_set_pixel(image, point.x + offset.x, point.y + offset.y, color)


static func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			_set_pixel(image, x, y, color)


static func _draw_rect_outline(image: Image, rect: Rect2i, color: Color) -> void:
	for x in range(rect.position.x, rect.position.x + rect.size.x):
		_set_pixel(image, x, rect.position.y, color)
		_set_pixel(image, x, rect.position.y + rect.size.y - 1, color)
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		_set_pixel(image, rect.position.x, y, color)
		_set_pixel(image, rect.position.x + rect.size.x - 1, y, color)


static func _set_pixel(image: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
		return
	image.set_pixel(x, y, color)
