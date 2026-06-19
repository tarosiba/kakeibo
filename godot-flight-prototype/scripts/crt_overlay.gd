extends ColorRect
## Fullscreen CRT post-process sampling the game SubViewport.

@export var game_viewport: SubViewport

var _shader_material: ShaderMaterial


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_setup_material()
	visible = FlightSession.crt_enabled


func _setup_material() -> void:
	var shader := load("res://shaders/crt_retro.gdshader") as Shader
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = shader
	material = _shader_material
	_update_shader_uniforms()


func _process(_delta: float) -> void:
	visible = FlightSession.crt_enabled
	if not visible:
		return
	if game_viewport != null:
		_shader_material.set_shader_parameter("screen_texture", game_viewport.get_texture())
	_update_shader_uniforms()


func _update_shader_uniforms() -> void:
	if _shader_material == null:
		return
	var render_size := FlightSession.get_render_size()
	_shader_material.set_shader_parameter("resolution", Vector2(render_size))
