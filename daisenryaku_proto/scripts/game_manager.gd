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
@onready var units_status_label: Label = %UnitsStatusLabel
@onready var unit_roster: VBoxContainer = %UnitRosterVBox
@onready var end_turn_button: Button = %EndTurnButton
@onready var next_unit_button: Button = %NextUnitButton

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
	hex_map.tile_hovered.connect(_on_tile_hovered)
	hex_map.tile_unhovered.connect(_on_tile_unhovered)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	next_unit_button.pressed.connect(_select_next_available_unit)
	_start_player_turn()


func _unhandled_input(event: InputEvent) -> void:
	if game_result != GameResult.NONE or turn_phase != TurnPhase.PLAYER or _enemy_turn_running:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			_select_next_available_unit()
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
		_update_status("%s は行動済みです。別のユニットを選んでください。" % unit.unit_name)
		return

	_clear_selection()
	selected_unit = unit
	reachable = hex_map.get_reachable(unit.coord, unit.move_range)
	attack_targets = hex_map.get_attack_targets(unit)
	state = State.UNIT_SELECTED
	hex_map.show_reachable(reachable)
	hex_map.show_attackable(attack_targets)
	hex_map.show_attack_predictions(unit, attack_targets)
	hex_map.show_selected(tile)
	_refresh_unit_roster()
	_update_status(_format_selection_message(unit))


func _select_next_available_unit() -> void:
	var idle_units: Array[Unit] = hex_map.get_idle_units_by_faction(Unit.Faction.PLAYER)
	if idle_units.is_empty():
		_clear_selection()
		_update_status("全ユニット行動済み。ターン終了を押してください。")
		return

	var next_unit: Unit = idle_units[0]
	if selected_unit != null:
		var current_index: int = idle_units.find(selected_unit)
		if current_index >= 0:
			next_unit = idle_units[(current_index + 1) % idle_units.size()]

	var tile: HexTile = hex_map.get_tile(next_unit.coord)
	_select_unit(next_unit, tile)


func _select_unit_from_roster(unit: Unit) -> void:
	if game_result != GameResult.NONE or turn_phase != TurnPhase.PLAYER:
		return

	var tile: HexTile = hex_map.get_tile(unit.coord)
	if tile == null:
		return

	_select_unit(unit, tile)


func _execute_move(tile: HexTile) -> void:
	if not hex_map.move_unit(selected_unit, tile):
		_update_status("移動できません。")
		return

	selected_unit.mark_acted()
	_clear_selection()
	_refresh_unit_roster()
	_update_status(_format_post_action_message("移動しました。"))


func _execute_attack(tile: HexTile) -> void:
	var defender: Unit = tile.unit
	var attacker: Unit = selected_unit
	var result: Dictionary = hex_map.attack_unit(attacker, tile)
	if not result.success:
		_update_status("攻撃できません。")
		return

	if is_instance_valid(attacker) and attacker.is_alive():
		attacker.mark_acted()
	_clear_selection()
	_refresh_unit_roster()
	_update_status(_format_post_action_message(_format_attack_message(result, defender)))
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
	next_unit_button.disabled = false
	_update_turn_label()
	_refresh_unit_roster()
	_update_status(_format_turn_start_message())
	_check_victory()


func _start_enemy_turn() -> void:
	if not hex_map.has_living_units(Unit.Faction.ENEMY):
		_on_player_victory()
		return

	turn_phase = TurnPhase.ENEMY
	end_turn_button.disabled = true
	next_unit_button.disabled = true
	_update_turn_label()
	_refresh_unit_roster()
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
				var victim: Unit = target_tile.unit
				var result: Dictionary = hex_map.attack_unit(enemy, target_tile)
				if result.success:
					_update_status(
						"%s が攻撃! %s" % [
							enemy.unit_name,
							_format_enemy_attack_message(result, victim),
						],
					)
					_refresh_unit_roster()
					if _check_victory():
						_enemy_turn_running = false
						return
			"move":
				var move_tile: HexTile = action.target
				hex_map.move_unit(enemy, move_tile)
				_update_status("%s が移動しました。" % enemy.unit_name)

		if is_instance_valid(enemy) and enemy.is_alive():
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
	next_unit_button.disabled = true
	_clear_selection()
	_refresh_unit_roster()
	_update_turn_label()
	_update_status("勝利! 敵を全滅させました。")


func _on_player_defeat() -> void:
	game_result = GameResult.DEFEAT
	end_turn_button.disabled = true
	next_unit_button.disabled = true
	_clear_selection()
	_refresh_unit_roster()
	_update_turn_label()
	_update_status("敗北... 自軍が全滅しました。")


func _refresh_unit_roster() -> void:
	for child: Node in unit_roster.get_children():
		child.queue_free()

	var player_units: Array[Unit] = hex_map.get_units_by_faction(Unit.Faction.PLAYER)
	var idle_count: int = hex_map.count_idle_units(Unit.Faction.PLAYER)
	var total_count: int = player_units.size()

	if total_count == 0:
		units_status_label.text = "自軍ユニット: なし"
		return

	units_status_label.text = "自軍: 行動可能 %d / %d" % [idle_count, total_count]

	for unit: Unit in player_units:
		var button := Button.new()
		var status_mark: String = " [待機]" if unit.has_acted else ""
		var selected_mark: String = " <<" if unit == selected_unit else ""
		button.text = "%s HP %d/%d%s%s" % [
			unit.unit_name,
			unit.hp,
			unit.max_hp,
			status_mark,
			selected_mark,
		]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = unit.has_acted or game_result != GameResult.NONE or turn_phase != TurnPhase.PLAYER
		button.pressed.connect(_select_unit_from_roster.bind(unit))
		unit_roster.add_child(button)


