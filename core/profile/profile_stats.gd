class_name ProfileStats
extends RefCounted
## Statistiques du joueur, conservees d'une run a l'autre.

const VERSION := 1
const DEFAULT_PATH := "user://profil.json"

var runs_started: int = 0
var runs_won: int = 0
var best_realm: int = 0
var best_hand_score: int = 0
var hands := HandTally.new()
## L'aide a deja ete proposee a la premiere partie. Champ optionnel : un ancien profil l'a faux.
var help_offered: bool = false


## Premiere partie du profil, et l'aide pas encore proposee.
func should_offer_help() -> bool:
	return runs_started == 0 and not help_offered


func to_dict() -> Dictionary:
	return {
		"runs_started": runs_started,
		"runs_won": runs_won,
		"best_realm": best_realm,
		"best_hand_score": best_hand_score,
		"hand_counts": hands.to_dict(),
		"help_offered": help_offered,
	}


## Le fichier vient du disque du joueur : une valeur absente, de mauvais type ou negative devient 0.
static func from_dict(data: Dictionary) -> ProfileStats:
	var stats := ProfileStats.new()
	stats.runs_started = _count(data, "runs_started")
	stats.runs_won = _count(data, "runs_won")
	stats.best_realm = _count(data, "best_realm")
	stats.best_hand_score = _count(data, "best_hand_score")
	stats.hands = HandTally.from_dict(data.get("hand_counts", {}))
	var offered: Variant = data.get("help_offered", false)
	stats.help_offered = offered is bool and offered
	return stats


static func load_from(storage: SaveStorage) -> ProfileStats:
	var data := SaveMigrator.migrate(storage.load_data(), VERSION, _migrations())
	var stats: Variant = data.get("stats", {})
	return from_dict(stats if stats is Dictionary else {})


func save_to(storage: SaveStorage) -> bool:
	return storage.save({"version": VERSION, "stats": to_dict()})


## Exemple pour plus tard : {1: func(data: Dictionary) -> Dictionary: return data}
static func _migrations() -> Dictionary:
	return {}


static func _count(data: Dictionary, key: String) -> int:
	return maxi(0, SaveData.int_of(data, key))