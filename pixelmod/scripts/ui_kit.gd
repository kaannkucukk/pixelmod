extends RefCounted
## Small helpers for building UI in code.


static func button(text: String, cb: Callable, min_width: float = 220.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_width, 30)
	b.pressed.connect(cb)
	return b


static func label(text: String, size: int = 12) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color("#f4f1e8"))
	l.add_theme_color_override("font_outline_color", Color("#1a1424"))
	l.add_theme_constant_override("outline_size", 3)
	return l


static func title(text: String) -> Label:
	var l := label(text, 26)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", Color("#ffd84a"))
	return l
