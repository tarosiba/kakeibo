extends Control

@onready var prompt_label: Label = $CenterContainer/VBoxContainer/PromptLabel


func _ready() -> void:
	prompt_label.text = "PRESS START / SPACE"


func _process(_delta: float) -> void:
	if int(Time.get_ticks_msec() / 500) % 2 == 0:
		prompt_label.modulate = Color(1, 1, 1, 1)
	else:
		prompt_label.modulate = Color(1, 1, 1, 0.35)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("start"):
		GameManager.go_to_team_select()
