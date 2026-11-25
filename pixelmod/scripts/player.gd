extends CharacterBody2D
## The player: run, double jump, dash, melee and guns from the weapon data.

signal died

const BULLET := preload("res://scripts/bullet.gd")

const MAX_SPEED := 105.0
const ACCEL := 1100.0
const FRICTION := 1300.0
const AIR_CONTROL := 0.8
const JUMP_VELOCITY := -300.0
const GRAVITY := 900.0
const FALL_MULT := 1.4
const MAX_FALL := 420.0
const COYOTE := 0.10
const JUMP_BUFFER := 0.12
const DASH_SPEED := 260.0
const DASH_TIME := 0.14
const DASH_COOLDOWN := 0.6
const MAX_SLOTS := 6

var game = null
var max_hp: int = 6
var hp: int = 6
var facing: int = 1
var slots: Array[String] = []
var current: int = 0
var ammo: Dictionary = {}
var cooldown: float = 0.0
var reload_left: float = 0.0
var invuln: float = 0.0
var hurt_timer: float = 0.0
var dash_timer: float = 0.0
var dash_cd: float = 0.0
var dash_dir: float = 1.0
var coyote_timer: float = 0.0
var jump_buffer: float = 0.0
var extra_jumps: int = 1
var anim_time: float = 0.0
var swing_t: float = 0.0
var kick: float = 0.0

var _was_on_floor: bool = true
var _sprite: Sprite2D
var _weapon: Sprite2D


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(10, 14)
	shape.shape = box
	add_child(shape)

	_sprite = Sprite2D.new()
	_sprite.texture = ModLoader.get_texture("player")
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(0, 0, 16, 16)
	add_child(_sprite)

	_weapon = Sprite2D.new()
	_weapon.offset = Vector2(6, 0)
	_weapon.position = Vector2(0, 1)
	_weapon.z_index = 1
	add_child(_weapon)

	for id in ModLoader.weapons:
		var w: Dictionary = ModLoader.weapon_def(str(id))
		if bool(w.get("start", false)):
			add_weapon(str(id))
	_refresh_weapon_sprite()


# ------------------------------------------------------------ weapons

func add_weapon(id: String) -> bool:
	if slots.has(id) or slots.size() >= MAX_SLOTS:
		return false
	if ModLoader.weapon_def(id).is_empty():
		return false
	slots.append(id)
	ammo[id] = int(ModLoader.weapon_def(id).get("ammo", 0))
	return true


func set_slot(i: int) -> void:
	if i < 0 or i >= slots.size() or i == current:
		return
	current = i
	reload_left = 0.0
	cooldown = 0.12
	_refresh_weapon_sprite()


func _refresh_weapon_sprite() -> void:
	if slots.is_empty():
		_weapon.texture = null
		return
	var w: Dictionary = ModLoader.weapon_def(slots[current])
	var tex: Texture2D = ModLoader.get_texture(str(w.get("icon", "wp_pistol")))
	if tex == null:
		tex = ModLoader.get_texture("wp_pistol")
	_weapon.texture = tex


func _unhandled_input(event: InputEvent) -> void:
	if slots.is_empty():
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			set_slot((current - 1 + slots.size()) % slots.size())
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			set_slot((current + 1) % slots.size())


func _handle_slot_keys() -> void:
	if slots.is_empty():
		return
	for i in MAX_SLOTS:
		if Input.is_action_just_pressed("slot_%d" % (i + 1)):
			set_slot(i)
	if Input.is_action_just_pressed("next_weapon"):
		set_slot((current + 1) % slots.size())
	if Input.is_action_just_pressed("prev_weapon"):
		set_slot((current - 1 + slots.size()) % slots.size())


func _try_attack(aim: Vector2) -> void:
	if cooldown > 0.0 or reload_left > 0.0 or slots.is_empty():
		return
	var id: String = slots[current]
	var w: Dictionary = ModLoader.weapon_def(id)
	if str(w.get("type", "gun")) == "melee":
		cooldown = float(w.get("cooldown", 0.35))
		_melee(w, aim)
		return
	if int(ammo.get(id, 0)) <= 0:
		_start_reload()
		return
	cooldown = float(w.get("cooldown", 0.3))
	_shoot(w, aim)
	ammo[id] = int(ammo.get(id, 0)) - 1
	if int(ammo[id]) <= 0:
		_start_reload()


