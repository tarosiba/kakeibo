extends Control

const MODE_VS := 0
const MODE_TOURNAMENT := 1

@onready var menu_labels: Array[Label] = [
	$CenterContainer/VBoxContainer/MenuVBox/VsLabel,
	$CenterContainer/VBoxContainer/MenuVBox/TournamentLabel,
]
@onready var prompt_label: Label = $CenterContainer/VBoxContainer/PromptLabel

var menu_index: int = 0


func _ready() -> void:
	_refresh_menu()


func _process(_delta: float) -> void:
	if int(Time.get_ticks_msec() / 500) % 2 == 0:
		prompt_label.modulate = Color(1, 1, 1, 1)
	else:
		prompt_label.modulate = Color(1, 1, 1, 0.35)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		menu_index = MODE_VS
		_refresh_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		menu_index = MODE_TOURNAMENT
		_refresh_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("start"):
		if menu_index == MODE_TOURNAMENT:
			GameManager.set_game_mode(GameManager.GameMode.TOURNAMENT)
		else:
			GameManager.set_game_mode(GameManager.GameMode.VS)
		GameManager.go_to_team_select()
		get_viewport().set_input_as_handled()


func _refresh_menu() -> void:
	for index in menu_labels.size():
		var prefix := "> " if index == menu_index else "  "
		if index == MODE_VS:
			menu_labels[index].text = "%sVS MATCH" % prefix
		else:
			menu_labels[index].text = "%sTOURNAMENT" % prefix

	prompt_label.text = "UP/DOWN: mode  SPACE: select"
