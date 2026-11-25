extends Control
## Main menu: play, settings, installed mods.

signal play_pressed
signal quit_pressed

const UI := preload("res://scripts/ui_kit.gd")
const SETTINGS_PANEL := preload("res://scripts/settings_panel.gd")

var _center: CenterContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_center = CenterContainer.new()
	_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_center)
	_show_main()


func _clear() -> VBoxContainer:
	for c in _center.get_children():
		c.queue_free()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.custom_minimum_size = Vector2(260, 0)
	_center.add_child(box)
	return box


func _show_main() -> void:
	var box: VBoxContainer = _clear()
	box.add_child(UI.title(Lang.t("menu.title")))
	var cat_tex: Texture2D = ModLoader.get_texture("cat")
	if cat_tex != null:
		var atlas := AtlasTexture.new()
		atlas.atlas = cat_tex
		atlas.region = Rect2(0, 0, 16, 16)
		var icon := TextureRect.new()
		icon.texture = atlas
		icon.custom_minimum_size = Vector2(64, 64)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		box.add_child(icon)
	box.add_child(UI.button(Lang.t("menu.play"), _on_play))
	box.add_child(UI.button(Lang.t("menu.settings"), _show_settings))
	box.add_child(UI.button(Lang.t("menu.mods"), _show_mods))
	if not OS.has_feature("mobile"):
		box.add_child(UI.button(Lang.t("menu.quit"), _on_quit))
	var credit: Label = UI.label(Lang.t("menu.credit"), 10)
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(credit)


func _show_settings() -> void:
	var box: VBoxContainer = _clear()
	var panel := SETTINGS_PANEL.new()
	panel.back.connect(_show_main)
	box.add_child(panel)


func _show_mods() -> void:
	var box: VBoxContainer = _clear()
	box.add_child(UI.title(Lang.t("mods.title")))
	if ModLoader.mods.is_empty():
		box.add_child(UI.label(Lang.t("mods.none"), 12))
	for m in ModLoader.mods:
		var line: Label = UI.label("%s  v%s  (%s)" % [m["name"], m["version"], m["author"]], 12)
		box.add_child(line)
		if str(m["description"]) != "":
			var desc: Label = UI.label(str(m["description"]), 10)
			desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			desc.custom_minimum_size = Vector2(260, 0)
			box.add_child(desc)
	var hint: Label = UI.label(Lang.t("mods.hint"), 10)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(260, 0)
	box.add_child(hint)
	box.add_child(UI.button(Lang.t("set.back"), _show_main))


func _on_play() -> void:
	play_pressed.emit()


func _on_quit() -> void:
	quit_pressed.emit()
