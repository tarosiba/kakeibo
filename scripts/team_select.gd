extends Control

const SIDE_HOME := 0
const SIDE_AWAY := 1

const LIST_VISIBLE_ROWS := 6
const PlayerVisualScript := preload("res://scripts/player_visual.gd")

@onready var home_name_label: Label = $MainLayout/TopRow/HomePanel/HomeVBox/HomeNameLabel
@onready var away_name_label: Label = $MainLayout/TopRow/AwayPanel/AwayVBox/AwayNameLabel
@onready var home_super_label: Label = $MainLayout/TopRow/HomePanel/HomeVBox/HomeSuperLabel
@onready var away_super_label: Label = $MainLayout/TopRow/AwayPanel/AwayVBox/AwaySuperLabel
@onready var home_swatch: ColorRect = $MainLayout/TopRow/HomePanel/HomeVBox/HomeSwatch
@onready var away_swatch: ColorRect = $MainLayout/TopRow/AwayPanel/AwayVBox/AwaySwatch
@onready var home_panel: PanelContainer = $MainLayout/TopRow/HomePanel
@onready var away_panel: PanelContainer = $MainLayout/TopRow/AwayPanel
@onready var home_preview: Node2D = $MainLayout/TopRow/HomePanel/HomeVBox/HomePreview
@onready var away_preview: Node2D = $MainLayout/TopRow/AwayPanel/AwayVBox/AwayPreview
@onready var team_list: VBoxContainer = $MainLayout/TeamList
@onready var hint_label: Label = $MainLayout/HintLabel
@onready var status_label: Label = $MainLayout/StatusLabel

var active_side: int = SIDE_HOME
var list_offset: int = 0


func _ready() -> void:
	if GameManager.teams.is_empty():
		status_label.text = "NO TEAMS LOADED"
		return

	_attach_preview(home_preview)
	_attach_preview(away_preview)
	_refresh_ui()


func _attach_preview(preview_root: Node2D) -> void:
	if preview_root.get_child_count() > 0:
		return
	var visual: Node2D = PlayerVisualScript.new()
	visual.name = "Visual"
	visual.scale = Vector2(1.4, 1.4)
	preview_root.add_child(visual)


func _input(event: InputEvent) -> void:
	if GameManager.teams.is_empty():
		return

	if event.is_action_pressed("ui_cancel"):
		GameManager.go_to_title()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("start"):
		GameManager.go_to_match()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		active_side = SIDE_HOME
		_refresh_ui()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		active_side = SIDE_AWAY
		_refresh_ui()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		_change_selection(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		_change_selection(1)
		get_viewport().set_input_as_handled()


func _change_selection(delta: int) -> void:
	if active_side == SIDE_HOME:
		GameManager.set_home_team_index(GameManager.home_team_index + delta)
	else:
		GameManager.set_away_team_index(GameManager.away_team_index + delta)

	_sync_list_offset()
	_refresh_ui()


func _sync_list_offset() -> void:
	var focus_index := GameManager.home_team_index if active_side == SIDE_HOME else GameManager.away_team_index
	if focus_index < list_offset:
		list_offset = focus_index
	elif focus_index >= list_offset + LIST_VISIBLE_ROWS:
		list_offset = focus_index - LIST_VISIBLE_ROWS + 1


func _refresh_ui() -> void:
	var home_team := GameManager.get_home_team()
	var away_team := GameManager.get_away_team()

	home_name_label.text = home_team.get("name", "---")
	away_name_label.text = away_team.get("name", "---")
	home_super_label.text = home_team.get("super_shot", "")
	away_super_label.text = away_team.get("super_shot", "")
	home_swatch.color = GameManager.get_team_color(home_team)
	away_swatch.color = GameManager.get_team_color(away_team)

	_update_panel_highlight(home_panel, active_side == SIDE_HOME)
	_update_panel_highlight(away_panel, active_side == SIDE_AWAY)
	_update_preview(home_preview, home_team)
	_update_preview(away_preview, away_team)
	_rebuild_team_list()

	hint_label.text = "ARROWS: choose  LEFT/RIGHT: side  SPACE: kick off  ESC: back"
	status_label.text = "HOME %s  vs  %s AWAY" % [home_team.get("abbr", ""), away_team.get("abbr", "")]


func _update_panel_highlight(panel: PanelContainer, active: bool) -> void:
	var style := panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if style == null:
		style = StyleBoxFlat.new()
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color("#facc15") if active else Color("#475569")
	style.bg_color = Color(0.08, 0.16, 0.12, 0.95)
	panel.add_theme_stylebox_override("panel", style)


func _update_preview(preview_root: Node2D, team: Dictionary) -> void:
	var visual: Node2D = preview_root.get_node("Visual")
	if visual == null:
		return
	if visual.has_method("set_team_color"):
		visual.set_team_color(GameManager.get_team_color(team))
	if visual.has_method("set_pose"):
		visual.set_pose(visual.Pose.IDLE)


func _rebuild_team_list() -> void:
	for child in team_list.get_children():
		team_list.remove_child(child)
		child.queue_free()

	var end_index := mini(list_offset + LIST_VISIBLE_ROWS, GameManager.teams.size())
	for index in range(list_offset, end_index):
		var team := GameManager.get_team(index)
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 8)
		label.text = _format_list_row(index, team)
		team_list.add_child(label)


func _format_list_row(index: int, team: Dictionary) -> String:
	var markers := ""
	if index == GameManager.home_team_index:
		markers += "H"
	if index == GameManager.away_team_index:
		markers += "A"
	if markers.is_empty():
		markers = " "

	var cursor := ">" if index == _focused_index() else " "
	return "%s%s %s" % [cursor, markers, team.get("name", "---")]


func _focused_index() -> int:
	return GameManager.home_team_index if active_side == SIDE_HOME else GameManager.away_team_index
