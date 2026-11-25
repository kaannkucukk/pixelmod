extends Area2D
## A projectile. Damages enemies, vanishes on walls.

var velocity: Vector2 = Vector2.ZERO
var damage: float = 10.0
var knockback: float = 100.0
var color: Color = Color.WHITE
var game = null
var life: float = 1.2

var _done: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 4  # world + enemies
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(4, 4)
	shape.shape = box
	add_child(shape)
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-2, -2, 4, 4), color)
	draw_rect(Rect2(-1, -1, 2, 2), Color.WHITE)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	life -= delta
	if life <= 0.0:
		queue_free()


func _on_body_entered(body) -> void:
	if _done:
		return
	if body.is_in_group("enemies"):
		_done = true
		var dir: Vector2 = velocity.normalized()
		body.take_damage(damage, dir * knockback + Vector2(0, -50))
		if game != null:
			game.burst(global_position, color, 4)
		queue_free()
	elif body is StaticBody2D:
		_done = true
		if game != null:
			game.burst(global_position, color, 3)
		queue_free()
