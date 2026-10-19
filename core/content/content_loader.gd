class_name ContentLoader
extends RefCounted
## Charge toutes les ressources d'un dossier de content/.
## Ajouter un fichier suffit, rien a declarer ailleurs.


static func load_all(dir_path: String) -> Array[Resource]:
	var result: Array[Resource] = []
	var res_names: Array[String] = []
	for file_name: String in DirAccess.get_files_at(dir_path):
		# En export web, les .tres deviennent "x.tres.remap" : on retire le suffixe.
		var clean: String = file_name.trim_suffix(".remap")
		if (clean.ends_with(".tres") or clean.ends_with(".res")) and not res_names.has(clean):
			res_names.append(clean)
	res_names.sort()
	for res_name: String in res_names:
		var res: Resource = load(dir_path.path_join(res_name))
		if res != null:
			result.append(res)
	return result