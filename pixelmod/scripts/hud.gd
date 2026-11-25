extends CanvasLayer
## Health bar, wave counter, hotbar, ammo, FPS counter, messages, game over.

const UI := preload("res://scripts/ui_kit.gd")
const SLOTS := 6

var game = null
var player = null

var _hp_fill: ColorRect
var _wave_label: Label
var _fps_label: Label
var _msg_label: Label
var _ammo_label: Label
var _slot_bg: Array[ColorRect] = []
var _slot_icon: Array[TextureRect] = []
var _msg_time: float = 0.0
var _over_shown: bool = false


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func _build() -> void:
	var hp_bg := ColorRect.new()
	hp_bg.color = Color("#1a1424")
	hp_bg.position = Vector2(8, 8)
	hp_bg.size = Vector2(84, 12)
	add_child(hp_bg)
	_hp_fill = ColorRect.new()
	_hp_fill.color = Color("#d9463e")
	_hp_fill.position = Vector2(10, 10)
	_hp_fill.size = Vector2(80, 8)
	add_child(_hp_fill)

	_wave_label = UI.label("", 12)
	_wave_label.position = Vector2(8, 22)
	add_child(_wave_label)

	_fps_label = UI.label("", 10)
	_fps_label.position = Vector2(290, 6)
	add_child(_fps_label)

	_msg_label = UI.label("", 16)
	_msg_label.position = Vector2(0, 70)
	_msg_label.size = Vector2(640, 24)
	_msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_msg_label)

	_ammo_label = UI.label("", 12)
	_ammo_label.position = Vector2(0, 306)
	_ammo_label.size = Vector2(640, 16)
	_ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_ammo_label)

	var start_x: float = (640.0 - (SLOTS * 26.0 + (SLOTS - 1) * 3.0)) * 0.5
	for i in SLOTS:
		var bg := ColorRect.new()
		bg.color = Color("#1a1424")
		bg.position = Vector2(start_x + i * 29.0, 326)
		bg.size = Vector2(26, 26)
		add_child(bg)
		_slot_bg.append(bg)
		var icon := TextureRect.new()
		icon.position = Vector2(5, 5)
		icon.size = Vector2(16, 16)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.add_child(icon)
		_slot_icon.append(icon)
		var num: Label = UI.label(str(i + 1), 8)
		num.position = Vector2(2, -1)
		bg.add_child(num)

	if Settings.touch_controls:
		var pause_btn: Button = UI.button("II", _on_pause_pressed, 34.0)
		pause_btn.position = Vector2(598, 6)
		add_child(pause_btn)


func _on_pause_pressed() -> void:
	if game != null:
		game.pause_menu.toggle()


func show_message(text: String, seconds: float) -> void:
	_msg_label.text = text
	_msg_time = seconds


func show_game_over() -> void:
	if _over_shown:
		return
	_over_shown = true
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	center.add_child(box)
	box.add_child(UI.title(Lang.t("game.over")))
	var stats: Label = UI.label("%s %d   %s %d" % [Lang.t("hud.wave"), game.wave, Lang.t("hud.kills"), game.kills], 14)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(stats)
	box.add_child(UI.button(Lang.t("game.restart"), _on_restart))
	box.add_child(UI.button(Lang.t("pause.menu"), _on_menu))


func _on_restart() -> void:
	game.restart_requested.emit()


func _on_menu() -> void:
	game.quit_to_menu.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fps"):
		Settings.show_fps = not Settings.show_fps
		Settings.save_settings()


func _process(delta: float) -> void:
	_fps_label.visible = Settings.show_fps
	if Settings.show_fps:
		_fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	if _msg_time > 0.0:
		_msg_time -= delta
		if _msg_time <= 0.0:
			_msg_label.text = ""
	if not is_instance_valid(player) or not is_instance_valid(game):
		return
	_hp_fill.size.x = 80.0 * clampf(float(player.hp) / float(player.max_hp), 0.0, 1.0)
	_wave_label.text = "%s %d   %s %d" % [Lang.t("hud.wave"), game.wave, Lang.t("hud.kills"), game.kills]

	for i in SLOTS:
		var has_weapon: bool = i < player.slots.size()
		_slot_icon[i].visible = has_weapon
		_slot_bg[i].color = Color("#ffd84a") if (has_weapon and i == player.current) else Color("#1a1424")
		if has_weapon:
			var w: Dictionary = ModLoader.weapon_def(player.slots[i])
			var tex: Texture2D = ModLoader.get_texture(str(w.get("icon", "wp_pistol")))
			if _slot_icon[i].texture != tex:
				_slot_icon[i].texture = tex

	if player.slots.is_empty():
		_ammo_label.text = ""
		return
	var id: String = player.slots[player.current]
	var cur: Dictionary = ModLoader.weapon_def(id)
	var name_text: String = ModLoader.weapon_name(id)
	if str(cur.get("type", "gun")) == "gun":
		if player.reload_left > 0.0:
			_ammo_label.text = "%s  %s" % [name_text, Lang.t("hud.reloading")]
		else:
			_ammo_label.text = "%s  %d/%d" % [name_text, int(player.ammo.get(id, 0)), int(cur.get("ammo", 0))]
	else:
		_ammo_label.text = name_text
