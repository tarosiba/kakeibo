class_name Unit
extends Node2D

enum Faction {
	PLAYER,
	ENEMY,
}

enum UnitType {
	TANK,
	INFANTRY,
	ARTILLERY,
}

const FACTION_COLORS: Dictionary = {
	Faction.PLAYER: Color(0.28, 0.52, 0.92),
	Faction.ENEMY: Color(0.88, 0.22, 0.22),
}
const CHIP_DISPLAY_SIZE: float = 56.0
const STRENGTH_BAR_WIDTH: float = 22.0

@export var unit_name: String = "ユニット"
@export var unit_type: UnitType = UnitType.INFANTRY
@export var move_range: int = 4
@export var attack_range: int = 1
@export var attack_power: int = 4
@export var defense: int = 1
@export var max_hp: int = ReplenishRules.MAX_STRENGTH
@export var faction: Faction = Faction.PLAYER
@export var faction_color: Color = Color(0.28, 0.52, 0.92)

@onready var chip_sprite: Sprite2D = $ChipSprite

var coord: Vector2i = Vector2i.ZERO
var hp: int = ReplenishRules.MAX_STRENGTH
var has_acted: bool = false
var replenish_turns_left: int = 0


static func get_faction_color(faction: Faction) -> Color:
	return FACTION_COLORS.get(faction, Color.WHITE)


func _ready() -> void:
	max_hp = ReplenishRules.MAX_STRENGTH
	hp = mini(hp, max_hp)
	faction_color = get_faction_color(faction)
	_update_visual()


func take_damage(amount: int) -> void:
	hp = maxi(0, hp - amount)
	_update_visual()


func is_alive() -> bool:
	return hp > 0


func is_replenishing() -> bool:
	return replenish_turns_left > 0


func can_take_action() -> bool:
	return is_alive() and not has_acted and not is_replenishing()


func start_replenish() -> void:
	if hp >= max_hp:
		return
	replenish_turns_left = ReplenishRules.get_required_turns(hp)
	mark_acted()
	_update_visual()


func cancel_replenish() -> void:
	replenish_turns_left = 0
	has_acted = false
	_update_visual()


func complete_replenish() -> void:
	hp = max_hp
	replenish_turns_left = 0
	has_acted = false
	_update_visual()


func tick_replenish(hex_map: HexMap) -> bool:
	if replenish_turns_left <= 0:
		return false

	if not ReplenishRules.is_in_supply_zone(hex_map, coord, faction):
		cancel_replenish()
		return true

	replenish_turns_left -= 1
	if replenish_turns_left <= 0:
		complete_replenish()
	else:
		has_acted = true
		_update_visual()
	return true


func mark_acted() -> void:
	has_acted = true
	_update_visual()


func reset_turn() -> void:
	if is_replenishing():
		has_acted = true
	else:
		has_acted = false
	_update_visual()


func get_status_suffix() -> String:
	if is_replenishing():
		return " [補充中:残%d]" % replenish_turns_left
	if has_acted:
		return " [待機]"
	return ""


func _update_visual() -> void:
	faction_color = get_faction_color(faction)
	_update_chip_sprite()
	if is_replenishing():
		modulate = Color(0.75, 0.85, 1.0)
	elif has_acted:
		modulate = Color(0.55, 0.55, 0.55)
	else:
		modulate = Color.WHITE
	queue_redraw()


func _update_chip_sprite() -> void:
	if chip_sprite == null:
		return

	chip_sprite.texture = UnitAtlas.get_texture(unit_type, faction)
	chip_sprite.z_index = 2
	chip_sprite.centered = true
	if UnitAtlas.uses_faction_tint(unit_type, faction):
		chip_sprite.modulate = faction_color
	else:
		chip_sprite.modulate = Color.WHITE

	var texture_size: Vector2 = chip_sprite.texture.get_size() if chip_sprite.texture != null else Vector2.ZERO
	var max_dim: float = maxf(texture_size.x, texture_size.y)
	if max_dim > 0.0:
		var scale_factor: float = CHIP_DISPLAY_SIZE / max_dim
		chip_sprite.scale = Vector2(scale_factor, scale_factor)


func _draw() -> void:
	_draw_strength_bar()
	_draw_strength_number()


func _draw_strength_bar() -> void:
	var bar_height: float = 4.0
	var bar_y: float = -22.0
	var ratio: float = float(hp) / float(max_hp)

	draw_rect(
		Rect2(-STRENGTH_BAR_WIDTH * 0.5, bar_y, STRENGTH_BAR_WIDTH, bar_height),
		Color(0.15, 0.15, 0.15),
	)
	draw_rect(
		Rect2(-STRENGTH_BAR_WIDTH * 0.5, bar_y, STRENGTH_BAR_WIDTH * ratio, bar_height),
		_get_hp_color(ratio),
	)


func _draw_strength_number() -> void:
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 14
	var text: String = str(hp)
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos := Vector2(-text_size.x * 0.5, 18.0)
	draw_rect(
		Rect2(text_pos.x - 2.0, text_pos.y - text_size.y, text_size.x + 4.0, text_size.y + 2.0),
		Color(0.0, 0.0, 0.0, 0.55),
	)
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)


func _get_hp_color(ratio: float) -> Color:
	if ratio > 0.5:
		return Color(0.25, 0.85, 0.30)
	if ratio > 0.25:
		return Color(0.95, 0.75, 0.15)
	return Color(0.90, 0.20, 0.20)
