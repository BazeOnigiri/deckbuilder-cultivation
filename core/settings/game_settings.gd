class_name GameSettings
extends RefCounted
## Reglages du joueur, conserves d'une partie a l'autre.

const VERSION := 1
const DEFAULT_PATH := "user://reglages.json"
## Vitesses proposees (multiplient tout le temps du jeu : sequences, tweens, minuteurs).
const GAME_SPEEDS: Array[float] = [1.0, 1.5, 2.0, 3.0]

## Coupe le mouvement continu (fond, cartes qui flottent) pour les joueurs que ca gene.
var reduce_motion: bool = false
var game_speed: float = 1.0
var fullscreen: bool = false


func to_dict() -> Dictionary:
	return {"reduce_motion": reduce_motion, "game_speed": game_speed, "fullscreen": fullscreen}


## Le fichier vient du disque du joueur : une valeur absente ou de mauvais type garde sa valeur par defaut.
static func from_dict(data: Dictionary) -> GameSettings:
	var settings := GameSettings.new()
	var reduce: Variant = data.get("reduce_motion", false)
	settings.reduce_motion = reduce if reduce is bool else false
	var speed: Variant = data.get("game_speed", 1.0)
	# JSON relit les nombres en float : une vitesse hors de la liste revient a 1.
	settings.game_speed = speed if (speed is float or speed is int) and GAME_SPEEDS.has(float(speed)) else 1.0
	var full: Variant = data.get("fullscreen", false)
	settings.fullscreen = full if full is bool else false
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
