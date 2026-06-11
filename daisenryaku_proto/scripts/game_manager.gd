extends Node

enum State {
	IDLE,
	UNIT_SELECTED,
	BASE_SELECTED,
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
@onready var funds_label: Label = %FundsLabel
@onready var units_status_label: Label = %UnitsStatusLabel
@onready var unit_roster: VBoxContainer = %UnitRosterVBox
@onready var production_panel: PanelContainer = %ProductionPanel
@onready var production_title: Label = %ProductionTitle
@onready var production_buttons: VBoxContainer = %ProductionButtons
@onready var end_turn_button: Button = %EndTurnButton
@onready var next_unit_button: Button = %NextUnitButton
@onready var menu_button: Button = $"../UI/MenuButton"
@onready var save_slot_buttons: HBoxContainer = %SaveSlotButtons
@onready var load_slot_buttons: HBoxContainer = %LoadSlotButtons

var state: State = State.IDLE
var turn_phase: TurnPhase = TurnPhase.PLAYER
var turn_number: int = 1
var selected_unit: Unit = null
var selected_base_tile: HexTile = null
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
	menu_button.pressed.connect(_on_menu_pressed)
	_build_save_load_buttons()
	production_panel.visible = false

	_log_unit_chip_status()

	if GameSession.has_resume_save():
		_apply_save_data(GameSession.take_resume_save())
	else:
		_start_player_turn()


func _log_unit_chip_status() -> void:
	UnitAtlas.clear_cache()
	var custom_loaded: bool = true

	for unit_type: Unit.UnitType in [Unit.UnitType.INFANTRY, Unit.UnitType.TANK, Unit.UnitType.ARTILLERY]:
		var texture: Texture2D = UnitAtlas.get_texture(unit_type, Unit.Faction.PLAYER)
		var source: String = UnitAtlas.get_texture_source(unit_type, Unit.Faction.PLAYER)
		var size_text: String = "missing"
		if texture != null:
			size_text = "%dx%d" % [texture.get_width(), texture.get_height()]
		if not source.begins_with("res://"):
			custom_loaded = false
		print(
			"UnitChip %s -> %s (%s)"
			% [UnitAtlas.TYPE_NAMES.get(unit_type, "?"), source, size_text]
		)

	for unit: Unit in hex_map.units:
		unit._update_visual()

	if custom_loaded:
		_update_status("自作ユニット画像を読み込みました。")
	else:
		_update_status(
			"警告: ユニット画像の読込に失敗。assets/units/ のPNGと scripts/ を確認してください。"
		)


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/boot.tscn")


func _build_save_load_buttons() -> void:
	for container: HBoxContainer in [save_slot_buttons, load_slot_buttons]:
		for child: Node in container.get_children():
			child.queue_free()

	for slot in range(1, SaveGame.MAX_SLOTS + 1):
		var save_button := Button.new()
		save_button.text = "S%d" % slot
		save_button.tooltip_text = SaveGame.get_slot_label(slot)
		save_button.disabled = not _can_save()
		save_button.pressed.connect(_on_save_slot_pressed.bind(slot))
		save_slot_buttons.add_child(save_button)

		var load_button := Button.new()
		load_button.text = "L%d" % slot
		load_button.tooltip_text = "スロット%dをロード" % slot
		load_button.disabled = not _can_load_slot(slot)
		load_button.pressed.connect(_on_load_slot_pressed.bind(slot))
		load_slot_buttons.add_child(load_button)


func _refresh_save_load_buttons() -> void:
	_build_save_load_buttons()


func _on_save_slot_pressed(slot: int) -> void:
	if not _can_save():
		_update_status("今はセーブできません。プレイヤーターン中のみ保存できます。")
		return

	var snapshot: Dictionary = SaveGame.build_snapshot(
		hex_map,
		turn_number,
		turn_phase,
		game_result,
		GameSession.map_source,
		slot,
	)
	if SaveGame.save_snapshot(slot, snapshot):
		_refresh_save_load_buttons()
		_update_status("スロット%dにセーブしました。(ターン %d)" % [slot, turn_number])
	else:
		_update_status("スロット%dへのセーブに失敗しました。" % slot)


func _on_load_slot_pressed(slot: int) -> void:
	if not _can_load_slot(slot):
		_update_status("スロット%dは空です。ロードできません。" % slot)
		return

	var save_data: Dictionary = SaveGame.load_slot(slot)
	if save_data.is_empty():
		_refresh_save_load_buttons()
		_update_status("スロット%dの読み込みに失敗しました。" % slot)
		return

