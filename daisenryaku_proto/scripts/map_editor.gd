extends Node

enum Tool {
	TERRAIN_PLAIN,
	TERRAIN_FOREST,
	TERRAIN_SEA,
	TERRAIN_MOUNTAIN,
	BASE_PLAYER,
	BASE_ENEMY,
	BASE_NEUTRAL,
	AIRFIELD_PLAYER,
	AIRFIELD_ENEMY,
	AIRFIELD_NEUTRAL,
	UNIT_PLAYER_INFANTRY,
	UNIT_PLAYER_TANK,
	UNIT_PLAYER_ARTILLERY,
	UNIT_PLAYER_AA_GUN,
	UNIT_PLAYER_ATTACK_HELI,
	UNIT_ENEMY_INFANTRY,
	UNIT_ENEMY_TANK,
	UNIT_ENEMY_ARTILLERY,
	UNIT_ENEMY_AA_GUN,
	UNIT_ENEMY_ATTACK_HELI,
}

const TOOL_LABELS: Dictionary = {
	Tool.TERRAIN_PLAIN: "平原",
	Tool.TERRAIN_FOREST: "森林",
	Tool.TERRAIN_SEA: "海",
	Tool.TERRAIN_MOUNTAIN: "山",
	Tool.BASE_PLAYER: "自軍基地",
	Tool.BASE_ENEMY: "敵基地",
	Tool.BASE_NEUTRAL: "中立都市",
	Tool.AIRFIELD_PLAYER: "自軍飛行場",
	Tool.AIRFIELD_ENEMY: "敵飛行場",
	Tool.AIRFIELD_NEUTRAL: "中立飛行場",
	Tool.UNIT_PLAYER_INFANTRY: "自歩兵",
	Tool.UNIT_PLAYER_TANK: "自戦車",
	Tool.UNIT_PLAYER_ARTILLERY: "自砲兵",
	Tool.UNIT_PLAYER_AA_GUN: "自対空砲",
	Tool.UNIT_PLAYER_ATTACK_HELI: "自攻撃ヘリ",
	Tool.UNIT_ENEMY_INFANTRY: "敵歩兵",
	Tool.UNIT_ENEMY_TANK: "敵戦車",
	Tool.UNIT_ENEMY_ARTILLERY: "敵砲兵",
	Tool.UNIT_ENEMY_AA_GUN: "敵対空砲",
	Tool.UNIT_ENEMY_ATTACK_HELI: "敵攻撃ヘリ",
}

@onready var hex_map: HexMap = $HexMap
@onready var status_label: Label = %EditorStatusLabel
@onready var tool_label: Label = %ToolLabel
@onready var tool_buttons: VBoxContainer = %ToolButtons

var map_data: MapData = MapData.from_map01()
var current_tool: Tool = Tool.TERRAIN_PLAIN
var hovered_tile: HexTile = null


func _ready() -> void:
	hex_map.setup_map(map_data)
	hex_map.tile_clicked.connect(_on_tile_clicked)
	hex_map.tile_hovered.connect(_on_tile_hovered)
	hex_map.tile_unhovered.connect(_on_tile_unhovered)
	_build_tool_buttons()
	_update_tool_label()
	_update_status("左クリックで配置 / 右クリックで消去")


func _build_tool_buttons() -> void:
	for child: Node in tool_buttons.get_children():
		child.queue_free()

	for tool_key: Tool in TOOL_LABELS.keys():
		var button := Button.new()
		button.text = TOOL_LABELS[tool_key]
		button.pressed.connect(_set_tool.bind(tool_key))
		tool_buttons.add_child(button)


func _set_tool(tool: Tool) -> void:
	current_tool = tool
	_update_tool_label()


func _update_tool_label() -> void:
	tool_label.text = "選択ツール: %s" % TOOL_LABELS[current_tool]


func _on_tile_hovered(tile: HexTile) -> void:
	hovered_tile = tile
	hex_map.clear_highlights()
	tile.set_highlight("editor")
	_update_status(
		"(%d, %d) 地形:%s" % [
			tile.coord.x,
			tile.coord.y,
			_terrain_name(tile.terrain),
		],
	)


func _on_tile_unhovered(_tile: HexTile) -> void:
	hovered_tile = null
	hex_map.clear_highlights()


func _on_tile_clicked(tile: HexTile, mouse_button: int) -> void:
	if mouse_button == MOUSE_BUTTON_RIGHT:
		_erase_at(tile.coord)
	elif mouse_button == MOUSE_BUTTON_LEFT:
		_apply_tool(tile.coord)
	else:
		return

	hex_map.rebuild_from_data(map_data)
	if hovered_tile != null and hex_map.get_tile(hovered_tile.coord) != null:
		hovered_tile = hex_map.get_tile(hovered_tile.coord)
		hovered_tile.set_highlight("editor")


