extends Node
## Autoload "Lang": translations. Base languages live in data/lang/<code>.json,
## mods can add lang/<code>.json (new strings or whole new languages).

signal language_changed

const BASE_CODES: Array[String] = ["en", "tr"]
const LANG_NAMES := {"en": "English", "tr": "Türkçe"}

var code: String = "en"

var _strings: Dictionary = {}
var _fallback: Dictionary = {}


func _ready() -> void:
	set_language(Settings.language)


func set_language(new_code: String) -> void:
	code = new_code
	_fallback = _load_code("en")
	if new_code == "en":
		_strings = _fallback
	else:
		_strings = _load_code(new_code)
	Settings.language = new_code
	language_changed.emit()


func cycle() -> void:
	var list: Array = available()
	var i: int = list.find(code)
	set_language(str(list[(i + 1) % list.size()]))
	Settings.save_settings()


func available() -> Array:
	var codes: Array = []
	for c in BASE_CODES:
		codes.append(c)
	for m in ModLoader.mods:
		var d := DirAccess.open(str(m["path"]) + "/lang")
		if d == null:
			continue
		for f in d.get_files():
			if f.get_extension() == "json" and not codes.has(f.get_basename()):
				codes.append(f.get_basename())
	return codes


func name_of(lang_code: String) -> String:
	return str(LANG_NAMES.get(lang_code, lang_code.to_upper()))


func t(key: String) -> String:
	if _strings.has(key):
		return str(_strings[key])
	if _fallback.has(key):
		return str(_fallback[key])
	return key


func _load_code(lang_code: String) -> Dictionary:
	var result: Dictionary = {}
	result.merge(ModLoader.read_json("res://data/lang/%s.json" % lang_code), true)
	for m in ModLoader.mods:
		var extra: Dictionary = ModLoader.read_json("%s/lang/%s.json" % [str(m["path"]), lang_code])
		result.merge(extra, true)
	return result
