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
var attack_targets: Array[HexTile] = []


func _ready() -> void:
	hex_map.tile_clicked.connect(_on_tile_clicked)
	_update_status("ユニットをクリックして選択してください。")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.pressed \
			and event.button_index == MOUSE_BUTTON_RIGHT:
		_clear_selection()


func _on_tile_clicked(tile: HexTile) -> void:
	if state == State.UNIT_SELECTED and _is_attack_target(tile):
		_execute_attack(tile)
		return

	if state == State.UNIT_SELECTED and reachable.has(tile.coord):
		if hex_map.move_unit(selected_unit, tile):
			_clear_selection()
			_update_status("移動しました。隣接した敵を攻撃できます。")
		return

	if tile.unit != null:
		if tile.unit.faction == Unit.Faction.PLAYER:
			_select_unit(tile.unit, tile)
		else:
			_show_enemy_info(tile)
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
	attack_targets = hex_map.get_attack_targets(unit)
	state = State.UNIT_SELECTED
	hex_map.show_reachable(reachable)
	hex_map.show_attackable(attack_targets)
	hex_map.show_selected(tile)
	_update_status(
		"選択中: (%d, %d)  HP %d/%d  移動 %d  攻撃力 %d  射程 %d" % [
			unit.coord.x,
			unit.coord.y,
			unit.hp,
			unit.max_hp,
			unit.move_range,
			unit.attack_power,
			unit.attack_range,
		],
	)


func _execute_attack(tile: HexTile) -> void:
	var defender: Unit = tile.unit
	var result: Dictionary = hex_map.attack_unit(selected_unit, tile)
	if not result.success:
		_update_status("攻撃できません。")
		return

	var message := "攻撃! %d ダメージ → 敵 HP %d" % [
		result.damage,
		result.defender_hp,
	]
	if result.killed:
		message = "攻撃! %d ダメージ → %s を撃破!" % [
			result.damage,
			_faction_name(defender.faction),
		]

	_clear_selection()
	_update_status(message)


func _show_enemy_info(tile: HexTile) -> void:
	var enemy: Unit = tile.unit
	if state == State.UNIT_SELECTED:
		_update_status(
			"射程外の敵: (%d, %d)  HP %d/%d  防御 %d" % [
				tile.coord.x,
				tile.coord.y,
				enemy.hp,
				enemy.max_hp,
				enemy.defense,
			],
		)
	else:
		_update_status(
			"敵: (%d, %d)  HP %d/%d" % [
				tile.coord.x,
				tile.coord.y,
				enemy.hp,
				enemy.max_hp,
			],
		)


func _is_attack_target(tile: HexTile) -> bool:
	return attack_targets.has(tile)


func _clear_selection() -> void:
	state = State.IDLE
	selected_unit = null
	reachable.clear()
	attack_targets.clear()
	hex_map.clear_highlights()


func _faction_name(faction: Unit.Faction) -> String:
	match faction:
		Unit.Faction.PLAYER:
			return "自軍"
		Unit.Faction.ENEMY:
			return "敵"
		_:
			return "ユニット"


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
