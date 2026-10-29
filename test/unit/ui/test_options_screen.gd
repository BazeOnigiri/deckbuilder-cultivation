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