func _shoot(w: Dictionary, aim: Vector2) -> void:
	var pellets: int = int(w.get("pellets", 1))
	var spread: float = deg_to_rad(float(w.get("spread", 0.0)))
	var speed: float = float(w.get("bullet_speed", 400.0))
	var color: Color = Color.from_string(str(w.get("bullet_color", "#ffffff")), Color.WHITE)
	var muzzle: Vector2 = global_position + Vector2(0, 1) + aim * 14.0
	for _i in pellets:
		var b = BULLET.new()
		var ang: float = aim.angle() + randf_range(-spread, spread) * 0.5
		b.velocity = Vector2.from_angle(ang) * speed
		b.damage = float(w.get("damage", 10.0))
		b.knockback = float(w.get("knockback", 100.0))
		b.color = color
		b.game = game
		b.position = muzzle
		get_parent().add_child(b)
	velocity.x -= aim.x * float(w.get("recoil", 0.0))
	kick = 1.0
	if game != null:
		game.burst(muzzle, color, 4)
		game.shake(float(w.get("shake", 1.5)))


func _melee(w: Dictionary, aim: Vector2) -> void:
	var reach: float = float(w.get("range", 28.0))
	var dmg: float = float(w.get("damage", 20.0))
	var kb: float = float(w.get("knockback", 150.0))
	swing_t = 0.18
	if game != null:
		game.slash(global_position + Vector2(0, 1), aim, reach)
	var hit := false
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		var to: Vector2 = e.global_position - global_position
		if to.length() <= reach + 8.0 and to.dot(aim) > 0.0:
			e.take_damage(dmg, aim * kb + Vector2(0, -90))
			hit = true
	if hit and game != null:
		game.shake(float(w.get("shake", 2.5)))
		game.hit_stop(0.05)


func _start_reload() -> void:
	if slots.is_empty() or reload_left > 0.0:
		return
	var id: String = slots[current]
	var w: Dictionary = ModLoader.weapon_def(id)
	if str(w.get("type", "gun")) != "gun":
		return
	if int(ammo.get(id, 0)) >= int(w.get("ammo", 0)):
		return
	reload_left = float(w.get("reload", 1.0))


func _tick_reload(delta: float) -> void:
	if reload_left <= 0.0:
		return
	reload_left -= delta
	if reload_left <= 0.0 and not slots.is_empty():
		var id: String = slots[current]
		ammo[id] = int(ModLoader.weapon_def(id).get("ammo", 0))


# ----------------------------------------------------------- movement

