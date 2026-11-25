extends Node2D
## One run: level, survival waves, Catto the cat, effects, HUD.

signal quit_to_menu
signal restart_requested

const LEVEL_W := 1600
const LEVEL_H := 360
const FLOOR_Y := 320

const PLAYER := preload("res://scripts/player.gd")
const ENEMY := preload("res://scripts/enemy.gd")
const HUD := preload("res://scripts/hud.gd")
const TOUCH := preload("res://scripts/touch_controls.gd")
const PAUSE := preload("res://scripts/pause_menu.gd")

# [x, y, width] of the wooden one-way platforms
const PLATFORMS: Array = [
	[160, 275, 80], [300, 230, 80], [440, 275, 80], [560, 230, 96],
	[720, 275, 96], [860, 230, 80], [1000, 275, 96], [1140, 230, 80],
	[1280, 275, 80], [1400, 230, 96],
]

var world: Node2D
var player = null
var camera: Camera2D
var hud = null
var pause_menu = null
var cat: Sprite2D

var wave: int = 0
var kills: int = 0
var enemies_alive: int = 0
var wave_timer: float = 1.5
var shake_amt: float = 0.0
var over: bool = false
var cat_given: bool = false

var _cat_blink: float = 3.0


func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	add_child(world)
	_build_background()
	_build_level()
	_build_cat()

	player = PLAYER.new()
	player.game = self
	player.position = Vector2(120, FLOOR_Y - 8)
	player.died.connect(_on_player_died)
	world.add_child(player)

	camera = Camera2D.new()
	camera.limit_left = 0
	camera.limit_right = LEVEL_W
	camera.limit_top = 0
	camera.limit_bottom = LEVEL_H
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	player.add_child(camera)
	camera.make_current()

	hud = HUD.new()
	hud.game = self
	hud.player = player
	add_child(hud)
	if Settings.touch_controls:
		add_child(TOUCH.new())
	pause_menu = PAUSE.new()
	pause_menu.quit_to_menu.connect(_on_quit_to_menu)
	add_child(pause_menu)


func _exit_tree() -> void:
	Engine.time_scale = 1.0


# ------------------------------------------------------------ building

func _build_background() -> void:
	var bg := ParallaxBackground.new()
	var layer := ParallaxLayer.new()
	layer.motion_scale = Vector2(0.3, 0.0)
	var tex: Texture2D = ModLoader.get_texture("cloud")
	for i in 12:
		var s := Sprite2D.new()
		s.texture = tex
		s.scale = Vector2(2, 2)
		s.position = Vector2(i * 150.0 + randf_range(0.0, 60.0), randf_range(30.0, 150.0))
		s.modulate.a = 0.6
		layer.add_child(s)
	bg.add_child(layer)
	add_child(bg)


func _build_level() -> void:
	_add_solid(Rect2(0, FLOOR_Y, LEVEL_W, 80), false)
	_add_tiles(Rect2(0, FLOOR_Y, LEVEL_W, 16), "tile_grass")
	_add_tiles(Rect2(0, FLOOR_Y + 16, LEVEL_W, LEVEL_H - FLOOR_Y - 16), "tile_dirt")
	_add_solid(Rect2(-16, -300, 16, 800), false)
	_add_solid(Rect2(LEVEL_W, -300, 16, 800), false)
	for p in PLATFORMS:
		_add_solid(Rect2(p[0], p[1], p[2], 8), true)
		_add_tiles(Rect2(p[0], p[1], p[2], 8), "tile_plank")


func _add_solid(rect: Rect2, one_way: bool) -> void:
	var body := StaticBody2D.new()
	body.position = rect.position + rect.size * 0.5
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.one_way_collision = one_way
	body.add_child(shape)
	world.add_child(body)


func _add_tiles(rect: Rect2, tex_name: String) -> void:
	var node := TextureRect.new()
	node.texture = ModLoader.get_texture(tex_name)
	node.stretch_mode = TextureRect.STRETCH_TILE
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.position = rect.position
	node.size = rect.size
	world.add_child(node)


func _build_cat() -> void:
	cat = Sprite2D.new()
	cat.texture = ModLoader.get_texture("cat")
	cat.region_enabled = true
	cat.region_rect = Rect2(0, 0, 16, 16)
	cat.position = Vector2(200, 268)
	world.add_child(cat)
	var tag := Label.new()
	tag.text = "Catto"
	tag.add_theme_font_size_override("font_size", 8)
	tag.position = Vector2(-14, -26)
	cat.add_child(tag)


