extends GutTest

const PATH := "user://test_save_storage.json"

var _storage: SaveStorage


func before_each() -> void:
	_storage = SaveStorage.new(PATH)
	_storage.delete()


func after_each() -> void:
	_storage.delete()


func test_aller_retour() -> void:
	assert_true(_storage.save({"version": 1, "nom": "test"}))
	var data := _storage.load_data()
	assert_eq(data["nom"], "test")
	assert_false(FileAccess.file_exists(PATH + ".tmp"))


func test_ecraser_une_sauvegarde_existante() -> void:
	_storage.save({"valeur": 1})
	assert_true(_storage.save({"valeur": 2}))
	assert_eq(int(_storage.load_data()["valeur"]), 2)


func test_fichier_absent_donne_un_dictionnaire_vide() -> void:
	assert_eq(_storage.load_data(), {})
	assert_eq(_storage.last_error, "")


func test_fichier_corrompu_donne_un_dictionnaire_vide() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("{ pas du json")
	file.close()
	assert_eq(_storage.load_data(), {})
	assert_ne(_storage.last_error, "")