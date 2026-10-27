extends GutTest
## Sons generes : chaque recette exportee de tools/sons/recettes.json a son .wav, lisible par Godot, et aucun .wav orphelin.

const RECIPES := "res://tools/sons/recettes.json"


func _recipes() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(RECIPES))


## id -> chemins des .wav : <id>.wav, ou <id>_1.wav, <id>_2.wav... avec des variantes (meme regle que le script).
func _takes() -> Dictionary:
	var data := _recipes()
	var takes := {}
	for recipe: Dictionary in data["recettes"]:
		if not recipe.get("export", true):
			continue
		var folder: String = "res://" + recipe.get("dossier", data["dossier"])
		var count: int = recipe.get("variantes", []).size()
		var paths: Array[String] = []
		for i: int in count:
			paths.append(folder.path_join("%s_%d.wav" % [recipe["id"], i + 1]))
		if count == 0:
			paths.append(folder.path_join(recipe["id"] + ".wav"))
		takes[recipe["id"]] = paths
	return takes


## id -> premier .wav (les musiques n'ont qu'une prise).
func _exported() -> Dictionary:
	var paths := {}
	var takes := _takes()
	for id: String in takes:
		paths[id] = takes[id][0]
	return paths


func test_chaque_recette_a_son_fichier() -> void:
	var takes := _takes()
	for id: String in takes:
		for path: String in takes[id]:
			var stream := load(path) as AudioStreamWAV
			assert_not_null(stream, path)
			if stream != null:
				assert_gt(stream.get_length(), 0.0, path)


## Effet mitraillette : les sons les plus frequents ont plusieurs prises, et la fiche les liste toutes.
func test_sons_frequents_en_plusieurs_prises() -> void:
	var takes := _takes()
	for id: String in ["ui_clic", "ui_survol", "carte_selection", "carte_deselection", "carte_pioche", "carte_jouee",
			"note_carte", "orbe_depart", "orbe_impact", "multiplication"]:
		assert_gt(takes[id].size(), 1, id)
		var cue: SoundCue = load("res://content/sons/%s.tres" % id)
		assert_eq(cue.streams.size(), takes[id].size(), "fiche de %s" % id)


func test_aucun_fichier_orphelin() -> void:
	var paths: Array = []
	for list: Array in _takes().values():
		paths.append_array(list)
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

