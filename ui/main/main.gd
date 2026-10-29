extends Control
## Racine du jeu : machine a etats MENU / RUN / STATS / COMPENDIUM / OPTIONS.
## Possede le contenu, le profil, les reglages et la sauvegarde de run, partages entre les ecrans.

const MENU_SCENE := preload("res://ui/menu/menu_screen.tscn")
const RUN_SCENE := preload("res://ui/round/round_screen.tscn")
const STATS_SCENE := preload("res://ui/stats/stats_screen.tscn")
const COMPENDIUM_SCENE := preload("res://ui/compendium/compendium_screen.tscn")
const OPTIONS_SCENE := preload("res://ui/options/options_screen.tscn")
## Parametre global de shader (declare dans project.godot) : 0 fige les shaders animes.
const MOTION_SCALE := &"motion_scale"
## Ambiance du menu et des ecrans hors run.
const MENU_AMBIANCE := &"menu"
## Surcharges de couleurs du mode contraste eleve : posees sur la racine, le Theme du projet reste dessous.
const CONTRAST_THEME := preload("res://ui/theme/contraste.tres")
## Titre de la fenetre et de l'onglet web (config/name reste le nom stable des dossiers de sauvegarde).
const WINDOW_TITLE := "五行 Wu Xing"

## Les tests les remplacent pour ne pas toucher aux vraies sauvegardes.
@export var profile_path: String = ProfileStats.DEFAULT_PATH
@export var run_path: String = RunSnapshot.DEFAULT_PATH
@export var settings_path: String = GameSettings.DEFAULT_PATH

var _screen: Node
var _stick: StickRepeat
var _content: GameContent
var _profile: ProfileStats
var _profile_storage: SaveStorage
var _tracker: ProfileTracker
var _run_storage: SaveStorage
var _settings: GameSettings
var _settings_storage: SaveStorage


func _ready() -> void:
	DisplayServer.window_set_title(WINDOW_TITLE)
	_settings_storage = SaveStorage.new(settings_path)
	_settings = GameSettings.load_from(_settings_storage)
	# En web le navigateur refuse le plein ecran sans geste du joueur : jamais applique au demarrage.
	if OS.has_feature("web"):
		_settings.fullscreen = false
	get_window().size_changed.connect(_confirm_fullscreen)
	_apply_settings()
	_content = GameContent.load_default()
	_profile_storage = SaveStorage.new(profile_path)
	_profile = ProfileStats.load_from(_profile_storage)
	_tracker = ProfileTracker.new(_profile, _content.profile_rules, _content.unlocks)
	_tracker.changed.connect(_save_profile)
	_run_storage = SaveStorage.new(run_path)
	_show_menu()


## open_new_run : le rouleau Nouvelle partie s'ouvre aussitot (nouvelle partie demandee depuis la run).
func _show_menu(open_new_run: bool = false) -> void:
	var menu := MENU_SCENE.instantiate()
	menu.saved_run = _saved_run_preview()
	menu.settings = _settings
	menu.content = _content
	menu.offer_help = _profile.should_offer_help()
	menu.help_offered.connect(func() -> void:
		_profile.help_offered = true
		_save_profile())
	menu.profile = _profile
	menu.open_new_run = open_new_run
	menu.start_requested.connect(_start_new_run)
	menu.continue_requested.connect(_continue_run)
	menu.stats_requested.connect(_show_stats)
	menu.compendium_requested.connect(_show_compendium)
	menu.options_requested.connect(_show_options)
	menu.quit_requested.connect(get_tree().quit)
	_swap(menu)
	Ambiance.apply(MENU_AMBIANCE)


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
	options.in_run = true
	options.back_requested.connect(veil.queue_free)
	options.menu_requested.connect(func() -> void:
		veil.queue_free()
		_show_menu())
	options.new_run_requested.connect(func() -> void:
		veil.queue_free()
		_show_menu(true))
	add_child(veil)
	# Avant d'y poser les reglages : la run dessous ne prend plus le focus, et le retrouve a la fermeture.
	Focus.trap(veil)
	veil.add_child(options)
	# Le voile prend la souris, pas le clavier : la run dessous ne lit plus ses touches tant qu'il est ouvert.
	var run_screen := _screen
	run_screen.set_process_unhandled_input(false)
	veil.tree_exited.connect(func() -> void:
		if is_instance_valid(run_screen):
			run_screen.set_process_unhandled_input(true))