func _physics_process(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)
	invuln = maxf(invuln - delta, 0.0)
	hurt_timer = maxf(hurt_timer - delta, 0.0)
	dash_cd = maxf(dash_cd - delta, 0.0)
	kick = move_toward(kick, 0.0, 8.0 * delta)
	swing_t = maxf(swing_t - delta, 0.0)
	_tick_reload(delta)

	var alive: bool = hp > 0
	var can_act: bool = alive and hurt_timer <= 0.0
	var input_x: float = 0.0
	if can_act:
		input_x = Input.get_axis("move_left", "move_right")
	var aim: Vector2 = _get_aim(input_x)

	if is_on_floor():
		coyote_timer = COYOTE
		extra_jumps = 1
	else:
		coyote_timer -= delta
	if can_act and Input.is_action_just_pressed("jump"):
		jump_buffer = JUMP_BUFFER
	else:
		jump_buffer -= delta

	if dash_timer > 0.0:
		dash_timer -= delta
		velocity = Vector2(dash_dir * DASH_SPEED, 0.0)
	else:
		if not is_on_floor():
			var g: float = GRAVITY
			if velocity.y > 0.0:
				g *= FALL_MULT
			velocity.y = minf(velocity.y + g * delta, MAX_FALL)
		if jump_buffer > 0.0 and can_act:
			if coyote_timer > 0.0:
				_jump(JUMP_VELOCITY)
				coyote_timer = 0.0
			elif extra_jumps > 0:
				extra_jumps -= 1
				_jump(JUMP_VELOCITY * 0.9)
		if can_act and Input.is_action_just_released("jump") and velocity.y < -80.0:
			velocity.y *= 0.5

		if not can_act:
			velocity.x = move_toward(velocity.x, 0.0, FRICTION * 0.4 * delta)
		elif input_x != 0.0:
			var accel: float = ACCEL
			if not is_on_floor():
				accel *= AIR_CONTROL
			velocity.x = move_toward(velocity.x, input_x * MAX_SPEED, accel * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

		if can_act and dash_cd <= 0.0 and Input.is_action_just_pressed("dash"):
			_start_dash(input_x)

	if can_act and dash_timer <= 0.0:
		if Input.is_action_pressed("attack"):
			_try_attack(aim)
		if Input.is_action_just_pressed("reload"):
			_start_reload()
		_handle_slot_keys()

	move_and_slide()

	var on_floor: bool = is_on_floor()
	if on_floor and not _was_on_floor:
		_sprite.scale = Vector2(1.3, 0.7)
		if game != null:
			game.burst(global_position + Vector2(0, 7), Color("#c9cfdd"), 5)
	_was_on_floor = on_floor
	if global_position.y > 700.0:
		global_position = Vector2(120, 300)
		velocity = Vector2.ZERO

	_animate(delta, aim)


func _jump(v: float) -> void:
	velocity.y = v
	jump_buffer = 0.0
	_sprite.scale = Vector2(0.75, 1.25)
	if game != null:
		game.burst(global_position + Vector2(0, 7), Color("#c9cfdd"), 5)


func _start_dash(input_x: float) -> void:
	if input_x != 0.0:
		dash_dir = signf(input_x)
	else:
		dash_dir = float(facing)
	dash_timer = DASH_TIME
	dash_cd = DASH_COOLDOWN
	invuln = maxf(invuln, DASH_TIME + 0.05)
	if game != null:
		game.burst(global_position, Color("#f4f1e8"), 6)


## Aim direction. Mouse on desktop; straight ahead with touch controls.
func _get_aim(input_x: float) -> Vector2:
	if Settings.touch_controls:
		if input_x != 0.0:
			facing = 1 if input_x > 0.0 else -1
		return Vector2(facing, 0)
	var d: Vector2 = get_global_mouse_position() - global_position
	if d.length() < 6.0:
		return Vector2(facing, 0)
	var aim: Vector2 = d.normalized()
	if absf(aim.x) > 0.15:
		facing = 1 if aim.x > 0.0 else -1
	return aim


# ------------------------------------------------------------- health

func take_damage(amount: int, from_pos: Vector2) -> void:
	if invuln > 0.0 or hp <= 0:
		return
	hp = maxi(hp - amount, 0)
	invuln = 1.0
	hurt_timer = 0.25
	dash_timer = 0.0
	var dir: float = signf(global_position.x - from_pos.x)
	if dir == 0.0:
		dir = -float(facing)
	velocity = Vector2(dir * 170.0, -170.0)
	if game != null:
		game.shake(5.0)
		game.hit_stop(0.07)
		game.burst(global_position, Color("#d9463e"), 10)
	if hp <= 0:
		died.emit()


func heal(n: int) -> void:
	hp = mini(hp + n, max_hp)


# ---------------------------------------------------------- animation

func _animate(delta: float, aim: Vector2) -> void:
	var frame: int = 0
	if hp <= 0 or hurt_timer > 0.0:
		frame = 8
	elif not is_on_floor():
		frame = 6 if velocity.y < 0.0 else 7
	elif absf(velocity.x) > 12.0:
		anim_time += delta * (absf(velocity.x) / MAX_SPEED)
		frame = 2 + int(anim_time * 12.0) % 4
	else:
		anim_time += delta
		frame = int(anim_time * 3.0) % 2
	_sprite.region_rect = Rect2(frame * 16, 0, 16, 16)
	_sprite.flip_h = facing < 0
	_sprite.scale = _sprite.scale.lerp(Vector2.ONE, minf(14.0 * delta, 1.0))
	if invuln > 0.0 and int(invuln * 24.0) % 2 == 0:
		_sprite.modulate.a = 0.35
	else:
		_sprite.modulate.a = 1.0

	_weapon.visible = hp > 0
	var swing_off: float = 0.0
	if swing_t > 0.0:
		swing_off = (0.5 - swing_t / 0.18) * 2.2
		if aim.x < 0.0:
			swing_off = -swing_off
	_weapon.rotation = aim.angle() + swing_off
	_weapon.flip_v = aim.x < 0.0
	_weapon.position = Vector2(0, 1) - aim * kick * 3.0
