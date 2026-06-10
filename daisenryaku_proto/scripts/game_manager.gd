extends Node

enum State {
	IDLE,
	UNIT_SELECTED,
}

enum TurnPhase {
	PLAYER,
	ENEMY,
}

enum GameResult {
	NONE,
	VICTORY,
	DEFEAT,
}

const ENEMY_ACTION_DELAY: float = 0.45

@onready var hex_map: HexMap = $"../HexMap"
@onready var status_label: Label = %StatusLabel
@onready var turn_label: Label = %TurnLabel
@onready var end_turn_button: Button = %EndTurnButton

var state: State = State.IDLE
var turn_phase: TurnPhase = TurnPhase.PLAYER
var turn_number: int = 1
var selected_unit: Unit = null
var reachable: Dictionary = {}
var attack_targets: Array[HexTile] = []
var game_result: GameResult = GameResult.NONE
var _enemy_turn_running: bool = false


func _ready() -> void:
	hex_map.tile_clicked.connect(_on_tile_clicked)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	_start_player_turn()


func _unhandled_input(event: InputEvent) -> void:
	if turn_phase != TurnPhase.PLAYER or _enemy_turn_running:
		return

	if event is InputEventMouseButton \
			and event.pressed \
			and event.button_index == MOUSE_BUTTON_RIGHT:
		_clear_selection()


func _on_tile_clicked(tile: HexTile) -> void:
	if game_result != GameResult.NONE or turn_phase != TurnPhase.PLAYER or _enemy_turn_running:
		return

	if state == State.UNIT_SELECTED and _is_attack_target(tile):
		_execute_attack(tile)
		return

	if state == State.UNIT_SELECTED and reachable.has(tile.coord):
		_execute_move(tile)
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
	if unit.has_acted:
		_update_status("このユニットは行動済みです。ターン終了を押してください。")
		return

	_clear_selection()
	selected_unit = unit
	reachable = hex_map.get_reachable(unit.coord, unit.move_range)
	attack_targets = hex_map.get_attack_targets(unit)
	state = State.UNIT_SELECTED
	hex_map.show_reachable(reachable)
	hex_map.show_attackable(attack_targets)
	hex_map.show_selected(tile)
	_update_status(
		"選択中: (%d, %d)  HP %d/%d  移動か攻撃を1回だけ実行できます" % [
			unit.coord.x,
			unit.coord.y,
			unit.hp,
			unit.max_hp,
		],
	)


func _execute_move(tile: HexTile) -> void:
	if not hex_map.move_unit(selected_unit, tile):
		_update_status("移動できません。")
		return

	selected_unit.mark_acted()
	_clear_selection()
	_update_status("移動しました。このユニットはターン終了まで待機します。")


func _execute_attack(tile: HexTile) -> void:
	var defender: Unit = tile.unit
	var result: Dictionary = hex_map.attack_unit(selected_unit, tile)
	if not result.success:
		_update_status("攻撃できません。")
		return

	selected_unit.mark_acted()

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
	if _check_victory():
		return


func _on_end_turn_pressed() -> void:
	if game_result != GameResult.NONE or turn_phase != TurnPhase.PLAYER or _enemy_turn_running:
		return

	_clear_selection()
	_start_enemy_turn()


func _start_player_turn() -> void:
	turn_phase = TurnPhase.PLAYER
	hex_map.reset_all_unit_turns()
	end_turn_button.disabled = false
	_update_turn_label()
	_update_status("プレイヤーターンです。ユニットを選んで移動か攻撃を行ってください。")
	_check_victory()


func _start_enemy_turn() -> void:
	if not hex_map.has_living_units(Unit.Faction.ENEMY):
		_on_player_victory()
		return

	turn_phase = TurnPhase.ENEMY
	end_turn_button.disabled = true
	_update_turn_label()
	_update_status("敵ターン...")
	_run_enemy_turn()


func _run_enemy_turn() -> void:
	_enemy_turn_running = true
	await get_tree().create_timer(0.3).timeout

	var enemies: Array[Unit] = hex_map.get_units_by_faction(Unit.Faction.ENEMY)
	for enemy: Unit in enemies:
		if not enemy.is_alive():
			continue

		var action: Dictionary = EnemyAI.decide_action(hex_map, enemy)
		match action.get("type", "wait"):
			"attack":
				var target_tile: HexTile = action.target
				var result: Dictionary = hex_map.attack_unit(enemy, target_tile)
				if result.success:
					_update_status(
						"敵が攻撃! %d ダメージ" % result.damage,
					)
					if result.killed:
						_update_status("敵の攻撃で自軍ユニットが撃破されました!")
					if _check_victory():
						_enemy_turn_running = false
						return
			"move":
				var move_tile: HexTile = action.target
				hex_map.move_unit(enemy, move_tile)
				_update_status("敵が移動しました。")

		enemy.mark_acted()
		await get_tree().create_timer(ENEMY_ACTION_DELAY).timeout

	_enemy_turn_running = false

	if hex_map.has_living_units(Unit.Faction.PLAYER):
		turn_number += 1
		_start_player_turn()
	else:
		_on_player_defeat()


func _check_victory() -> bool:
	if not hex_map.has_living_units(Unit.Faction.ENEMY):
		_on_player_victory()
		return true
	if not hex_map.has_living_units(Unit.Faction.PLAYER):
		_on_player_defeat()
		return true
	return false


func _on_player_victory() -> void:
	game_result = GameResult.VICTORY
	end_turn_button.disabled = true
	_clear_selection()
	_update_turn_label()
	_update_status("勝利! 敵を全滅させました。")


func _on_player_defeat() -> void:
	game_result = GameResult.DEFEAT
	end_turn_button.disabled = true
	_clear_selection()
	_update_turn_label()
	_update_status("敗北... 自軍が全滅しました。")


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


func _update_turn_label() -> void:
	match game_result:
		GameResult.VICTORY:
			turn_label.text = "勝利"
			return
		GameResult.DEFEAT:
			turn_label.text = "敗北"
			return

	match turn_phase:
		TurnPhase.PLAYER:
			turn_label.text = "ターン %d - プレイヤー" % turn_number
		TurnPhase.ENEMY:
			turn_label.text = "ターン %d - 敵" % turn_number


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
