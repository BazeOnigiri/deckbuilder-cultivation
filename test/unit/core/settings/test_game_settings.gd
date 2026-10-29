extends GutTest

const PATH := "user://test_game_settings.json"


func after_each() -> void:
	SaveStorage.new(PATH).delete()


func test_aller_retour_sur_disque() -> void:
	var storage := SaveStorage.new(PATH)
	var settings := GameSettings.new()
	settings.reduce_motion = true
	assert_true(settings.save_to(storage))
	assert_true(GameSettings.load_from(storage).reduce_motion)


func test_fichier_absent_donne_les_valeurs_par_defaut() -> void:
	assert_false(GameSettings.load_from(SaveStorage.new(PATH)).reduce_motion)


func test_valeur_de_mauvais_type_ignoree() -> void:
	assert_false(GameSettings.from_dict({"reduce_motion": "oui"}).reduce_motion)
	assert_false(GameSettings.from_dict({"reduce_motion": 1}).reduce_motion)


func test_version_plus_recente_ignoree() -> void:
	var storage := SaveStorage.new(PATH)
	storage.save({"version": GameSettings.VERSION + 1, "settings": {"reduce_motion": true}})
	assert_false(GameSettings.load_from(storage).reduce_motion)


func test_vitesse_et_plein_ecran_sur_disque() -> void:
	var storage := SaveStorage.new(PATH)
	var settings := GameSettings.new()
	settings.game_speed = 2.0
	settings.fullscreen = true
	settings.save_to(storage)
	var loaded := GameSettings.load_from(storage)
	assert_eq(loaded.game_speed, 2.0)
	assert_true(loaded.fullscreen)


func test_vitesse_inconnue_revient_a_1() -> void:
	assert_eq(GameSettings.from_dict({"game_speed": 7.0}).game_speed, 1.0)
	assert_eq(GameSettings.from_dict({"game_speed": "vite"}).game_speed, 1.0)
	assert_eq(GameSettings.from_dict({"game_speed": 3}).game_speed, 3.0)


func test_volumes_sur_disque() -> void:
	var storage := SaveStorage.new(PATH)
	var settings := GameSettings.new()
	settings.master_volume = 0.5
	settings.music_volume = 0.0
	settings.effects_volume = 1.0
	settings.save_to(storage)
	var loaded := GameSettings.load_from(storage)
	assert_eq([loaded.master_volume, loaded.music_volume, loaded.effects_volume], [0.5, 0.0, 1.0])


func test_volume_hors_bornes_ou_absent() -> void:
	var defaults := GameSettings.new()
	var settings := GameSettings.from_dict({"master_volume": 3, "music_volume": "fort"})
	assert_eq(settings.master_volume, 1.0, "borne a 1")
	assert_eq(settings.music_volume, defaults.music_volume, "mauvais type : valeur par defaut")
	assert_eq(settings.effects_volume, defaults.effects_volume, "ancien fichier sans volume")



func test_langue_sauvee_et_relue() -> void:
	var storage := SaveStorage.new(PATH)
	var settings := GameSettings.new()
	settings.language = "fr" if GameSettings.default_language() == "en" else "en"
	assert_true(settings.save_to(storage))
	assert_eq(GameSettings.load_from(storage).language, settings.language)


func test_langue_invalide_ou_absente_donne_le_defaut() -> void:
	assert_eq(GameSettings.from_dict({"language": "de"}).language, GameSettings.default_language())
	assert_eq(GameSettings.from_dict({"language": 3}).language, GameSettings.default_language())
	assert_eq(GameSettings.from_dict({}).language, GameSettings.default_language())
	assert_true(GameSettings.LANGUAGES.has(GameSettings.default_language()))


func test_contraste_eleve_sauve_et_relu() -> void:
	var storage := SaveStorage.new(PATH)
	var settings := GameSettings.new()
	settings.high_contrast = true
	assert_true(settings.save_to(storage))
	assert_true(GameSettings.load_from(storage).high_contrast)
	assert_false(GameSettings.from_dict({"high_contrast": "oui"}).high_contrast)
	assert_false(GameSettings.from_dict({}).high_contrast)


func test_plein_ecran_refuse_decoche_la_case() -> void:
	var settings := GameSettings.new()
	settings.fullscreen = true
	watch_signals(settings)
	assert_false(settings.sync_fullscreen(true))
	assert_signal_not_emitted(settings, "fullscreen_lost")
	assert_true(settings.sync_fullscreen(false))
	assert_false(settings.fullscreen)
	assert_signal_emitted(settings, "fullscreen_lost")


func test_touches_choisies_sauvees_et_relues() -> void:
	var storage := SaveStorage.new(PATH)
	var settings := GameSettings.new()
	settings.key_bindings = {"play_hand": KEY_P}
	assert_true(settings.save_to(storage))
	assert_eq(GameSettings.load_from(storage).key_bindings, {"play_hand": KEY_P})


func test_ancien_fichier_sans_touches_garde_celles_par_defaut() -> void:
	assert_eq(GameSettings.from_dict({"reduce_motion": true}).key_bindings, {})


func test_touches_invalides_ignorees() -> void:
	var data := {"key_bindings": {"play_hand": "P", "action_inconnue": KEY_P, "discard_hand": -3,
		"show_deck": float(KEY_T)}}
	assert_eq(GameSettings.from_dict(data).key_bindings, {"show_deck": KEY_T})
	assert_eq(GameSettings.from_dict({"key_bindings": [1, 2]}).key_bindings, {})
