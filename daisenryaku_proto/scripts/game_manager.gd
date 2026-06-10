extends Node

enum State {
	IDLE,
	UNIT_SELECTED,
}

@onready var hex_map: HexMap = $"../HexMap"
@onready var status_label: Label = %StatusLabel

var state: State = State.IDLE
var selected_unit: Unit = null
var reachable: Dictionary = {}


func _ready() -> void:
	hex_map.tile_clicked.connect(_on_tile_clicked)
	_update_status("ユニットをクリックして選択してください。")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.pressed \
			and event.button_index == MOUSE_BUTTON_RIGHT:
		_clear_selection()


func _on_tile_clicked(tile: HexTile) -> void:
	if state == State.UNIT_SELECTED and reachable.has(tile.coord):
		if hex_map.move_unit(selected_unit, tile):
			_clear_selection()
			_update_status("移動しました。別のユニットを選択してください。")
		return

	if tile.unit != null:
		if tile.unit.faction == Unit.Faction.PLAYER:
			_select_unit(tile.unit, tile)
		else:
			_update_status("敵ユニット (%d, %d)" % [tile.coord.x, tile.coord.y])
		return

	_clear_selection()
	_update_status("(%d, %d) %s" % [
		tile.coord.x,
		tile.coord.y,
		_terrain_name(tile.terrain),
	])


func _select_unit(unit: Unit, tile: HexTile) -> void:
	_clear_selection()
	selected_unit = unit
	reachable = hex_map.get_reachable(unit.coord, unit.move_range)
	state = State.UNIT_SELECTED
	hex_map.show_reachable(reachable)
	hex_map.show_selected(tile)
	_update_status(
		"選択中: (%d, %d)  移動力 %d  右クリックで解除" % [
			unit.coord.x,
			unit.coord.y,
			unit.move_range,
		],
	)


func _clear_selection() -> void:
	state = State.IDLE
	selected_unit = null
	reachable.clear()
	hex_map.clear_highlights()


func _terrain_name(terrain: Terrain.Type) -> String:
	match terrain:
		Terrain.Type.PLAIN:
			return "平原"
		Terrain.Type.FOREST:
			return "森林"
		Terrain.Type.SEA:
			return "海"
		Terrain.Type.MOUNTAIN:
			return "山"
		_:
			return "不明"


func _update_status(text: String) -> void:
	status_label.text = text
