@tool
extends Control

const MENU_BG_PATH: String = "res://assets/ui/menu_background.png"

@onready var slot_buttons: VBoxContainer = %SlotButtons
@onready var map_option: OptionButton = %MapOption
@onready var difficulty_option: OptionButton = %DifficultyOption
@onready var difficulty_description: Label = %DifficultyDescription


func _ready() -> void:
	_setup_menu_background()
	if Engine.is_editor_hint():
		return

	SaveGame.migrate_legacy_save()
	_build_slot_buttons()
	_build_map_options()
	_build_difficulty_options()
	_update_difficulty_description()


func _setup_menu_background() -> void:
	var layer: CanvasLayer = get_node_or_null("BackgroundLayer") as CanvasLayer
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = "BackgroundLayer"
		layer.layer = -10
		add_child(layer)
		move_child(layer, 0)

	var bg: TextureRect = layer.get_node_or_null("MenuBackground") as TextureRect
	if bg == null:
		bg = TextureRect.new()
		bg.name = "MenuBackground"
		layer.add_child(bg)

	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.offset_left = 0.0
	bg.offset_top = 0.0
	bg.offset_right = 0.0
	bg.offset_bottom = 0.0
	bg.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bg.grow_vertical = Control.GROW_DIRECTION_BOTH
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	var texture: Texture2D = _load_menu_texture()
	if texture == null:
		push_error("メニュー背景画像を読み込めません: %s" % MENU_BG_PATH)
		bg.visible = false
	else:
		bg.texture = texture
		bg.visible = true
		if not Engine.is_editor_hint():
			print(
				"Menu background loaded: %s (%dx%d)"
				% [MENU_BG_PATH, texture.get_width(), texture.get_height()],
			)

	var overlay: ColorRect = layer.get_node_or_null("DimOverlay") as ColorRect
	if overlay == null:
		overlay = ColorRect.new()
		overlay.name = "DimOverlay"
		layer.add_child(overlay)

	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.offset_left = 0.0
	overlay.offset_top = 0.0
	overlay.offset_right = 0.0
	overlay.offset_bottom = 0.0
	overlay.grow_horizontal = Control.GROW_DIRECTION_BOTH
	overlay.grow_vertical = Control.GROW_DIRECTION_BOTH
	overlay.color = Color(0.02, 0.04, 0.1, 0.15)
	overlay.visible = texture != null


func _load_menu_texture() -> Texture2D:
	var resource_texture: Texture2D = load(MENU_BG_PATH) as Texture2D
	if resource_texture != null:
		return resource_texture

	var image := Image.new()
	var error: Error = image.load(MENU_BG_PATH)
	if error != OK:
		return null

	return ImageTexture.create_from_image(image)


func _build_slot_buttons() -> void:
	for child: Node in slot_buttons.get_children():
		child.queue_free()

	for slot in range(1, SaveGame.MAX_SLOTS + 1):
		var button := Button.new()
		button.text = SaveGame.get_slot_label(slot)
		button.disabled = not SaveGame.exists(slot)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_slot_pressed.bind(slot))
		slot_buttons.add_child(button)


func _build_map_options() -> void:
	map_option.clear()
	for entry: Dictionary in MapRegistry.MAPS:
		if entry.id == "custom" and MapData.load_custom_map() == null:
			continue
		map_option.add_item(MapRegistry.get_display_name(entry.id))
		map_option.set_item_metadata(map_option.item_count - 1, entry.id)


func _build_difficulty_options() -> void:
	difficulty_option.clear()
	for level: int in [
		GameDifficulty.Level.EASY,
		GameDifficulty.Level.NORMAL,
		GameDifficulty.Level.DIFFICULT,
	]:
		difficulty_option.add_item(GameDifficulty.get_label(level))
		difficulty_option.set_item_metadata(difficulty_option.item_count - 1, level)
	difficulty_option.select(GameDifficulty.Level.NORMAL)


func _update_difficulty_description() -> void:
	var level: GameDifficulty.Level = _get_selected_difficulty()
	difficulty_description.text = GameDifficulty.get_description(level)


func _get_selected_map_id() -> String:
	var index: int = map_option.selected
	if index < 0:
		return "map_01"
	return map_option.get_item_metadata(index)


func _get_selected_difficulty() -> GameDifficulty.Level:
	var index: int = difficulty_option.selected
	if index < 0:
		return GameDifficulty.Level.NORMAL
	return difficulty_option.get_item_metadata(index)


func _on_difficulty_option_item_selected(_index: int) -> void:
	_update_difficulty_description()


func _on_slot_pressed(slot: int) -> void:
	var save_data: Dictionary = SaveGame.load_slot(slot)
	if save_data.is_empty():
		_build_slot_buttons()
		return

	GameSession.set_resume_from_save(save_data, slot)
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_start_game_pressed() -> void:
	GameSession.set_new_game(_get_selected_map_id(), _get_selected_difficulty())
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_map_editor_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/map_editor.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
