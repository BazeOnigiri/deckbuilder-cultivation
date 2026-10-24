class_name ProfileStats
extends RefCounted
## Statistiques du joueur, conservees d'une run a l'autre.

const VERSION := 1
const DEFAULT_PATH := "user://profil.json"

var runs_started: int = 0
var runs_won: int = 0
var best_realm: int = 0
var best_hand_score: int = 0
## id de main -> nombre de fois jouee.
var hand_counts: Dictionary = {}


func total_hands() -> int:
	var total: int = 0
	for count: int in hand_counts.values():
		total += count
	return total


## Main la plus jouee, "" si aucune. En cas d'egalite, le plus petit id : resultat stable.
func most_played_hand() -> String:
	var ids: Array = hand_counts.keys()
	ids.sort()
	var best_id: String = ""
	var best_count: int = 0
	for id: String in ids:
		if hand_counts[id] > best_count:
			best_id = id
			best_count = hand_counts[id]
	return best_id


func to_dict() -> Dictionary:
	return {
		"runs_started": runs_started,
		"runs_won": runs_won,
		"best_realm": best_realm,
		"best_hand_score": best_hand_score,
		"hand_counts": hand_counts.duplicate(),
	}


## Le fichier vient du disque du joueur : une valeur absente, de mauvais type ou negative devient 0.
static func from_dict(data: Dictionary) -> ProfileStats:
	var stats := ProfileStats.new()
	stats.runs_started = _count(data, "runs_started")
	stats.runs_won = _count(data, "runs_won")
	stats.best_realm = _count(data, "best_realm")
	stats.best_hand_score = _count(data, "best_hand_score")
	var counts: Variant = data.get("hand_counts", {})
	if counts is Dictionary:
		for key: Variant in counts:
			if key is String:
				var count: int = _count(counts, key)
				if count > 0:
					stats.hand_counts[key] = count
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
	var value: Variant = data.get(key, 0)
	if value is int or value is float:
		return maxi(0, int(value))
	return 0