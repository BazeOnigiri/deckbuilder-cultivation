extends Control
## Racine du jeu : machine a etats MENU / RUN. Une seule scene affichee a la fois.

const MENU_SCENE := preload("res://ui/menu/menu_screen.tscn")
const RUN_SCENE := preload("res://ui/round/round_screen.tscn")

var _screen: Node


func _ready() -> void:
	_show_menu()


func _show_menu() -> void:
	var menu := MENU_SCENE.instantiate()
	menu.start_requested.connect(_show_run)
	_swap(menu)


func _show_run() -> void:
	var run := RUN_SCENE.instantiate()
	run.menu_requested.connect(_show_menu)
	_swap(run)


func _swap(screen: Node) -> void:
	if _screen != null:
		_screen.queue_free()
	_screen = screen
	add_child(screen)