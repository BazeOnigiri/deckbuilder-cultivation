class_name GameSettings
extends RefCounted
## Reglages du joueur, conserves d'une partie a l'autre.

const VERSION := 1
const DEFAULT_PATH := "user://reglages.json"
## Vitesses proposees (multiplient tout le temps du jeu : sequences, tweens, minuteurs).
const GAME_SPEEDS: Array[float] = [1.0, 1.5, 2.0, 3.0]
## Langues du jeu (codes de TranslationServer) et langue de repli quand celle du systeme n'en fait pas partie.
const LANGUAGES: Array[String] = ["fr", "en"]
const FALLBACK_LANGUAGE := "en"
## Delai laisse au navigateur pour accorder le plein ecran avant de decocher la case.
const FULLSCREEN_CONFIRM_SECONDS := 0.5

## Le plein ecran a ete refuse ou quitte (Echap) : la case des options se decoche.
signal fullscreen_lost

## Coupe le mouvement continu (fond, cartes qui flottent) pour les joueurs que ca gene.
var reduce_motion: bool = false
var game_speed: float = 1.0
var fullscreen: bool = false
var language: String = default_language()
## Couleurs de Qi, de Comprehension, de tribulation et textes secondaires renforces (ui/theme/contraste.tres).
var high_contrast: bool = false
## Volumes de 0 (muet) a 1, un par bus audio. Nouveaux champs : un ancien fichier garde ces valeurs par defaut.
var master_volume: float = 0.8
var music_volume: float = 0.6
var effects_volume: float = 0.8
## Touches choisies dans les options (KeyBindings) : {action : touche physique}. Vide : celles de project.godot.
var key_bindings: Dictionary = {}


func to_dict() -> Dictionary:
	return {"reduce_motion": reduce_motion, "game_speed": game_speed, "fullscreen": fullscreen,
		"language": language, "high_contrast": high_contrast,
		"master_volume": master_volume, "music_volume": music_volume, "effects_volume": effects_volume,
		"key_bindings": key_bindings}


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
	var lang: Variant = data.get("language", "")
	settings.language = lang if lang is String and LANGUAGES.has(lang) else default_language()
	var contrast: Variant = data.get("high_contrast", false)
	settings.high_contrast = contrast if contrast is bool else false
	settings.master_volume = _volume(data, "master_volume", settings.master_volume)
	settings.music_volume = _volume(data, "music_volume", settings.music_volume)
	settings.effects_volume = _volume(data, "effects_volume", settings.effects_volume)
	settings.key_bindings = KeyBindings.sanitized(data.get("key_bindings", {}))
	return settings


## Langue du systeme si le jeu la propose, sinon l'anglais.
static func default_language() -> String:
	var system := OS.get_locale_language()
	return system if LANGUAGES.has(system) else FALLBACK_LANGUAGE


## Aligne la case sur l'etat reel de la fenetre (le navigateur peut refuser le plein ecran, Echap le quitte).
## Renvoie vrai si le reglage a change : a sauvegarder.
func sync_fullscreen(actual: bool) -> bool:
	if fullscreen == actual:
		return false
	fullscreen = actual
	if not actual:
		fullscreen_lost.emit()
	return true


static func _volume(data: Dictionary, key: String, fallback: float) -> float:
	var value: Variant = data.get(key, fallback)
	return clampf(float(value), 0.0, 1.0) if value is float or value is int else fallback


static func load_from(storage: SaveStorage) -> GameSettings:
	var data := SaveMigrator.migrate(storage.load_data(), VERSION, _migrations())
	var settings: Variant = data.get("settings", {})
	return from_dict(settings if settings is Dictionary else {})


func save_to(storage: SaveStorage) -> bool:
	return storage.save({"version": VERSION, "settings": to_dict()})


## Exemple pour plus tard : {1: func(data: Dictionary) -> Dictionary: return data}
static func _migrations() -> Dictionary:
	return {}
