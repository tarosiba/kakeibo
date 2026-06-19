extends Node
## Global flight session settings (CRT toggle, low-res scale).

var crt_enabled: bool = true
var render_scale: float = 1.0

const BASE_WIDTH := 320
const BASE_HEIGHT := 200

func get_render_size() -> Vector2i:
	return Vector2i(
		int(BASE_WIDTH * render_scale),
		int(BASE_HEIGHT * render_scale)
	)
