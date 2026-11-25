extends CanvasLayer
## On-screen buttons for phones. TouchScreenButton supports several fingers at once.

const BUTTONS := [
	# [label, action, x, y, size]
	["<", "move_left", 14, 292, 52],
	[">", "move_right", 76, 292, 52],
	["JUMP", "jump", 574, 292, 52],
	["HIT", "attack", 512, 292, 52],
	["DASH", "dash", 574, 232, 52],
	["SWAP", "next_weapon", 512, 232, 52],
	["R", "reload", 450, 292, 44],
]


func _ready() -> void:
	layer = 11
	for b in BUTTONS:
		_add_button(str(b[0]), str(b[1]), float(b[2]), float(b[3]), int(b[4]))


func _add_button(text: String, action: String, x: float, y: float, size: int) -> void:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0.22))
	var tex := ImageTexture.create_from_image(img)
	var btn := TouchScreenButton.new()
	btn.texture_normal = tex
	btn.action = action
	btn.position = Vector2(x, y)
	add_child(btn)
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	l.size = Vector2(size, size)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = Vector2(x, y)
	add_child(l)
