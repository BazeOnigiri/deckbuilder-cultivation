class_name GameSettings
extends RefCounted
## Reglages du joueur, conserves d'une partie a l'autre.

const VERSION := 1
const DEFAULT_PATH := "user://reglages.json"

## Coupe le mouvement continu (fond, cartes qui flottent) pour les joueurs que ca gene.
var reduce_motion: bool = false


func to_dict() -> Dictionary:
	return {"reduce_motion": reduce_motion}


## Le fichier vient du disque du joueur : une valeur absente ou de mauvais type garde sa valeur par defaut.
static func from_dict(data: Dictionary) -> GameSettings:
	var settings := GameSettings.new()
	var reduce: Variant = data.get("reduce_motion", false)
	settings.reduce_motion = reduce if reduce is bool else false
	return settings


static func load_from(storage: SaveStorage) -> GameSettings:
	var data := SaveMigrator.migrate(storage.load_data(), VERSION, _migrations())
	var settings: Variant = data.get("settings", {})
	return from_dict(settings if settings is Dictionary else {})


func save_to(storage: SaveStorage) -> bool:
	return storage.save({"version": VERSION, "settings": to_dict()})


## Exemple pour plus tard : {1: func(data: Dictionary) -> Dictionary: return data}
static func _migrations() -> Dictionary:
	return {}