	_apply_save_data(save_data)
	_update_status("スロット%dをロードしました。" % slot)


func _can_load_slot(slot: int) -> bool:
	return SaveGame.exists(slot) \
			and turn_phase == TurnPhase.PLAYER \
			and not _enemy_turn_running


func _can_save() -> bool:
	return game_result == GameResult.NONE \
			and turn_phase == TurnPhase.PLAYER \
			and not _enemy_turn_running


func _apply_save_data(save_data: Dictionary) -> void:
	hex_map.restore_runtime_state(save_data.get("map", {}))
	turn_number = save_data.get("turn_number", 1)
	turn_phase = save_data.get("turn_phase", TurnPhase.PLAYER)
	game_result = save_data.get("game_result", GameResult.NONE)
	_enemy_turn_running = false
	_clear_selection()
	_refresh_unit_roster()
	_update_turn_label()
	_update_funds_label()
	end_turn_button.disabled = game_result != GameResult.NONE or turn_phase != TurnPhase.PLAYER
	next_unit_button.disabled = end_turn_button.disabled
	_refresh_save_load_buttons()

	var slot_text: String = ""
	if GameSession.resume_slot > 0:
		slot_text = "スロット%dの" % GameSession.resume_slot

	match game_result:
		GameResult.VICTORY:
			_update_status("%sセーブデータを読み込みました。勝利状態です。" % slot_text)
		GameResult.DEFEAT:
			_update_status("%sセーブデータを読み込みました。敗北状態です。" % slot_text)
		_:
			_update_status(
				"%sセーブデータを読み込みました。ターン %d から再開します。" % [
					slot_text,
					turn_number,
				],
			)


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


func _on_tile_clicked(tile: HexTile, mouse_button: int = MOUSE_BUTTON_LEFT) -> void:
	if mouse_button != MOUSE_BUTTON_LEFT:
		return
	if game_result != GameResult.NONE or turn_phase != TurnPhase.PLAYER or _enemy_turn_running:
		return

	if state == State.UNIT_SELECTED and _is_attack_target(tile):
		_execute_attack(tile)
		return

	if state == State.UNIT_SELECTED and reachable.has(tile.coord) and tile.unit == null:
		_execute_move(tile)
		return

	if _can_open_production(tile):
		_select_base(tile)
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


func _can_open_production(tile: HexTile) -> bool:
	if tile.base_info == null:
		return false
	if not tile.base_info.is_owned_by(Unit.Faction.PLAYER):
		return false
	if state == State.UNIT_SELECTED:
		if reachable.has(tile.coord) and tile.unit == null:
			return false
	return true


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
	_update_funds_label()
	_update_status(_format_selection_message(unit))


func _select_base(tile: HexTile) -> void:
	_clear_selection()
	selected_base_tile = tile
	state = State.BASE_SELECTED
	hex_map.show_base_selected(tile)
	_refresh_production_panel()
	_update_funds_label()
	_update_status(_format_base_message(tile))


func _select_next_available_unit() -> void:
	var idle_units: Array[Unit] = hex_map.get_idle_units_by_faction(Unit.Faction.PLAYER)
	if idle_units.is_empty():
		_clear_selection()
		_update_status("全ユニット行動済み。基地で生産するかターン終了してください。")
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
	var result: Dictionary = hex_map.move_unit(selected_unit, tile)
	if not result.success:
		_update_status("移動できません。")
		return

	selected_unit.mark_acted()
	_clear_selection()
	_refresh_unit_roster()
	_update_funds_label()

	var message: String = "移動しました。"
	var capture: Dictionary = result.get("capture", {})
	if capture.get("captured", false):
		message = "移動して %s を占領!" % capture.base_name
	_update_status(_format_post_action_message(message))


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
	_update_funds_label()
	_update_status(_format_post_action_message(_format_attack_message(result, defender)))
	if _check_victory():
		return


func _execute_production(catalog_id: String) -> void:
	if selected_base_tile == null:
		return

	var result: Dictionary = hex_map.produce_unit(
		selected_base_tile,
		Unit.Faction.PLAYER,
		catalog_id,
	)
	if not result.success:
		_update_status(result.get("reason", "生産できません。"))
		return

