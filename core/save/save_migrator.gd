class_name SaveMigrator
extends RefCounted
## Fait passer une sauvegarde de sa version a la version courante, une migration a la fois.
## migrations[n] est un Callable qui transforme une sauvegarde de version n en version n + 1.


## Renvoie {} si la sauvegarde est vide, vient d'une version plus recente du jeu, ou si une migration manque.
static func migrate(data: Dictionary, current_version: int, migrations: Dictionary) -> Dictionary:
	if data.is_empty():
		return {}
	# Une version qui n'est pas un nombre (null, tableau...) : sauvegarde illisible, refusee.
	if data.has("version") and not (data["version"] is int or data["version"] is float):
		return {}
	# Les nombres JSON sont lus en float : int_of les remet en entier.
	var version: int = SaveData.int_of(data, "version", 1)
	if version > current_version:
		return {}
	var result: Dictionary = data.duplicate(true)
	while version < current_version:
		if not migrations.has(version):
			return {}
		result = migrations[version].call(result)
		version += 1
		result["version"] = version
	return result