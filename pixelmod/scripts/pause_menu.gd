extends CanvasLayer
## Pause overlay (Esc / on-screen II button).

signal quit_to_menu

const UI := preload("res://scripts/ui_kit.gd")
const SETTINGS_PANEL := preload("res://scripts/settings_panel.gd")

var _center: CenterContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_center = CenterContainer.new()
	_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(_center)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if visible:
		_resume()
	else:
		visible = true
		get_tree().paused = true
		_show_main()


func _resume() -> void:
	visible = false
	get_tree().paused = false


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
	box.add_child(UI.title(Lang.t("pause.title")))
	box.add_child(UI.button(Lang.t("pause.resume"), _resume))
	box.add_child(UI.button(Lang.t("menu.settings"), _show_settings))
	box.add_child(UI.button(Lang.t("pause.menu"), _on_menu))


func _show_settings() -> void:
	var box: VBoxContainer = _clear()
	var panel := SETTINGS_PANEL.new()
	panel.back.connect(_show_main)
	box.add_child(panel)


func _on_menu() -> void:
	get_tree().paused = false
	quit_to_menu.emit()
