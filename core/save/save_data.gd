class_name SaveData
extends RefCounted
## Lecture prudente des valeurs d'une sauvegarde : le fichier vient du disque du joueur.


## Entier lu depuis JSON (ou les nombres sont des float). Mauvais type ou absent : default.
static func int_of(data: Dictionary, key: String, default: int = 0) -> int:
	var value: Variant = data.get(key, default)
	if value is int or value is float:
		return int(value)
	return default


## Liste de textes ; tout element qui n'est pas un texte est ignore.
static func string_list(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item: Variant in value:
			if item is String:
				result.append(item)
	return result


## Ids texte d'une liste de contenus (artefacts, pilules, manuels), dans l'ordre.
static func ids(list: Array) -> Array[String]:
	var result: Array[String] = []
	for item: Resource in list:
		result.append(String(item.id))
	return result