func _format_turn_start_message() -> String:
	var idle_count: int = hex_map.count_idle_units(Unit.Faction.PLAYER)
	if idle_count == 0:
		return "プレイヤーターンです。全ユニット行動済みならターン終了してください。"
	return "プレイヤーターンです。%d 体が行動可能。クリックか Tab で選択。" % idle_count


func _format_selection_message(unit: Unit) -> String:
	return (
		"[%s] (%d, %d)  HP %d/%d  移%d/攻%d/射%d  赤数字=与/被ダメ"
		% [
			unit.unit_name,
			unit.coord.x,
			unit.coord.y,
			unit.hp,
			unit.max_hp,
			unit.move_range,
			unit.attack_power,
			unit.attack_range,
		]
	)


func _format_post_action_message(action_text: String) -> String:
	var idle_count: int = hex_map.count_idle_units(Unit.Faction.PLAYER)
	if idle_count == 0:
		return "%s 全ユニット行動済み。ターン終了を押してください。" % action_text
	return "%s 残り %d 体が行動可能。" % [action_text, idle_count]


func _on_tile_hovered(tile: HexTile) -> void:
	if game_result != GameResult.NONE or state != State.UNIT_SELECTED:
		return

	if _is_attack_target(tile):
		_show_attack_prediction(tile)


func _on_tile_unhovered(_tile: HexTile) -> void:
	if game_result != GameResult.NONE or state != State.UNIT_SELECTED or selected_unit == null:
		return

	_update_status(_format_selection_message(selected_unit))


func _show_attack_prediction(tile: HexTile) -> void:
	var preview: Dictionary = hex_map.predict_attack(selected_unit, tile)
	if preview.is_empty():
		return

	_update_status(
		"[%s] %s" % [
			selected_unit.unit_name,
			_format_prediction_message(preview),
		],
	)


func _format_prediction_message(preview: Dictionary) -> String:
	var outgoing_text: String
	if preview.will_kill_defender:
		outgoing_text = "敵に %d ダメージ (撃破!)" % preview.outgoing_damage
	else:
		outgoing_text = "敵に %d ダメージ (敵HP %d→%d)" % [
			preview.outgoing_damage,
			preview.defender_hp_after + preview.outgoing_damage,
			preview.defender_hp_after,
		]

	if not preview.counter_possible:
		return "攻撃予測: %s  /  反撃なし" % outgoing_text

	var counter_text: String
	if preview.will_kill_attacker:
		counter_text = "反撃 %d ダメージ (自軍撃破!)" % preview.counter_damage
	else:
		counter_text = "反撃 %d ダメージ (自軍HP %d→%d)" % [
			preview.counter_damage,
			preview.attacker_hp_after + preview.counter_damage,
			preview.attacker_hp_after,
		]

	return "攻撃予測: %s  /  %s" % [outgoing_text, counter_text]


func _show_enemy_info(tile: HexTile) -> void:
	var enemy: Unit = tile.unit
	if state == State.UNIT_SELECTED:
		_update_status(
			"[%s] 射程外: (%d, %d)  HP %d/%d  防御 %d" % [
				enemy.unit_name,
				tile.coord.x,
				tile.coord.y,
				enemy.hp,
				enemy.max_hp,
				enemy.defense,
			],
		)
	else:
		_update_status(
			"[%s]: (%d, %d)  HP %d/%d" % [
				enemy.unit_name,
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
	_refresh_unit_roster()


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


func _format_attack_message(result: Dictionary, defender: Unit) -> String:
	var message: String
	if result.killed:
		message = "攻撃! %d ダメージ → %s を撃破!" % [
			result.damage,
			defender.unit_name,
		]
	else:
		message = "攻撃! %d ダメージ → %s HP %d" % [
			result.damage,
			defender.unit_name,
			result.defender_hp,
		]

	return message + _format_counter_message(result.get("counter", {}))


func _format_enemy_attack_message(result: Dictionary, victim: Unit) -> String:
	var message: String
	if result.killed:
		message = "%d ダメージ → %s を撃破!" % [result.damage, victim.unit_name]
	else:
		message = "%d ダメージ → %s HP %d" % [
			result.damage,
			victim.unit_name,
			result.defender_hp,
		]

	return message + _format_counter_message(result.get("counter", {}))


func _format_counter_message(counter: Dictionary) -> String:
	if not counter.get("occurred", false):
		return ""

	var counter_attacker: Unit = counter.counter_attacker
	var counter_victim: Unit = counter.counter_victim
	if counter.killed:
		return "  /  反撃! %d ダメージ → %s を撃破!" % [
			counter.damage,
			counter_victim.unit_name,
		]

	return "  /  反撃! %d ダメージ → %s HP %d" % [
		counter.damage,
		counter_victim.unit_name,
		counter.attacker_hp,
	]


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
