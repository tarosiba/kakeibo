extends Control
## Core flight scene rendered inside the low-res SubViewport.

const INSTRUMENT_RATIO := 0.28

@onready var world_view: Control = $Layout/WorldView
@onready var instrument_panel: Control = $Layout/InstrumentPanel
@onready var hud_label: Label = $HudLabel

var model := FlightModel.new()


func _ready() -> void:
	_bind_views()
	_update_layout()
	resized.connect(_update_layout)


func _bind_views() -> void:
	world_view.model = model
	instrument_panel.model = model


func _update_layout() -> void:
	var instrument_h := maxf(56.0, size.y * INSTRUMENT_RATIO)
	world_view.position = Vector2.ZERO
	world_view.size = Vector2(size.x, size.y - instrument_h)
	instrument_panel.position = Vector2(0.0, size.y - instrument_h)
	instrument_panel.size = Vector2(size.x, instrument_h)


func _process(delta: float) -> void:
	_handle_input(delta)
	world_view.queue_redraw()
	instrument_panel.queue_redraw()
	_update_hud()


func _handle_input(delta: float) -> void:
	if Input.is_action_just_pressed("reset_flight"):
		model.reset()

	var pitch_input := Input.get_action_strength("pitch_down") - Input.get_action_strength("pitch_up")
	var roll_input := Input.get_action_strength("roll_right") - Input.get_action_strength("roll_left")
	var yaw_input := Input.get_action_strength("yaw_right") - Input.get_action_strength("yaw_left")
	var throttle_input := Input.get_action_strength("throttle_up") - Input.get_action_strength("throttle_down")
	var braking := Input.is_action_pressed("brake")

	model.apply_controls(pitch_input, roll_input, yaw_input, throttle_input, braking, delta)


func _update_hud() -> void:
	hud_label.text = "FS4 PROTOTYPE  |  TAB: CRT  |  %02d:%02d" % [
		int(model.flight_time) / 60,
		int(model.flight_time) % 60,
	]
