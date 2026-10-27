extends GutTest
## Sons generes : chaque recette exportee de tools/sons/recettes.json a son .wav, lisible par Godot, et aucun .wav orphelin.

const RECIPES := "res://tools/sons/recettes.json"


func _recipes() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(RECIPES))


## id -> chemin du .wav (dossier de la recette, ou dossier par defaut).
func _exported() -> Dictionary:
	var data := _recipes()
	var paths := {}
	for recipe: Dictionary in data["recettes"]:
		if recipe.get("export", true):
			paths[recipe["id"]] = "res://%s/%s.wav" % [recipe.get("dossier", data["dossier"]), recipe["id"]]
	return paths


func test_chaque_recette_a_son_fichier() -> void:
	var paths := _exported()
	for id: String in paths:
		var stream := load(paths[id]) as AudioStreamWAV
		assert_not_null(stream, id)
		if stream != null:
			assert_gt(stream.get_length(), 0.0, id)


func test_aucun_fichier_orphelin() -> void:
	var paths: Array = _exported().values()
	var folders := {}
	for path: String in paths:
		folders[path.get_base_dir()] = true
	for folder: String in folders:
		for file: String in DirAccess.get_files_at(folder):
			if file.ends_with(".wav"):
				assert_has(paths, folder.path_join(file), "%s n'a plus de recette : relancer le script ou le supprimer" % file)


## Les musiques tournent en boucle : reglage d'import edit/loop_mode=2 (en avant), a remettre si le .import est recree.
func test_musiques_en_boucle() -> void:
	for id: String in _exported():
		if id.begins_with("musique_"):
			var stream: AudioStreamWAV = load(_exported()[id])
			assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD, id)


## Les variantes jouent synchronisees : meme longueur, sinon elles se decalent a chaque boucle.
func test_variantes_de_musique_de_meme_longueur() -> void:
	var lengths := {}
	for id: String in _exported():
		if id.begins_with("musique_"):
			lengths[id] = (load(_exported()[id]) as AudioStreamWAV).get_length()
	assert_gt(lengths.size(), 1)
	for id: String in lengths:
		assert_almost_eq(lengths[id], lengths.values()[0], 0.0001, id)

