extends Control
## Racine du jeu : machine a etats MENU / RUN / STATS. Possede le profil du joueur, partage entre les ecrans.

const MENU_SCENE := preload("res://ui/menu/menu_screen.tscn")
const RUN_SCENE := preload("res://ui/round/round_screen.tscn")
const STATS_SCENE := preload("res://ui/stats/stats_screen.tscn")

## Les tests le remplacent pour ne pas ecrire dans le vrai profil.
@export var profile_path: String = ProfileStats.DEFAULT_PATH

var _screen: Node
var _profile: ProfileStats
var _profile_storage: SaveStorage
var _tracker: ProfileTracker


func _ready() -> void:
	_profile_storage = SaveStorage.new(profile_path)
	_profile = ProfileStats.load_from(_profile_storage)
	_tracker = ProfileTracker.new(_profile)
	_tracker.changed.connect(_save_profile)
	_show_menu()


func _show_menu() -> void:
	var menu := MENU_SCENE.instantiate()
	menu.start_requested.connect(_show_run)
	menu.stats_requested.connect(_show_stats)
	_swap(menu)


func _show_stats() -> void:
	var stats := STATS_SCENE.instantiate()
	stats.profile = _profile
	stats.back_requested.connect(_show_menu)
	_swap(stats)


func _show_run() -> void:
	var run_screen := RUN_SCENE.instantiate()
	# Branche avant add_child : run_created est emis pendant le _ready de l'ecran.
	run_screen.run_created.connect(_tracker.track)
	run_screen.menu_requested.connect(_show_menu)
	_swap(run_screen)


func _swap(screen: Node) -> void:
	if _screen != null:
		_screen.queue_free()
	_screen = screen
	add_child(screen)


func _save_profile() -> void:
	if not _profile.save_to(_profile_storage):
		push_warning("Profil non sauvegarde : %s" % _profile_storage.last_error)