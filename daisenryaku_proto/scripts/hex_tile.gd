class_name HexTile
extends Area2D

signal clicked(tile: HexTile, mouse_button: int)
signal hovered(tile: HexTile)
signal unhovered(tile: HexTile)

@export var coord: Vector2i = Vector2i.ZERO
@export var terrain: Terrain.Type = Terrain.Type.PLAIN

var unit: Unit = null
var base_info: BaseInfo = null

@onready var terrain_sprite: Sprite2D = $TerrainSprite
@onready var polygon: Polygon2D = $Polygon2D
@onready var highlight: Polygon2D = $Highlight
@onready var base_sprite: Sprite2D = $BaseSprite
@onready var damage_label: Label = $DamageLabel


func _ready() -> void:
	input_pickable = true
	monitoring = true
	polygon.visible = false
	_apply_terrain_visual()
	highlight.visible = false
	_update_base_display()
	set_damage_preview("")
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func setup(tile_coord: Vector2i, tile_terrain: Terrain.Type) -> void:
	coord = tile_coord
	terrain = tile_terrain
	if is_node_ready():
		_apply_terrain_visual()
		_update_base_display()


func set_base(info: BaseInfo) -> void:
	base_info = info
	if is_node_ready():
		_update_base_display()


func _update_base_display() -> void:
	if base_info == null:
		base_sprite.visible = false
		return

	base_sprite.visible = true
	base_sprite.texture = TileAtlas.get_base_texture(base_info.owner, base_info.base_type)


func _apply_terrain_visual() -> void:
	terrain_sprite.texture = TileAtlas.get_terrain_texture(terrain)


func set_damage_preview(text: String) -> void:
	damage_label.text = text
	damage_label.visible = text != ""


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
		"base":
			highlight.color = Color(0.95, 0.75, 0.20, 0.55)
			highlight.visible = true
		"editor":
			highlight.color = Color(0.95, 0.95, 1.0, 0.45)
			highlight.visible = true
		_:
			highlight.visible = false


func is_passable_for_movement() -> bool:
	return unit == null


func get_move_cost() -> int:
	return Terrain.MOVE_COST.get(terrain, 99)


func _on_mouse_entered() -> void:
	hovered.emit(self)


func _on_mouse_exited() -> void:
	unhovered.emit(self)


func _on_input_event(
	_viewport: Node,
	event: InputEvent,
	_shape_idx: int,
) -> void:
	if event is InputEventMouseButton and event.pressed:
		clicked.emit(self, event.button_index)
