class_name Terrain

enum Type {
	PLAIN,
	FOREST,
	SEA,
	MOUNTAIN,
}

const MOVE_COST: Dictionary = {
	Type.PLAIN: 1,
	Type.FOREST: 2,
	Type.SEA: 99,
	Type.MOUNTAIN: 99,
}

const COLORS: Dictionary = {
	Type.PLAIN: Color(0.45, 0.65, 0.35),
	Type.FOREST: Color(0.22, 0.48, 0.20),
	Type.SEA: Color(0.28, 0.45, 0.78),
	Type.MOUNTAIN: Color(0.55, 0.40, 0.30),
}