# ------------------------------------------------------------ main loop

func _process(delta: float) -> void:
	if Settings.screen_shake and shake_amt > 0.05:
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_amt
	else:
		camera.offset = Vector2.ZERO
	shake_amt = move_toward(shake_amt, 0.0, 25.0 * delta)

	_cat_blink -= delta
	if _cat_blink <= 0.0:
		_cat_blink = randf_range(2.0, 4.0)
		cat.region_rect = Rect2(16, 0, 16, 16)
		get_tree().create_timer(0.15).timeout.connect(_cat_open_eyes)
	if not cat_given and player.hp > 0:
		if player.global_position.distance_to(cat.global_position) < 26.0:
			_give_pewpew()

	if over:
		return
	if enemies_alive <= 0:
		wave_timer -= delta
		if wave_timer <= 0.0:
			_start_wave()


func _cat_open_eyes() -> void:
	if is_instance_valid(cat):
		cat.region_rect = Rect2(0, 0, 16, 16)


func _give_pewpew() -> void:
	cat_given = true
	if player.add_weapon("pewpew"):
		player.set_slot(player.slots.find("pewpew"))
	hud.show_message(Lang.t("cat.pickup"), 3.0)
	burst(cat.global_position + Vector2(0, -8), Color("#ff7ad9"), 14)
	var tween := create_tween()
	tween.tween_property(cat, "position:y", cat.position.y - 10.0, 0.12)
	tween.tween_property(cat, "position:y", cat.position.y, 0.12)


func _start_wave() -> void:
	wave += 1
	var count: int = mini(3 + wave * 2, 24)
	enemies_alive = count
	for i in count:
		var e = ENEMY.new()
		e.game = self
		e.player = player
		e.max_hp = 20.0 + wave * 6.0
		e.hp = e.max_hp
		e.speed = minf(32.0 + randf() * 14.0 + wave * 2.0, 85.0)
		var side: float = -1.0 if randf() < 0.5 else 1.0
		var x: float = clampf(player.global_position.x + side * randf_range(260.0, 420.0), 40.0, LEVEL_W - 40.0)
		e.position = Vector2(x, FLOOR_Y - 20.0 - float(i % 3) * 8.0)
		e.died.connect(_on_enemy_died)
		world.add_child(e)
	hud.show_message("%s %d" % [Lang.t("hud.wave"), wave], 1.8)
	if wave > 1:
		player.heal(1)


func _on_enemy_died(e) -> void:
	enemies_alive -= 1
	kills += 1
	burst(e.global_position, Color("#5fcf6b"), 14)
	shake(2.0)
	if enemies_alive <= 0:
		wave_timer = 2.5


func _on_player_died() -> void:
	over = true
	shake(8.0)
	burst(player.global_position, Color("#d9463e"), 18)
	hud.show_game_over()


func _on_quit_to_menu() -> void:
	quit_to_menu.emit()


# -------------------------------------------------------------- effects

func burst(pos: Vector2, color: Color, amount: int = 8) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = 0.45
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.gravity = Vector2(0, 420)
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 110.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	p.color = color
	world.add_child(p)
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)


func shake(amount: float) -> void:
	shake_amt = maxf(shake_amt, amount)


func hit_stop(duration: float) -> void:
	Engine.time_scale = 0.08
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0


func damage_number(pos: Vector2, amount: float) -> void:
	var l := Label.new()
	l.text = str(int(round(amount)))
	l.position = pos + Vector2(-6, 0)
	l.z_index = 20
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", Color("#ffd84a"))
	l.add_theme_color_override("font_outline_color", Color("#1a1424"))
	l.add_theme_constant_override("outline_size", 3)
	world.add_child(l)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(l, "position:y", l.position.y - 18.0, 0.5)
	t.tween_property(l, "modulate:a", 0.0, 0.5)
	t.tween_callback(l.queue_free).set_delay(0.5)


func slash(pos: Vector2, dir: Vector2, reach: float) -> void:
	var line := Line2D.new()
	line.width = 3.0
	line.default_color = Color("#f4f1e8")
	var base: float = dir.angle()
	var pts := PackedVector2Array()
	for i in 9:
		pts.append(Vector2.from_angle(base - 0.9 + float(i) * 0.225) * reach)
	line.points = pts
	line.position = pos
	line.z_index = 5
	world.add_child(line)
	var t := create_tween()
	t.tween_property(line, "modulate:a", 0.0, 0.15)
	t.tween_callback(line.queue_free)