func _apply_tool(coord: Vector2i) -> void:
	match current_tool:
		Tool.TERRAIN_PLAIN:
			map_data.set_terrain_at(coord, Terrain.Type.PLAIN)
		Tool.TERRAIN_FOREST:
			map_data.set_terrain_at(coord, Terrain.Type.FOREST)
		Tool.TERRAIN_SEA:
			map_data.set_terrain_at(coord, Terrain.Type.SEA)
		Tool.TERRAIN_MOUNTAIN:
			map_data.set_terrain_at(coord, Terrain.Type.MOUNTAIN)
		Tool.BASE_PLAYER:
			_place_base(coord, BaseInfo.Owner.PLAYER, "自軍都市", BaseInfo.BaseType.CITY)
		Tool.BASE_ENEMY:
			_place_base(coord, BaseInfo.Owner.ENEMY, "敵都市", BaseInfo.BaseType.CITY)
		Tool.BASE_NEUTRAL:
			_place_base(coord, BaseInfo.Owner.NEUTRAL, "中立都市", BaseInfo.BaseType.CITY)
		Tool.AIRFIELD_PLAYER:
			_place_base(coord, BaseInfo.Owner.PLAYER, "自軍飛行場", BaseInfo.BaseType.AIRFIELD)
		Tool.AIRFIELD_ENEMY:
			_place_base(coord, BaseInfo.Owner.ENEMY, "敵飛行場", BaseInfo.BaseType.AIRFIELD)
		Tool.AIRFIELD_NEUTRAL:
			_place_base(coord, BaseInfo.Owner.NEUTRAL, "中立飛行場", BaseInfo.BaseType.AIRFIELD)
		Tool.UNIT_PLAYER_INFANTRY:
			_place_unit(coord, Unit.Faction.PLAYER, "infantry")
		Tool.UNIT_PLAYER_TANK:
			_place_unit(coord, Unit.Faction.PLAYER, "tank")
		Tool.UNIT_PLAYER_ARTILLERY:
			_place_unit(coord, Unit.Faction.PLAYER, "artillery")
		Tool.UNIT_PLAYER_AA_GUN:
			_place_unit(coord, Unit.Faction.PLAYER, "aa_gun")
		Tool.UNIT_PLAYER_ATTACK_HELI:
			_place_unit(coord, Unit.Faction.PLAYER, "attack_heli")
		Tool.UNIT_ENEMY_INFANTRY:
			_place_unit(coord, Unit.Faction.ENEMY, "infantry")
		Tool.UNIT_ENEMY_TANK:
			_place_unit(coord, Unit.Faction.ENEMY, "tank")
		Tool.UNIT_ENEMY_ARTILLERY:
			_place_unit(coord, Unit.Faction.ENEMY, "artillery")
		Tool.UNIT_ENEMY_AA_GUN:
			_place_unit(coord, Unit.Faction.ENEMY, "aa_gun")
		Tool.UNIT_ENEMY_ATTACK_HELI:
			_place_unit(coord, Unit.Faction.ENEMY, "attack_heli")


func _erase_at(coord: Vector2i) -> void:
	map_data.set_terrain_at(coord, Terrain.Type.PLAIN)
	map_data.remove_base_at(coord)
	map_data.remove_unit_at(coord)


func _place_base(
	coord: Vector2i,
	owner: BaseInfo.Owner,
	base_name: String,
	base_type: BaseInfo.BaseType = BaseInfo.BaseType.CITY,
) -> void:
	map_data.remove_unit_at(coord)
	var income: int = 300 if owner == BaseInfo.Owner.NEUTRAL else 250
	if base_type == BaseInfo.BaseType.AIRFIELD:
		income = 280 if owner == BaseInfo.Owner.NEUTRAL else 200
	map_data.upsert_base({
		"coord": coord,
		"name": base_name,
		"owner": owner,
		"base_type": base_type,
		"income": income,
	})


func _place_unit(coord: Vector2i, faction: Unit.Faction, catalog_id: String) -> void:
	var entry: Dictionary = UnitCatalog.get_entry(catalog_id)
	if entry.is_empty():
		return

	map_data.remove_unit_at(coord)
	map_data.remove_base_at(coord)

	var unit_config: Dictionary = {
		"coord": coord,
		"name": ("敵" if faction == Unit.Faction.ENEMY else "") + entry.name,
		"type": entry.type,
		"move": entry.move,
		"range": entry.range,
		"atk": entry.atk,
		"def": entry.def,
		"hp": entry.hp,
		"color": Unit.get_faction_color(faction),
		"catalog_id": catalog_id,
	}

	if faction == Unit.Faction.PLAYER:
		map_data.player_units.append(unit_config)
	else:
		map_data.enemy_units.append(unit_config)


func _on_load_default_pressed() -> void:
	map_data = MapData.from_map01()
	hex_map.rebuild_from_data(map_data)
	_update_status("map_01 を読み込みました。")


func _on_save_pressed() -> void:
	map_data.map_name = "custom"
	if map_data.save_custom_map():
		_update_status("カスタムマップを保存しました。")
	else:
		_update_status("保存に失敗しました。")


func _on_test_pressed() -> void:
	GameSession.set_editor_test_map(map_data.duplicate_data())
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/boot.tscn")


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
