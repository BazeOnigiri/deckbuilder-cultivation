extends GutTest
## Options : les curseurs de volume montrent le reglage et le modifient.

const SCREEN := preload("res://ui/options/options_screen.tscn")


func test_curseur_de_musique() -> void:
	var screen: Control = SCREEN.instantiate()
	screen.settings.music_volume = 0.25
	add_child_autofree(screen)
	var slider: HSlider = screen.get_node("%MusicVolume")
	assert_eq(slider.value, 0.25)
	watch_signals(screen)
	slider.value = 0.5
	assert_eq(screen.settings.music_volume, 0.5)
	assert_signal_emitted(screen, "settings_changed")


func test_langue_choisie_dans_la_liste() -> void:
	var screen: Control = SCREEN.instantiate()
	add_child_autofree(screen)
	watch_signals(screen)
	var other := 1 - GameSettings.LANGUAGES.find(screen.settings.language)
	screen.get_node("%Language").item_selected.emit(other)
	assert_eq(screen.settings.language, GameSettings.LANGUAGES[other])
	assert_signal_emitted(screen, "settings_changed")


func test_case_contraste_modifie_le_reglage() -> void:
	var screen: Control = SCREEN.instantiate()
	add_child_autofree(screen)
	screen.get_node("%HighContrast").button_pressed = true
	assert_true(screen.settings.high_contrast)


func test_plein_ecran_perdu_decoche_la_case() -> void:
	var screen: Control = SCREEN.instantiate()
	screen.settings.fullscreen = true
	add_child_autofree(screen)
	assert_true(screen.get_node("%Fullscreen").button_pressed)
	screen.settings.sync_fullscreen(false)
	assert_false(screen.get_node("%Fullscreen").button_pressed)


func after_each() -> void:
	KeyBindings.apply({})


func test_focus_initial_sur_le_premier_reglage() -> void:
	var screen: Control = add_child_autofree(SCREEN.instantiate())
	assert_true(screen.get_node("%ReduceMotion").has_focus())


func test_nouvelle_touche_sauvee_dans_les_reglages() -> void:
	var screen: Control = add_child_autofree(SCREEN.instantiate())
	watch_signals(screen)
	assert_true(screen.set_key(&"discard_hand", KEY_K))
	assert_eq(screen.settings.key_bindings, {"discard_hand": KEY_K})
	assert_eq(Keys.name_of(&"discard_hand", false), "K")
	assert_signal_emitted(screen, "settings_changed")


func test_touche_reservee_refusee_dans_les_options() -> void:
	var screen: Control = add_child_autofree(SCREEN.instantiate())
	assert_false(screen.set_key(&"discard_hand", KEY_ESCAPE))
	assert_eq(screen.settings.key_bindings, {})


func test_capture_d_une_touche_puis_retour_par_defaut() -> void:
	var screen: Control = add_child_autofree(SCREEN.instantiate())
	screen._show_keys()
	screen._key_buttons[&"play_hand"].pressed.emit()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_P
	key.pressed = true
	get_viewport().push_input(key)
	assert_eq(screen.settings.key_bindings, {"play_hand": KEY_P})
	assert_eq(screen._key_buttons[&"play_hand"].text, "P")
	screen._reset_keys()
	assert_eq(screen.settings.key_bindings, {})
	assert_eq(screen._key_buttons[&"play_hand"].text, Keys.name_of(&"play_hand", false))
