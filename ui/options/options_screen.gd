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
## Rouleau des touches : un bouton par action de jeu, et l'action qui attend sa nouvelle touche (&"" : aucune).
var _keys_scroll: ScrollOverlay
var _key_buttons: Dictionary[StringName, Button] = {}
var _key_status: Label
var _capturing: StringName = &""


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
	var keys := _seal("UI_OPTIONS_KEYS")
	keys.size_flags_horizontal = SIZE_SHRINK_CENTER
	keys.pressed.connect(_show_keys)
	%RunButtons.add_sibling(keys)
	%RunButtons.get_parent().move_child(keys, %RunButtons.get_index())
	%ReduceMotion.grab_focus(not Focus.shown)
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


## Liste des actions de jeu et de leur touche. Clic (ou valider) sur une touche, puis appui sur la nouvelle.
func _show_keys() -> void:
	var body := VBoxContainer.new()
	var grid := GridContainer.new()
	grid.columns = 2
	_key_buttons.clear()
	for entry: Array in Keys.LISTED:
		var action: StringName = entry[0]
		if not KeyBindings.ACTIONS.has(action):
			continue
		var label := SideColumn.make_label(&"ScrollText")
		label.text = Keys.text_of(entry[1])
		label.size_flags_horizontal = SIZE_EXPAND_FILL
		grid.add_child(label)
		var button := _seal("")
		button.pressed.connect(_capture.bind(action))
		grid.add_child(button)
		_key_buttons[action] = button
	body.add_child(grid)
	_key_status = SideColumn.make_label(&"ScrollCaption")
	_key_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_key_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_key_status.custom_minimum_size.x = get_theme_constant(&"text_width", &"ScrollPanel")
	body.add_child(_key_status)
	var defaults := _seal("UI_OPTIONS_KEYS_DEFAULT")
	defaults.size_flags_horizontal = SIZE_SHRINK_CENTER
	defaults.pressed.connect(_reset_keys)
	body.add_child(defaults)
	_keys_scroll = ScrollOverlay.open(self, "UI_OPTIONS_KEYS", body, not settings.reduce_motion)
	_keys_scroll.closed.connect(func() -> void: _capturing = &"")
	_refresh_keys()


func _refresh_keys() -> void:
	for action: StringName in _key_buttons:
		_key_buttons[action].text = tr("UI_OPTIONS_PRESS_KEY") if action == _capturing else Keys.name_of(action, false)


func _capture(action: StringName) -> void:
	_capturing = action
	_key_status.text = ""
	_refresh_keys()


## La touche attendue est lue avant tout le reste : Echap annule au lieu de fermer le rouleau.
func _input(event: InputEvent) -> void:
	if _capturing == &"" or not event.is_pressed() or event.is_echo():
		return
	if not (event is InputEventKey or event.is_action(&"ui_cancel")):
		return
	get_viewport().set_input_as_handled()
	var action := _capturing
	_capturing = &""
	var key := event as InputEventKey
	if key != null and not event.is_action(&"ui_cancel"):
		set_key(action, key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode)
	_refresh_keys()


## Echange avec une autre action de jeu ; une touche reservee (Echap, Espace, fleches, chiffres) est refusee.
func set_key(action: StringName, keycode: int) -> bool:
	var other := KeyBindings.owner_of(keycode, settings.key_bindings)
	if not KeyBindings.rebind(settings.key_bindings, action, keycode):
		if _key_status != null:
			_key_status.text = tr("UI_OPTIONS_KEY_TAKEN") % OS.get_keycode_string(keycode)
		return false
	KeyBindings.apply(settings.key_bindings)
	if _key_status != null:
		_key_status.text = "" if other == &"" or other == action else tr("UI_OPTIONS_KEY_SWAPPED") % Keys.text_of(_label_of(other))
	settings_changed.emit()
	return true


func _reset_keys() -> void:
	settings.key_bindings.clear()
	KeyBindings.apply(settings.key_bindings)
	_capturing = &""
	if _key_status != null:
		_key_status.text = ""
	settings_changed.emit()
	_refresh_keys()


func _label_of(action: StringName) -> String:
	for entry: Array in Keys.LISTED:
		if entry[0] == action:
			return entry[1]
	return String(action)


## Manette : B (ui_cancel) ferme les reglages comme le sceau Retour. Un rouleau ouvert le prend avant.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		back_requested.emit()


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
