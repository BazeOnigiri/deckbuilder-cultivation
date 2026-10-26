extends Control
## Racine du jeu : machine a etats MENU / RUN / STATS / OPTIONS.
## Possede le contenu, le profil, les reglages et la sauvegarde de run, partages entre les ecrans.

const MENU_SCENE := preload("res://ui/menu/menu_screen.tscn")
const RUN_SCENE := preload("res://ui/round/round_screen.tscn")
const STATS_SCENE := preload("res://ui/stats/stats_screen.tscn")
const OPTIONS_SCENE := preload("res://ui/options/options_screen.tscn")
## Parametre global de shader (declare dans project.godot) : 0 fige les shaders animes.
const MOTION_SCALE := &"motion_scale"

## Les tests les remplacent pour ne pas toucher aux vraies sauvegardes.
@export var profile_path: String = ProfileStats.DEFAULT_PATH
@export var run_path: String = RunSnapshot.DEFAULT_PATH
@export var settings_path: String = GameSettings.DEFAULT_PATH

var _screen: Node
var _content: GameContent
var _profile: ProfileStats
var _profile_storage: SaveStorage
var _tracker: ProfileTracker
var _run_storage: SaveStorage
var _settings: GameSettings
var _settings_storage: SaveStorage


func _ready() -> void:
	_settings_storage = SaveStorage.new(settings_path)
	_settings = GameSettings.load_from(_settings_storage)
	_apply_settings()
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
	menu.options_requested.connect(_show_options)
	_swap(menu)


func _show_options() -> void:
	var options := _options_screen()
	options.back_requested.connect(_show_menu)
	_swap(options)


## Depuis la run : les reglages sur un voile par-dessus l'ecran de run, qui reste tel quel dessous.
func _show_options_over_run() -> void:
	var veil := PanelContainer.new()
	veil.theme_type_variation = &"Veil"
	veil.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var options := _options_screen()
	options.back_requested.connect(veil.queue_free)
	veil.add_child(options)
	add_child(veil)


func _options_screen() -> Node:
	var options := OPTIONS_SCENE.instantiate()
	options.settings = _settings
	options.settings_changed.connect(_on_settings_changed)
	return options


func _on_settings_changed() -> void:
	_apply_settings()
	if not _settings.save_to(_settings_storage):
		push_warning("Reglages non sauvegardes : %s" % _settings_storage.last_error)


func _apply_settings() -> void:
	RenderingServer.global_shader_parameter_set(MOTION_SCALE, 0.0 if _settings.reduce_motion else 1.0)


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
	run_screen.settings = _settings
	# Branche avant add_child : run_created est emis pendant le _ready de l'ecran.
	run_screen.run_created.connect(func(run: RunState, resumed: bool) -> void: _tracker.track(run, not resumed))
	run_screen.menu_requested.connect(_show_menu)
	run_screen.options_requested.connect(_show_options_over_run)
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