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
