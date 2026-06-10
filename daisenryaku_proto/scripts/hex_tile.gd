class_name HexTile
extends Area2D

signal clicked(tile: HexTile)

@export var coord: Vector2i = Vector2i.ZERO
@export var terrain: Terrain.Type = Terrain.Type.PLAIN

var unit: Unit = null

@onready var polygon: Polygon2D = $Polygon2D
@onready var highlight: Polygon2D = $Highlight


func _ready() -> void:
	input_pickable = true
	_apply_terrain_color()
	highlight.visible = false
	input_event.connect(_on_input_event)


func setup(tile_coord: Vector2i, tile_terrain: Terrain.Type) -> void:
	coord = tile_coord
	terrain = tile_terrain
	if is_node_ready():
		_apply_terrain_color()


func _apply_terrain_color() -> void:
	polygon.color = Terrain.COLORS.get(terrain, Color.GRAY)


func set_highlight(mode: String) -> void:
	match mode:
		"selected":
			highlight.color = Color(1.0, 1.0, 0.2, 0.55)
			highlight.visible = true
		"reachable":
			highlight.color = Color(0.35, 0.75, 1.0, 0.45)
			highlight.visible = true
		"attackable":
			highlight.color = Color(1.0, 0.30, 0.20, 0.55)
			highlight.visible = true
		_:
			highlight.visible = false


func is_passable_for_movement() -> bool:
	return unit == null


func get_move_cost() -> int:
	return Terrain.MOVE_COST.get(terrain, 99)


func _on_input_event(
	_viewport: Node,
	event: InputEvent,
	_shape_idx: int,
) -> void:
	if event is InputEventMouseButton \
			and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)