	_refresh_unit_roster()
	_refresh_production_panel()
	_update_funds_label()
	_update_status(
		"%s で %s を生産しました。(-%d)" % [
			selected_base_tile.base_info.base_name,
			result.unit_name,
			result.cost,
		],
	)


func _on_end_turn_pressed() -> void:
	if game_result != GameResult.NONE or turn_phase != TurnPhase.PLAYER or _enemy_turn_running:
		return

	_clear_selection()
	_start_enemy_turn()


func _start_player_turn() -> void:
	turn_phase = TurnPhase.PLAYER
	hex_map.reset_all_unit_turns()
	hex_map.reset_base_production(Unit.Faction.PLAYER)
	var income: int = hex_map.collect_income(Unit.Faction.PLAYER)
	end_turn_button.disabled = false
	next_unit_button.disabled = false
	_refresh_save_load_buttons()
	_update_turn_label()
	_refresh_unit_roster()
	_update_funds_label()
	_update_status(
		"プレイヤーターン。+%d 資金。ユニット操作か自軍基地クリックで生産。" % income,
	)
	_check_victory()


func _start_enemy_turn() -> void:
	if not hex_map.has_living_units(Unit.Faction.ENEMY) \
			and hex_map.get_bases_owned_by(Unit.Faction.ENEMY).is_empty():
		_on_player_victory()
		return

	turn_phase = TurnPhase.ENEMY
	end_turn_button.disabled = true
	next_unit_button.disabled = true
	_refresh_save_load_buttons()
	_clear_selection()
	_update_turn_label()
	_refresh_unit_roster()
	_update_funds_label()
	_update_status("敵ターン...")
	_run_enemy_turn()


func _run_enemy_turn() -> void:
	_enemy_turn_running = true
	await get_tree().create_timer(0.3).timeout

	hex_map.reset_base_production(Unit.Faction.ENEMY)
	var enemy_income: int = hex_map.collect_income(Unit.Faction.ENEMY)
	_update_funds_label()
	_update_status("敵ターン。敵は +%d 資金を獲得。" % enemy_income)
	await get_tree().create_timer(0.35).timeout

	_enemy_produce_units()

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
					_update_funds_label()
					if _check_victory():
						_enemy_turn_running = false
						return
			"move":
				var move_tile: HexTile = action.target
				var move_result: Dictionary = hex_map.move_unit(enemy, move_tile)
				if move_result.success:
					var move_message: String = "%s が移動しました。" % enemy.unit_name
					var capture: Dictionary = move_result.get("capture", {})
					if capture.get("captured", false):
						move_message = "%s が移動して %s を占領!" % [
							enemy.unit_name,
							capture.base_name,
						]
					_update_status(move_message)
					_update_funds_label()

		if is_instance_valid(enemy) and enemy.is_alive():
			enemy.mark_acted()
		await get_tree().create_timer(ENEMY_ACTION_DELAY).timeout

	_enemy_turn_running = false

	if hex_map.has_living_units(Unit.Faction.PLAYER) \
			or not hex_map.get_bases_owned_by(Unit.Faction.PLAYER).is_empty():
		turn_number += 1
		_start_player_turn()
	else:
		_on_player_defeat()


func _enemy_produce_units() -> void:
	for base_tile: HexTile in hex_map.get_bases_owned_by(Unit.Faction.ENEMY):
		var catalog_id: String = EnemyAI.decide_production(
			hex_map,
			base_tile,
			hex_map.get_funds(Unit.Faction.ENEMY),
		)
		if catalog_id == "":
			continue

		var result: Dictionary = hex_map.produce_unit(
			base_tile,
			Unit.Faction.ENEMY,
			catalog_id,
		)
		if result.success:
			_update_status(
				"敵が %s で %s を生産。" % [
					base_tile.base_info.base_name,
					result.unit_name,
				],
			)
			_update_funds_label()
			await get_tree().create_timer(0.35).timeout


func _check_victory() -> bool:
	if not hex_map.has_living_units(Unit.Faction.ENEMY) \
			and hex_map.get_bases_owned_by(Unit.Faction.ENEMY).is_empty():
		_on_player_victory()
		return true
	if not hex_map.has_living_units(Unit.Faction.PLAYER) \
			and hex_map.get_bases_owned_by(Unit.Faction.PLAYER).is_empty():
		_on_player_defeat()
		return true
	return false


func _on_player_victory() -> void:
	game_result = GameResult.VICTORY
	end_turn_button.disabled = true
	next_unit_button.disabled = true
	_refresh_save_load_buttons()
	_clear_selection()
	_refresh_unit_roster()
	_update_turn_label()
	_update_funds_label()
	_update_status("勝利! 敵を全滅し、敵基地を制圧しました。")


func _on_player_defeat() -> void:
	game_result = GameResult.DEFEAT
	end_turn_button.disabled = true
	next_unit_button.disabled = true
	_refresh_save_load_buttons()
	_clear_selection()
	_refresh_unit_roster()
	_update_turn_label()
	_update_funds_label()
	_update_status("敗北... 自軍と基地を失いました。")


func _refresh_production_panel() -> void:
	for child: Node in production_buttons.get_children():
		child.queue_free()

