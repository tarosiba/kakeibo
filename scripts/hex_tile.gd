class_name HexTile
extends Node2D

@onready var fill: Polygon2D = $Fill
@onready var border: Line2D = $Border
@onready var city_label: Label = $CityLabel

var axial_q: int = 0
var axial_r: int = 0
var terrain_id: String = "clear"
var owner_id: String = ""
var city_name: String = ""

var _base_fill: Color = Color.WHITE
var _base_border: Color = Color(0.2, 0.2, 0.2, 0.5)
var _hover: bool = false
var _move: bool = false
var _select: bool = false


func setup(tile_data: Dictionary, terrain_colors: Dictionary, owner_tints: Dictionary) -> void:
	_ensure_nodes()
	axial_q = int(tile_data.get("q", 0))
	axial_r = int(tile_data.get("r", 0))
	terrain_id = str(tile_data.get("terrain", "clear"))
	owner_id = str(tile_data.get("owner", ""))
	city_name = str(tile_data.get("city_name", ""))

	var corners: PackedVector2Array = HexGrid.hex_corners()
	if fill == null or border == null:
		push_error("HexTile missing Fill or Border node")
		return
	fill.polygon = corners
	border.points = corners

	_base_fill = terrain_colors.get(terrain_id, terrain_colors.get("sea", Color.GRAY)) as Color
	if terrain_id == "sea":
		_base_fill = _base_fill.darkened(0.05)

	if owner_id != "" and owner_tints.has(owner_id):
		var tint: Color = owner_tints[owner_id] as Color
		_base_fill = _base_fill.lerp(tint, 0.22)

	if city_name != "":
		city_label.text = city_name
		city_label.visible = true
	else:
		city_label.visible = false

	_apply_visual()


func set_highlight(mode: String, enabled: bool = true) -> void:
	match mode:
		"hover":
			_hover = enabled
		"move":
			_move = enabled
		"select":
			_select = enabled
		"none":
			_hover = false
			_move = false
			_select = false
	_apply_visual()


func _ensure_nodes() -> void:
	if fill == null:
		fill = get_node_or_null("Fill") as Polygon2D
	if border == null:
		border = get_node_or_null("Border") as Line2D
	if city_label == null:
		city_label = get_node_or_null("CityLabel") as Label


func _apply_visual() -> void:
	_ensure_nodes()
	if fill == null or border == null:
		return
	if _select:
		fill.color = _base_fill.lightened(0.08)
		border.default_color = Color(0.95, 0.95, 0.95, 1.0)
		border.width = 3.0
	elif _move:
		fill.color = _base_fill.lightened(0.18)
		border.default_color = Color(0.2, 0.75, 0.35, 1.0)
		border.width = 2.5
	elif _hover:
		fill.color = _base_fill.lightened(0.12)
		border.default_color = Color(0.95, 0.85, 0.2, 1.0)
		border.width = 2.5
	else:
		fill.color = _base_fill
		border.default_color = _base_border
		border.width = 1.5
