class_name SaveStorage
extends RefCounted
## Lit et ecrit un Dictionary en JSON. Jamais de .tres pour une sauvegarde : charger une ressource
## venant du disque du joueur peut executer du code. Ne fait jamais planter le jeu : voir last_error.

var path: String
var last_error: String = ""


func _init(p_path: String) -> void:
	path = p_path


func save(data: Dictionary) -> bool:
	last_error = ""
	var tmp_path: String = path + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		last_error = "ecriture impossible : %s" % error_string(FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	# Ecrire a cote puis renommer : une coupure pendant l'ecriture ne corrompt pas l'ancienne sauvegarde.
	var error := DirAccess.rename_absolute(tmp_path, path)
	if error != OK:
		last_error = "renommage impossible : %s" % error_string(error)
		return false
	return true


## Renvoie {} si le fichier n'existe pas ou n'est pas un objet JSON valide.
func load_data() -> Dictionary:
	last_error = ""
	if not FileAccess.file_exists(path):
		return {}
	# JSON.new().parse() plutot que JSON.parse_string() : pas d'erreur moteur sur un fichier corrompu.
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		last_error = "fichier illisible : %s" % json.get_error_message()
		return {}
	if not json.data is Dictionary:
		last_error = "fichier illisible : pas un objet JSON"
		return {}
	return json.data


func delete() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)