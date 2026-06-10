extends Control

const DungeonDataScript = preload("res://scripts/dungeon_data.gd")

var game: Control


func _draw() -> void:
	if game == null:
		return

	var cell := 14.0
	var ox := 20.0
	var oy := 20.0

	# parchment background
	draw_rect(Rect2(0, 0, size.x, size.y), Color("#c4a86a"))
	draw_rect(Rect2(4, 4, size.x - 8, size.y - 8), Color("#d8c090"))

	for y in range(DungeonDataScript.MAP_H):
		for x in range(DungeonDataScript.MAP_W):
			var key := Vector2i(x, y)
			if not game.seen.get(key, false):
				continue
			var tile: String = DungeonDataScript.get_tile(x, y)
			var px := ox + x * cell
			var py := oy + y * cell
			if tile == '#':
				draw_rect(Rect2(px, py, cell - 1, cell - 1), Color("#4a4030"))
			elif tile == 'D':
				var col := Color("#6a8a50") if game.door_open else Color("#8a7050")
				draw_rect(Rect2(px, py, cell - 1, cell - 1), col)
				draw_rect(Rect2(px + cell * 0.3, py, cell * 0.4, cell - 1), Color("#3a3020"))
			else:
				var visited: bool = game.visited.get(key, false)
				draw_rect(Rect2(px, py, cell - 1, cell - 1),
					Color("#a89060") if visited else Color("#b8a070", 0.5))

	# player marker
	var ppx: float = ox + game.player_pos.x * cell
	var ppy: float = oy + game.player_pos.y * cell
	draw_line(Vector2(ppx - 4, ppy), Vector2(ppx + 4, ppy), Color.YELLOW, 2.0)
	draw_line(Vector2(ppx, ppy - 4), Vector2(ppx, ppy + 4), Color.YELLOW, 2.0)

	# NPC markers
	for n in game.npcs:
		var nk := Vector2i(n["x"], n["y"])
		if game.seen.get(nk, false):
			draw_circle(Vector2(ox + n["x"] * cell + cell / 2, oy + n["y"] * cell + cell / 2), 3, Color.CYAN)

	# labels
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(size.x - 70, 20), "Level 1", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#3a2818"))
	draw_string(font, Vector2(size.x - 90, size.y - 10), "M: 閉じる", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#3a2818"))
