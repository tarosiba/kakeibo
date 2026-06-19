extends Control
## Root scene: low-res SubViewport + optional CRT overlay.

@onready var game_viewport: SubViewport = $GameViewportContainer/GameViewport
@onready var crt_overlay: ColorRect = $CrtLayer/CrtOverlay
@onready var viewport_container: SubViewportContainer = $GameViewportContainer

const BEZEL_COLOR := Color("101018")


func _ready() -> void:
	_configure_viewport()
	crt_overlay.game_viewport = game_viewport
	_update_viewport_container_size()
	resized.connect(_update_viewport_container_size)


func _configure_viewport() -> void:
	var render_size := FlightSession.get_render_size()
	game_viewport.size = render_size
	game_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	game_viewport.snap_2d_transforms_to_pixel = true
	game_viewport.snap_2d_vertices_to_pixel = true
	viewport_container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	viewport_container.stretch = true


func _update_viewport_container_size() -> void:
	var render_size := FlightSession.get_render_size()
	var aspect := float(render_size.x) / float(render_size.y)
	var max_w := size.x * 0.92
	var max_h := size.y * 0.92
	var target_w := max_w
	var target_h := target_w / aspect
	if target_h > max_h:
		target_h = max_h
		target_w = target_h * aspect

	viewport_container.custom_minimum_size = Vector2(target_w, target_h)
	viewport_container.size = Vector2(target_w, target_h)
	viewport_container.position = Vector2((size.x - target_w) * 0.5, (size.y - target_h) * 0.5)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_crt"):
		FlightSession.crt_enabled = not FlightSession.crt_enabled
		viewport_container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		get_viewport().set_input_as_handled()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BEZEL_COLOR)
