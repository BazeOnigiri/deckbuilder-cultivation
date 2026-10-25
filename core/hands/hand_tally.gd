class_name HandTally
extends RefCounted
## Nombre de fois ou chaque main a ete jouee. Partage par le profil et les statistiques de run.

## id de main -> nombre de fois jouee.
var counts: Dictionary = {}


func record(hand_id: String) -> void:
	counts[hand_id] = count_of(hand_id) + 1


func count_of(hand_id: String) -> int:
	return counts.get(hand_id, 0)


func total() -> int:
	var sum: int = 0
	for count: int in counts.values():
		sum += count
	return sum


## Main la plus jouee, "" si aucune. En cas d'egalite, le plus petit id : resultat stable.
func most_played() -> String:
	var ids: Array = counts.keys()
	ids.sort()
	var best_id: String = ""
	var best_count: int = 0
	for id: String in ids:
		if counts[id] > best_count:
			best_id = id
			best_count = counts[id]
	return best_id


func to_dict() -> Dictionary:
	return counts.duplicate()


## Donnees venant du disque du joueur : on ne garde que les paires id texte -> nombre positif.
static func from_dict(data: Variant) -> HandTally:
	var tally := HandTally.new()
	if not data is Dictionary:
		return tally
	for key: Variant in data:
		var value: Variant = data[key]
		if key is String and (value is int or value is float) and int(value) > 0:
			tally.counts[key] = int(value)
	return tally