func _options_screen() -> Node:
	var options := OPTIONS_SCENE.instantiate()
	options.settings = _settings
	options.settings_changed.connect(_on_settings_changed)
	return options


func _on_settings_changed() -> void:
	_apply_settings()
	_on_settings_saved()


func _on_settings_saved() -> void:
	if not _settings.save_to(_settings_storage):
		push_warning("Reglages non sauvegardes : %s" % _settings_storage.last_error)


func _apply_settings() -> void:
	RenderingServer.global_shader_parameter_set(MOTION_SCALE, 0.0 if _settings.reduce_motion else 1.0)
	Ambiance.reduce_motion = _settings.reduce_motion
	Sons.apply_volumes(_settings)
	# Accelere tout ce qui suit le temps du moteur (tweens, minuteurs), pas les shaders.
	Engine.time_scale = _settings.game_speed
	TranslationServer.set_locale(_settings.language)
	KeyBindings.apply(_settings.key_bindings)
	theme = CONTRAST_THEME if _settings.high_contrast else null
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if _settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
		if _settings.fullscreen:
			# Delai ignorant l'acceleration du jeu : si la fenetre n'est pas passee en plein ecran, la case se decoche.
			get_tree().create_timer(GameSettings.FULLSCREEN_CONFIRM_SECONDS, true, false, true).timeout.connect(_confirm_fullscreen)


## Echap ou refus du navigateur : la case suit l'etat reel de la fenetre.
func _confirm_fullscreen() -> void:
	if _settings.sync_fullscreen(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN):
		_on_settings_saved()


## Souris et doigt cachent le focus pose par le jeu, clavier et manette le montrent.
func _input(event: InputEvent) -> void:
	Focus.note_input(event)
	if _stick == null:
		_stick = StickRepeat.new(get_theme_constant(&"stick_repeat_ms", &"FocusNav"))
	if not _stick.allow(event, Time.get_ticks_msec()):
		get_viewport().set_input_as_handled()


func _show_stats() -> void:
	var stats := STATS_SCENE.instantiate()
	stats.profile = _profile
	stats.settings = _settings
	stats.content = _content
	stats.back_requested.connect(_show_menu)
	_swap(stats)


func _show_compendium() -> void:
	var compendium := COMPENDIUM_SCENE.instantiate()
	compendium.profile = _profile
	compendium.settings = _settings
	compendium.content = _content
	compendium.back_requested.connect(_show_menu)
	_swap(compendium)


func _start_new_run(setup: RunSetup) -> void:
	_run_storage.delete()
	_show_run({}, setup)


func _continue_run() -> void:
	_show_run(_run_storage.load_data())


func _show_run(resume_data: Dictionary, setup: RunSetup = RunSetup.new()) -> void:
	var run_screen := RUN_SCENE.instantiate()
	run_screen.setup = setup
	run_screen.content = _content
	run_screen.run_storage = _run_storage
	run_screen.resume_data = resume_data
	run_screen.settings = _settings
	run_screen.profile = _profile
	run_screen.tracker = _tracker
	# Branche avant add_child : run_created est emis pendant le _ready de l'ecran.
	run_screen.run_created.connect(func(run: RunState, resumed: bool) -> void: _tracker.track(run, not resumed))
	run_screen.shop_created.connect(_tracker.track_shop)
	run_screen.menu_requested.connect(_show_menu)
	run_screen.options_requested.connect(_show_options_over_run)
	run_screen.ambiance_changed.connect(Ambiance.apply)
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