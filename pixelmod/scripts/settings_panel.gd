extends VBoxContainer
## Settings list used by the main menu and the pause menu.

signal back

const UI := preload("res://scripts/ui_kit.gd")


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	_build()


func _onoff(v: bool) -> String:
	return Lang.t("on") if v else Lang.t("off")


func _build() -> void:
	for c in get_children():
		c.queue_free()
	add_child(UI.title(Lang.t("set.title")))
	add_child(UI.button("%s: %s" % [Lang.t("set.fps"), Settings.fps_text()], _on_fps))
	add_child(UI.button("%s: %s" % [Lang.t("set.show_fps"), _onoff(Settings.show_fps)], _on_show_fps))
	add_child(UI.button("%s: %s" % [Lang.t("set.vsync"), _onoff(Settings.vsync)], _on_vsync))
	add_child(UI.button("%s: %s" % [Lang.t("set.shake"), _onoff(Settings.screen_shake)], _on_shake))
	add_child(UI.button("%s: %s" % [Lang.t("set.touch"), _onoff(Settings.touch_controls)], _on_touch))
	add_child(UI.button("%s: %s" % [Lang.t("set.language"), Lang.name_of(Lang.code)], _on_language))
	add_child(UI.button(Lang.t("set.back"), _on_back))


func _on_fps() -> void:
	Settings.cycle_fps()
	_build()


func _on_show_fps() -> void:
	Settings.show_fps = not Settings.show_fps
	Settings.save_settings()
	_build()


func _on_vsync() -> void:
	Settings.vsync = not Settings.vsync
	Settings.apply()
	Settings.save_settings()
	_build()


func _on_shake() -> void:
	Settings.screen_shake = not Settings.screen_shake
	Settings.save_settings()
	_build()


func _on_touch() -> void:
	Settings.touch_controls = not Settings.touch_controls
	Settings.save_settings()
	_build()


func _on_language() -> void:
	Lang.cycle()
	_build()


func _on_back() -> void:
	back.emit()
