extends Camera2D

@export var min_zoom: float = 0.45
@export var max_zoom: float = 1.8
@export var zoom_step: float = 0.1
@export var pan_button: MouseButton = MOUSE_BUTTON_RIGHT

var _dragging: bool = false
var _drag_start: Vector2 = Vector2.ZERO
var _cam_start: Vector2 = Vector2.ZERO


func _ready() -> void:
	position_smoothing_enabled = true


func focus_on_rect(world_rect: Rect2) -> void:
	if world_rect.size.x <= 1.0 or world_rect.size.y <= 1.0:
		return
	position = world_rect.get_center()
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var zoom_x: float = viewport_size.x / world_rect.size.x
	var zoom_y: float = viewport_size.y / world_rect.size.y
	var fit_zoom: float = minf(zoom_x, zoom_y) * 0.9
	zoom = Vector2.ONE * clampf(fit_zoom, min_zoom, max_zoom)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == pan_button:
		if event.pressed:
			_dragging = true
			_drag_start = event.position
			_cam_start = position
		else:
			_dragging = false
		return

	if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		_apply_zoom(1.0 + zoom_step)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		_apply_zoom(1.0 - zoom_step)


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if not _dragging:
		return
	var delta: Vector2 = (_drag_start - event.position) / zoom
	position = _cam_start + delta


func _apply_zoom(multiplier: float) -> void:
	var new_zoom: float = clampf(zoom.x * multiplier, min_zoom, max_zoom)
	zoom = Vector2.ONE * new_zoom
