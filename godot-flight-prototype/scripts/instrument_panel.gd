extends Control
## Bottom instrument strip — FS4-style gauges drawn with immediate mode.

const PANEL_BG := Color("0d0d14")
const PANEL_LINE := Color("3a8a5a")
const PHOSPHOR := Color("7cff9a")
const PHOSPHOR_DIM := Color("3a6a48")
const WARN := Color("ff6644")

var model: FlightModel


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PANEL_BG)
	draw_line(Vector2(0.0, 1.0), Vector2(size.x, 1.0), PANEL_LINE, 2.0)

	if model == null:
		_draw_placeholder()
		return

	var w := size.x
	var h := size.y
	var pad := 8.0
	var gauge_w := (w - pad * 5.0) / 4.0

	_draw_attitude(Rect2(pad, pad, gauge_w, h - pad * 2.0))
	_draw_airspeed(Rect2(pad * 2.0 + gauge_w, pad, gauge_w, h - pad * 2.0))
	_draw_altimeter(Rect2(pad * 3.0 + gauge_w * 2.0, pad, gauge_w, h - pad * 2.0))
	_draw_heading_throttle(Rect2(pad * 4.0 + gauge_w * 3.0, pad, gauge_w, h - pad * 2.0))

	if model.crashed:
		_draw_center_text("CRASH — R TO RESET", WARN)
	elif model.on_ground and model.airspeed_kts < 2.0:
		_draw_center_text("ON GROUND", PHOSPHOR_DIM)


func _draw_placeholder() -> void:
	_draw_center_text("INSTRUMENT PANEL", PHOSPHOR_DIM)


func _draw_center_text(text: String, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var font_size := 14
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(
		font,
		Vector2((size.x - text_size.x) * 0.5, size.y * 0.55),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		color
	)


func _draw_label(rect: Rect2, title: String) -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, rect.position + Vector2(4.0, 14.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, PHOSPHOR_DIM)


func _draw_box(rect: Rect2) -> void:
	draw_rect(rect, PANEL_LINE, false, 1.0)


func _draw_attitude(rect: Rect2) -> void:
	_draw_box(rect)
	_draw_label(rect, "ATT")

	var center := rect.get_center()
	var radius := minf(rect.size.x, rect.size.y) * 0.34
	draw_arc(center, radius, 0.0, TAU, 48, PHOSPHOR_DIM, 1.0)

	var roll_rad := deg_to_rad(model.roll)
	var pitch_offset := clampf(model.pitch, -30.0, 30.0) * 1.4

	draw_set_transform(center, roll_rad, Vector2.ONE)
	var horizon_y := pitch_offset
	draw_line(Vector2(-radius * 1.4, horizon_y), Vector2(radius * 1.4, horizon_y), PHOSPHOR, 2.0)
	draw_line(Vector2(-radius * 0.35, -radius * 0.55), Vector2(0.0, -radius * 0.15), PHOSPHOR, 2.0)
	draw_line(Vector2(radius * 0.35, -radius * 0.55), Vector2(0.0, -radius * 0.15), PHOSPHOR, 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	draw_line(center + Vector2(-18.0, 0.0), center + Vector2(18.0, 0.0), WARN, 2.0)
	draw_line(center + Vector2(0.0, -10.0), center + Vector2(0.0, 10.0), WARN, 2.0)


func _draw_airspeed(rect: Rect2) -> void:
	_draw_box(rect)
	_draw_label(rect, "IAS")

	var speed := int(model.airspeed_kts)
	var font := ThemeDB.fallback_font
	draw_string(font, rect.position + Vector2(10.0, rect.size.y * 0.55), "%03d" % speed, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, PHOSPHOR)
	draw_string(font, rect.position + Vector2(10.0, rect.size.y * 0.78), "KTS", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, PHOSPHOR_DIM)

	var bar_rect := Rect2(rect.position.x + rect.size.x - 18.0, rect.position.y + 20.0, 8.0, rect.size.y - 30.0)
	draw_rect(bar_rect, PHOSPHOR_DIM, false, 1.0)
	var fill_h := bar_rect.size.y * clampf(speed / 120.0, 0.0, 1.0)
	draw_rect(Rect2(bar_rect.position.x, bar_rect.end.y - fill_h, bar_rect.size.x, fill_h), PHOSPHOR)


func _draw_altimeter(rect: Rect2) -> void:
	_draw_box(rect)
	_draw_label(rect, "ALT")

	var alt := int(model.altitude_ft)
	var vs := int(model.vertical_speed_fpm)
	var font := ThemeDB.fallback_font
	draw_string(font, rect.position + Vector2(8.0, rect.size.y * 0.52), "%04d" % alt, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, PHOSPHOR)
	draw_string(font, rect.position + Vector2(8.0, rect.size.y * 0.74), "FT", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, PHOSPHOR_DIM)

	var vs_color := PHOSPHOR if vs >= 0 else WARN
	var vs_sign := "+" if vs >= 0 else ""
	draw_string(font, rect.position + Vector2(8.0, rect.size.y * 0.9), "VS %s%d" % [vs_sign, vs], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, vs_color)


func _draw_heading_throttle(rect: Rect2) -> void:
	_draw_box(rect)
	_draw_label(rect, "HDG / THR")

	var font := ThemeDB.fallback_font
	var hdg := int(model.heading)
	draw_string(font, rect.position + Vector2(10.0, rect.size.y * 0.5), "%03d" % hdg, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, PHOSPHOR)
	draw_string(font, rect.position + Vector2(10.0, rect.size.y * 0.66), "DEG", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, PHOSPHOR_DIM)

	var thr_pct := int(model.throttle * 100.0)
	draw_string(font, rect.position + Vector2(10.0, rect.size.y * 0.84), "THR %d%%" % thr_pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, PHOSPHOR)

	var bar := Rect2(rect.position.x + rect.size.x - 20.0, rect.position.y + 24.0, 10.0, rect.size.y - 36.0)
	draw_rect(bar, PHOSPHOR_DIM, false, 1.0)
	var fill := bar.size.y * model.throttle
	draw_rect(Rect2(bar.position.x, bar.end.y - fill, bar.size.x, fill), PHOSPHOR)
