class_name RetroTheme
extends RefCounted

const BG := Color("1a3f7a")
const PANEL_BG := Color("f2f2f2")
const PANEL_BORDER := Color("101010")
const PANEL_TITLE := Color("d8e8ff")
const TEXT := Color("101010")
const TEXT_DIM := Color("404040")
const ACCENT := Color("b01818")
const FAIRWAY := Color("3f9a3f")
const ROUGH := Color("2f6f2f")
const GREEN := Color("4fbf4f")
const WATER := Color("2f78c8")
const SAND := Color("d9c878")
const SKY_TOP := Color("6ab4ff")
const SKY_BOTTOM := Color("b8dcff")

static func draw_panel(canvas: CanvasItem, rect: Rect2, title: String = "") -> void:
	canvas.draw_rect(rect, RetroTheme.PANEL_BORDER, false, 2.0)
	var inner := rect.grow(-2.0)
	canvas.draw_rect(inner, RetroTheme.PANEL_BG)
	if title.is_empty():
		return
	var title_h := 18.0
	var title_rect := Rect2(inner.position, Vector2(inner.size.x, title_h))
	canvas.draw_rect(title_rect, RetroTheme.BG)
	canvas.draw_line(
		title_rect.position + Vector2(0.0, title_h),
		title_rect.position + Vector2(title_rect.size.x, title_h),
		RetroTheme.PANEL_BORDER,
		1.0
	)

static func default_font() -> Font:
	var font := ThemeDB.fallback_font
	return font
