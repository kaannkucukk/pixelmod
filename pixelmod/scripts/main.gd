extends Node
## Root: switches between the main menu and a game run.

const MENU := preload("res://scripts/menu.gd")
const GAME := preload("res://scripts/game.gd")

var _current: Node = null


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#2b2d4a"))
	show_menu()


func _swap(node: Node) -> void:
	if _current != null:
		_current.queue_free()
		_current = null
	get_tree().paused = false
	Engine.time_scale = 1.0
	_current = node
	add_child(node)


func show_menu() -> void:
	var m = MENU.new()
	m.play_pressed.connect(start_game)
	m.quit_pressed.connect(_quit)
	_swap(m)


func start_game() -> void:
	var g = GAME.new()
	g.quit_to_menu.connect(show_menu)
	g.restart_requested.connect(start_game)
	_swap(g)


func _quit() -> void:
	get_tree().quit()
