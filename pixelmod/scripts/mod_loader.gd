extends Node
## Autoload "ModLoader": finds mods, merges weapon data, serves textures.
##
## A mod is a folder containing mod.json. Optional contents:
##   weapons.json       -> adds or replaces weapons (same format as data/weapons.json)
##   lang/<code>.json   -> adds or replaces translation strings
##   textures/<name>.png -> replaces a built-in texture with the same name
## Mod folders are read from user://mods (the player's mods) and res://mods (built in).

const MODS_DIR := "user://mods"
const BUILTIN_MODS_DIR := "res://mods"

var mods: Array = []  # Array of Dictionary: id, name, version, author, description, path
var weapons: Dictionary = {}

var _texture_overrides: Dictionary = {}
var _texture_cache: Dictionary = {}


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(MODS_DIR)
	reload()


func reload() -> void:
	mods.clear()
	weapons.clear()
	_texture_overrides.clear()
	_texture_cache.clear()
	weapons = read_json("res://data/weapons.json")
	_scan(BUILTIN_MODS_DIR)
	_scan(MODS_DIR)


func _scan(root: String) -> void:
	var dir := DirAccess.open(root)
	if dir == null:
		return
	var folders: PackedStringArray = dir.get_directories()
	folders.sort()
	for folder in folders:
		var path: String = root + "/" + folder
		var info: Dictionary = read_json(path + "/mod.json")
		if info.is_empty():
			continue
		mods.append({
			"id": str(info.get("id", folder)),
			"name": str(info.get("name", folder)),
			"version": str(info.get("version", "1.0")),
			"author": str(info.get("author", "?")),
			"description": str(info.get("description", "")),
			"path": path,
		})
		var mod_weapons: Dictionary = read_json(path + "/weapons.json")
		for key in mod_weapons:
			weapons[key] = mod_weapons[key]
		_load_textures(path + "/textures")


func _load_textures(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for file in dir.get_files():
		if file.get_extension().to_lower() != "png":
			continue
		var img := Image.load_from_file(dir_path + "/" + file)
		if img == null:
			continue
		_texture_overrides[file.get_basename()] = ImageTexture.create_from_image(img)


## Returns the texture called tex_name (mods can override built-in ones).
func get_texture(tex_name: String) -> Texture2D:
	if _texture_overrides.has(tex_name):
		return _texture_overrides[tex_name]
	if _texture_cache.has(tex_name):
		return _texture_cache[tex_name]
	var path := "res://assets/%s.png" % tex_name
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path)
	_texture_cache[tex_name] = tex
	return tex


func weapon_def(id: String) -> Dictionary:
	var d: Variant = weapons.get(id, {})
	if d is Dictionary:
		return d
	return {}


## Display name: the translated name_key if the weapon has one, else its "name".
func weapon_name(id: String) -> String:
	var w: Dictionary = weapon_def(id)
	if w.has("name_key"):
		return Lang.t(str(w["name_key"]))
	return str(w.get("name", id))


func read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		return parsed
	push_warning("Could not read JSON file: " + path)
	return {}
