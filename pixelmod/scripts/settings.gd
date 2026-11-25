extends Node
## Autoload "Settings": saved options + keyboard input map.

signal changed

const SAVE_PATH := "user://settings.cfg"
const FPS_OPTIONS: Array[int] = [30, 60, 120, 0]  # 0 = unlimited

var show_fps: bool = false
var fps_limit: int = 60
var vsync: bool = true
var screen_shake: bool = true
var touch_controls: bool = false
var language: String = "en"
var master_volume: float = 1.0


func _ready() -> void:
	_register_inputs()
	touch_controls = OS.has_feature("mobile")
	if OS.get_locale_language() == "tr":
		language = "tr"
	load_settings()
	apply()


func apply() -> void:
	Engine.max_fps = fps_limit
	if vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	AudioServer.set_bus_volume_db(0, linear_to_db(clampf(master_volume, 0.0001, 1.0)))
	changed.emit()


func cycle_fps() -> void:
	var i: int = FPS_OPTIONS.find(fps_limit)
	fps_limit = FPS_OPTIONS[(i + 1) % FPS_OPTIONS.size()]
	apply()
	save_settings()


func fps_text() -> String:
	if fps_limit == 0:
		return "MAX"
	return str(fps_limit)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "show_fps", show_fps)
	cfg.set_value("game", "fps_limit", fps_limit)
	cfg.set_value("game", "vsync", vsync)
	cfg.set_value("game", "screen_shake", screen_shake)
	cfg.set_value("game", "touch_controls", touch_controls)
	cfg.set_value("game", "language", language)
	cfg.set_value("game", "master_volume", master_volume)
	cfg.save(SAVE_PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	show_fps = bool(cfg.get_value("game", "show_fps", show_fps))
	fps_limit = int(cfg.get_value("game", "fps_limit", fps_limit))
	vsync = bool(cfg.get_value("game", "vsync", vsync))
	screen_shake = bool(cfg.get_value("game", "screen_shake", screen_shake))
	touch_controls = bool(cfg.get_value("game", "touch_controls", touch_controls))
	language = str(cfg.get_value("game", "language", language))
	master_volume = float(cfg.get_value("game", "master_volume", master_volume))


# ---------------------------------------------------------------- inputs

func _register_inputs() -> void:
	_add_keys("move_left", [KEY_A, KEY_LEFT])
	_add_keys("move_right", [KEY_D, KEY_RIGHT])
	_add_keys("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_add_keys("dash", [KEY_SHIFT, KEY_K])
	_add_keys("attack", [KEY_J])
	_add_keys("next_weapon", [KEY_E])
	_add_keys("prev_weapon", [KEY_Q])
	_add_keys("reload", [KEY_R])
	_add_keys("slot_1", [KEY_1])
	_add_keys("slot_2", [KEY_2])
	_add_keys("slot_3", [KEY_3])
	_add_keys("slot_4", [KEY_4])
	_add_keys("slot_5", [KEY_5])
	_add_keys("slot_6", [KEY_6])
	_add_keys("pause", [KEY_ESCAPE])
	_add_keys("toggle_fps", [KEY_F3])
	# On phones every touch is also an emulated mouse click, so the mouse
	# button is only bound to "attack" on desktop.
	if not OS.has_feature("mobile"):
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("attack", ev)


func _add_keys(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k as Key
		InputMap.action_add_event(action, ev)
