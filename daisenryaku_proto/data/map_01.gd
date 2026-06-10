class_name Map01

# 0=plain, 1=forest, 2=sea, 3=mountain
const DATA: Array = [
	[0, 0, 0, 1, 1, 0, 0, 0, 2, 2, 0, 0],
	[0, 0, 1, 1, 0, 0, 0, 2, 2, 2, 0, 0],
	[0, 1, 1, 0, 0, 0, 0, 0, 2, 0, 0, 0],
	[0, 0, 0, 0, 0, 3, 3, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 3, 3, 3, 3, 0, 0, 1, 0],
	[0, 0, 0, 0, 0, 3, 3, 0, 0, 1, 1, 0],
	[0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0],
	[0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 1, 0, 0, 0, 2, 2, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 2, 2, 2, 2, 0, 0, 0],
]

const PLAYER_START: Vector2i = Vector2i(2, 2)
const ENEMY_START: Vector2i = Vector2i(9, 6)
const ENEMY_NEAR: Vector2i = Vector2i(3, 2)
