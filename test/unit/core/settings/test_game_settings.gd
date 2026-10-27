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

