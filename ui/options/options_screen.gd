extends Control
## Ecran des reglages du joueur. Ouvert depuis une run (in_run), il propose aussi le retour au menu et une nouvelle partie.

signal back_requested
## Emis a chaque changement : main sauvegarde et applique.
signal settings_changed
## Depuis une run seulement. La run est deja sauvegardee : le menu propose de la continuer.
signal menu_requested
## Depuis une run seulement, apres confirmation : la run en cours est abandonnee.
signal new_run_requested

## Injecte par main avant l'ajout a l'arbre. Par defaut des reglages neufs (scene lancee seule, tests).
var settings: GameSettings = GameSettings.new()
## Pose par main avant l'ajout a l'arbre quand les options s'ouvrent par-dessus une run.
var in_run: bool = false

var _confirm: ScrollOverlay
var _confirm_button: Button


func _ready() -> void:
	# Avant de brancher les signaux : afficher la valeur ne doit pas compter comme un changement.
	%ReduceMotion.button_pressed = settings.reduce_motion
	%Fullscreen.button_pressed = settings.fullscreen
	%HighContrast.button_pressed = settings.high_contrast
	_fill_options()
	_bind_volume(%MasterVolume, "master_volume")
	_bind_volume(%MusicVolume, "music_volume")
	_bind_volume(%EffectsVolume, "effects_volume")
	%ReduceMotion.toggled.connect(_on_reduce_motion_toggled)
	%Fullscreen.toggled.connect(_on_fullscreen_toggled)
	# Plein ecran refuse ou quitte (Echap) : la case se decoche sans repasser par toggled.
	settings.fullscreen_lost.connect(func() -> void: %Fullscreen.set_pressed_no_signal(false))
	%HighContrast.toggled.connect(_on_high_contrast_toggled)
	%Language.item_selected.connect(_on_language_selected)
	%GameSpeed.item_selected.connect(_on_game_speed_selected)
	%BackButton.pressed.connect(back_requested.emit)
	%RunButtons.visible = in_run
	%MenuButton.pressed.connect(menu_requested.emit)
	%NewRunButton.pressed.connect(_ask_new_run)
	%BackButton.reduce_motion = settings.reduce_motion
	%Scroll.unroll(0.0 if settings.reduce_motion else get_theme_constant(&"unroll_ms", &"ScrollPanel") / 1000.0)


## Items construits en code : refaits quand la langue change, leur texte depend d'elle.
func _fill_options() -> void:
	%GameSpeed.clear()
	for speed: float in GameSettings.GAME_SPEEDS:
		%GameSpeed.add_item(tr("UI_OPTIONS_SPEED_ITEM") % str(speed).trim_suffix(".0").replace(".", tr("UI_DECIMAL_SEPARATOR")))
	%GameSpeed.select(maxi(GameSettings.GAME_SPEEDS.find(settings.game_speed), 0))
	%Language.clear()
	for code: String in GameSettings.LANGUAGES:
		%Language.add_item(tr("UI_LANGUAGE_" + code.to_upper()))
	%Language.select(maxi(GameSettings.LANGUAGES.find(settings.language), 0))


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_fill_options()


## Le curseur montre le reglage puis l'ecrit a chaque cran (step 0.05 : une vingtaine d'ecritures au plus par glisse).
func _bind_volume(slider: HSlider, property: String) -> void:
	slider.custom_minimum_size.x = get_theme_constant(&"width", &"ScrollSlider")
	slider.set_value_no_signal(settings.get(property))
	slider.value_changed.connect(func(value: float) -> void:
		settings.set(property, value)
		settings_changed.emit())


func _ask_new_run() -> void:
	var body := VBoxContainer.new()
	var question := SideColumn.make_label(&"ScrollText", "UI_OPTIONS_NEW_RUN_CONFIRM")
	question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question.custom_minimum_size.x = get_theme_constant(&"text_width", &"ScrollPanel")
	body.add_child(question)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override(&"separation", get_theme_constant(&"separation", &"ScrollPanel"))
	_confirm_button = _seal("UI_OPTIONS_NEW_RUN")
	_confirm_button.pressed.connect(new_run_requested.emit)
	actions.add_child(_confirm_button)
	var cancel := _seal("UI_CANCEL")
	actions.add_child(cancel)
	body.add_child(actions)
	_confirm = ScrollOverlay.open(self, "UI_OPTIONS_NEW_RUN", body, not settings.reduce_motion)
	_confirm.hide_close()
	cancel.pressed.connect(_confirm.close)


func _seal(text_key: String) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"SealButton"
	button.text = text_key
	return button


func _on_reduce_motion_toggled(on: bool) -> void:
	settings.reduce_motion = on
	settings_changed.emit()


func _on_fullscreen_toggled(on: bool) -> void:
	settings.fullscreen = on
	settings_changed.emit()


func _on_game_speed_selected(index: int) -> void:
	settings.game_speed = GameSettings.GAME_SPEEDS[index]
	settings_changed.emit()


func _on_high_contrast_toggled(on: bool) -> void:
	settings.high_contrast = on
	settings_changed.emit()


func _on_language_selected(index: int) -> void:
	settings.language = GameSettings.LANGUAGES[index]
	settings_changed.emit()
