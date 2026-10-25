extends Control
## Racine du jeu : machine a etats MENU / RUN / STATS.
## Possede le contenu, le profil et la sauvegarde de run, partages entre les ecrans.

const MENU_SCENE := preload("res://ui/menu/menu_screen.tscn")
const RUN_SCENE := preload("res://ui/round/round_screen.tscn")
const STATS_SCENE := preload("res://ui/stats/stats_screen.tscn")

## Les tests les remplacent pour ne pas toucher aux vraies sauvegardes.
@export var profile_path: String = ProfileStats.DEFAULT_PATH
@export var run_path: String = RunSnapshot.DEFAULT_PATH

var _screen: Node
var _content: GameContent
var _profile: ProfileStats
var _profile_storage: SaveStorage
var _tracker: ProfileTracker
var _run_storage: SaveStorage


func _ready() -> void:
	_content = GameContent.load_default()
	_profile_storage = SaveStorage.new(profile_path)
	_profile = ProfileStats.load_from(_profile_storage)
	_tracker = ProfileTracker.new(_profile)
	_tracker.changed.connect(_save_profile)
	_run_storage = SaveStorage.new(run_path)
	_show_menu()


func _show_menu() -> void:
	var menu := MENU_SCENE.instantiate()
	menu.saved_run = _saved_run_preview()
	menu.start_requested.connect(_start_new_run)
	menu.continue_requested.connect(_continue_run)
	menu.stats_requested.connect(_show_stats)
	_swap(menu)


func _show_stats() -> void:
	var stats := STATS_SCENE.instantiate()
	stats.profile = _profile
	stats.content = _content
	stats.back_requested.connect(_show_menu)
	_swap(stats)


func _start_new_run() -> void:
	_run_storage.delete()
	_show_run({})


func _continue_run() -> void:
	_show_run(_run_storage.load_data())


func _show_run(resume_data: Dictionary) -> void:
	var run_screen := RUN_SCENE.instantiate()
	run_screen.content = _content
	run_screen.run_storage = _run_storage
	run_screen.resume_data = resume_data
	# Branche avant add_child : run_created est emis pendant le _ready de l'ecran.
	run_screen.run_created.connect(func(run: RunState, resumed: bool) -> void: _tracker.track(run, not resumed))
	run_screen.menu_requested.connect(_show_menu)
	_swap(run_screen)


## Run sauvegardee restauree avec une RNG jetable, pour l'apercu du menu. null si absente ou inutilisable.
func _saved_run_preview() -> RunState:
	var data := _run_storage.load_data()
	if data.is_empty():
		return null
	return RunSnapshot.restore(data, _content, RandomNumberGenerator.new())


func _swap(screen: Node) -> void:
	if _screen != null:
		_screen.queue_free()
	_screen = screen
	add_child(screen)


func _save_profile() -> void:
	if not _profile.save_to(_profile_storage):
		push_warning("Profil non sauvegarde : %s" % _profile_storage.last_error)