	if selected_base_tile == null or selected_base_tile.base_info == null:
		production_panel.visible = false
		return

	production_panel.visible = true
	var base_name: String = selected_base_tile.base_info.base_name
	var produced: String = "済" if selected_base_tile.base_info.produced_this_turn else "可"
	production_title.text = "%s 生産[%s]" % [base_name, produced]

	if selected_base_tile.base_info.produced_this_turn:
		var done_label := Label.new()
		done_label.text = "この基地は今ターン生産済み"
		production_buttons.add_child(done_label)
		return

	if selected_base_tile.unit != null:
		var blocked_label := Label.new()
		blocked_label.text = "ユニットがいるため生産不可"
		production_buttons.add_child(blocked_label)
		return

	for entry: Dictionary in UnitCatalog.ENTRIES:
		var button := Button.new()
		var affordable: bool = hex_map.can_afford(Unit.Faction.PLAYER, entry.cost)
		button.text = "%s  $%d" % [entry.name, entry.cost]
		button.disabled = not affordable
		button.pressed.connect(_execute_production.bind(entry.id))
		production_buttons.add_child(button)


func _refresh_unit_roster() -> void:
	for child: Node in unit_roster.get_children():
		child.queue_free()

	var player_units: Array[Unit] = hex_map.get_units_by_faction(Unit.Faction.PLAYER)
	var idle_count: int = hex_map.count_idle_units(Unit.Faction.PLAYER)
	var total_count: int = player_units.size()
	var base_count: int = hex_map.get_bases_owned_by(Unit.Faction.PLAYER).size()

	if total_count == 0:
		units_status_label.text = "自軍: 0体  基地 %d  $%d" % [
			base_count,
			hex_map.get_funds(Unit.Faction.PLAYER),
		]
	else:
		units_status_label.text = "自軍: 行動可能 %d/%d  基地 %d" % [
			idle_count,
			total_count,
			base_count,
		]

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


func _update_funds_label() -> void:
	var player_funds: int = hex_map.get_funds(Unit.Faction.PLAYER)
	var enemy_funds: int = hex_map.get_funds(Unit.Faction.ENEMY)
	funds_label.text = "資金  自軍 $%d  /  敵 $%d" % [player_funds, enemy_funds]


func _format_base_message(tile: HexTile) -> String:
	var info: BaseInfo = tile.base_info
	var production_state: String = "生産済み" if info.produced_this_turn else "生産可能"
	if tile.unit != null:
		production_state = "上にユニットあり"
	return "%s (%d,%d)  収入 +%d/ターン  %s" % [
		info.base_name,
		tile.coord.x,
		tile.coord.y,
		info.income,
		production_state,
	]


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
		return "%s 全ユニット行動済み。基地生産かターン終了。" % action_text
	return "%s 残り %d 体が行動可能。" % [action_text, idle_count]


func _on_tile_hovered(tile: HexTile) -> void:
	if game_result != GameResult.NONE:
		return

	if state == State.BASE_SELECTED and tile == selected_base_tile:
		_update_status(_format_base_message(tile))
		return

	if state == State.UNIT_SELECTED and _is_attack_target(tile):
		_show_attack_prediction(tile)


func _on_tile_unhovered(_tile: HexTile) -> void:
	if game_result != GameResult.NONE:
		return

	if state == State.BASE_SELECTED and selected_base_tile != null:
		_update_status(_format_base_message(selected_base_tile))
		return

	if state == State.UNIT_SELECTED and selected_unit != null:
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
		var base_text: String = ""
		if tile.base_info != null:
			base_text = "  [%s]" % tile.base_info.base_name
		_update_status(
			"[%s]%s: (%d, %d)  HP %d/%d" % [
				enemy.unit_name,
				base_text,
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
	selected_base_tile = null
	reachable.clear()
	attack_targets.clear()
	hex_map.clear_highlights()
	production_panel.visible = false
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
