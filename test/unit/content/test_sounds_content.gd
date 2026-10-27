extends GutTest
## Sons generes : chaque recette exportee de tools/sons/recettes.json a son .wav, lisible par Godot, et aucun .wav orphelin.

const RECIPES := "res://tools/sons/recettes.json"


func _recipes() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(RECIPES))


func _exported_ids() -> Array[String]:
	var ids: Array[String] = []
	for recipe: Dictionary in _recipes()["recettes"]:
		if recipe.get("export", true):
			ids.append(recipe["id"])
	return ids


func test_chaque_recette_a_son_fichier() -> void:
	var folder: String = "res://" + _recipes()["dossier"]
	for id: String in _exported_ids():
		var stream := load("%s/%s.wav" % [folder, id]) as AudioStreamWAV
		assert_not_null(stream, id)
		if stream != null:
			assert_gt(stream.get_length(), 0.0, id)


func test_aucun_fichier_orphelin() -> void:
	var folder: String = "res://" + _recipes()["dossier"]
	var ids := _exported_ids()
	for file: String in DirAccess.get_files_at(folder):
		if file.ends_with(".wav"):
			assert_has(ids, file.get_basename(), "%s n'a plus de recette : relancer le script ou le supprimer" % file)
