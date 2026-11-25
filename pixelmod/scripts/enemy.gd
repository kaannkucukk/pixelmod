extends CharacterBody2D
## A slime: walks at the player, hurts on contact, flies back when hit.

signal died(enemy: Node)

const GRAVITY := 900.0

var game = null
var player = null
var max_hp: float = 30.0
var hp: float = 30.0
var speed: float = 40.0
var contact_damage: int = 1
var hurt_time: float = 0.0
var contact_cooldown: float = 0.0
var anim_t: float = 0.0
var facing: int = 1

var _sprite: Sprite2D


func _ready() -> void:
	anim_t = randf() * 10.0
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(12, 12)
	shape.shape = box
	add_child(shape)
	_sprite = Sprite2D.new()
	_sprite.texture = ModLoader.get_texture("slime")
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(0, 0, 16, 16)
	add_child(_sprite)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	var target_alive: bool = is_instance_valid(player) and player.hp > 0
	if hurt_time > 0.0:
		hurt_time -= delta
		velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
	elif target_alive:
		facing = 1 if player.global_position.x > global_position.x else -1
		velocity.x = facing * speed
		if is_on_wall() and is_on_floor():
			velocity.y = -240.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
	move_and_slide()

	contact_cooldown -= delta
	if contact_cooldown <= 0.0 and target_alive:
		var d: Vector2 = player.global_position - global_position
		if absf(d.x) < 11.0 and absf(d.y) < 13.0:
			player.take_damage(contact_damage, global_position)
			contact_cooldown = 0.7

	anim_t += delta
	var frame: int = int(anim_t * 5.0) % 2
	if hurt_time > 0.0:
		frame = 2
	_sprite.region_rect = Rect2(frame * 16, 0, 16, 16)
	_sprite.flip_h = facing < 0


func take_damage(amount: float, knock: Vector2) -> void:
	hp -= amount
	hurt_time = 0.22
	velocity = knock
	if game != null:
		game.burst(global_position, Color("#5fcf6b"), 6)
		game.damage_number(global_position + Vector2(0, -10), amount)
	if hp <= 0.0:
		died.emit(self)
		queue_free()
