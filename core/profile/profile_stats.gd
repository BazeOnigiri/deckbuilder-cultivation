class_name ProfileStats
extends RefCounted
## Statistiques du joueur, conservees d'une run a l'autre.
## Version 2 : contenu vu (compendium), historique des parties, achats et tribulations.
## Version 3 : contenus debloques et succes obtenus. Champs optionnels.

const VERSION := 3
const DEFAULT_PATH := "user://profil.json"

var runs_started: int = 0
var runs_won: int = 0
var best_realm: int = 0
var best_hand_score: int = 0
var hands := HandTally.new()
## Categorie (Compendium.KEYS) -> {id: true} : les contenus deja offerts en boutique ou possedes.
var seen: Dictionary = {}
## id d'artefact -> nombre d'achats en boutique.
var artifact_purchases: Dictionary = {}
## id de tribulation -> {"won": n, "lost": n}.
var tribulations: Dictionary = {}
## Les dernieres parties terminees, la plus ancienne en premier.
var games: Array[GameRecord] = []
## id de contenu -> true : les contenus verrouilles au depart (UnlockRule) que le joueur a debloques.
var unlocked: Dictionary = {}
## id de succes -> true : les succes obtenus.
var achievements: Dictionary = {}
## L'aide a deja ete proposee a la premiere partie. Champ optionnel : un ancien profil l'a faux.
var help_offered: bool = false


## Premiere partie du profil, et l'aide pas encore proposee.
func should_offer_help() -> bool:
	return runs_started == 0 and not help_offered
## Plus haut niveau de difficulte ouvert : gagner au niveau N ouvre N + 1.
var difficulty_unlocked: int = 1
## Plus loin atteint en mode sans fin : numero du royaume genere (Royaume celeste N).
var best_endless_realm: int = 0
## Ids des defis gagnes au moins une fois.
var challenges_won: Array[String] = []


func to_dict() -> Dictionary:
	var seen_ids: Dictionary = {}
	for kind: String in seen:
		var ids: Array = seen[kind].keys()
		ids.sort()
		seen_ids[kind] = ids
	return {
		"runs_started": runs_started,
		"runs_won": runs_won,
		"best_realm": best_realm,
		"best_hand_score": best_hand_score,
		"hand_counts": hands.to_dict(),
		"help_offered": help_offered,
		"seen": seen_ids,
		"artifact_purchases": artifact_purchases.duplicate(),
		"tribulations": tribulations.duplicate(true),
		"unlocked": _sorted_ids(unlocked),
		"achievements": _sorted_ids(achievements),
		"games": games.map(func(game: GameRecord) -> Dictionary: return game.to_dict()),
		"difficulty_unlocked": difficulty_unlocked,
		"best_endless_realm": best_endless_realm,
		"challenges_won": challenges_won.duplicate(),
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
	var saved_seen: Variant = data.get("seen", {})
	if saved_seen is Dictionary:
		for kind: Variant in saved_seen:
			if kind is String:
				for id: String in SaveData.string_list(saved_seen[kind]):
					stats.mark_seen(kind, StringName(id))
	var purchases: Variant = data.get("artifact_purchases", {})
	if purchases is Dictionary:
		for id: Variant in purchases:
			if id is String and _count(purchases, id) > 0:
				stats.artifact_purchases[id] = _count(purchases, id)
	var results: Variant = data.get("tribulations", {})
	if results is Dictionary:
		for id: Variant in results:
			if id is String and results[id] is Dictionary:
				var won := _count(results[id], "won")
				var lost := _count(results[id], "lost")
				if won + lost > 0:
					stats.tribulations[id] = {"won": won, "lost": lost}
	for id: String in SaveData.string_list(data.get("unlocked")):
		stats.unlock(StringName(id))
	for id: String in SaveData.string_list(data.get("achievements")):
		stats.achieve(StringName(id))
	var saved_games: Variant = data.get("games", [])
	if saved_games is Array:
		for game: Variant in saved_games:
			if game is Dictionary:
				stats.games.append(GameRecord.from_dict(game))
	stats.difficulty_unlocked = maxi(1, _count(data, "difficulty_unlocked"))
	stats.best_endless_realm = _count(data, "best_endless_realm")
	stats.challenges_won = SaveData.string_list(data.get("challenges_won"))
	return stats


## Victoire hors mode sans fin : ouvre la difficulte suivante, note le defi gagne.
func record_win(setup: RunSetup) -> void:
	runs_won += 1
	if setup.challenge != null:
		if not challenges_won.has(String(setup.challenge.id)):
			challenges_won.append(String(setup.challenge.id))
	else:
		difficulty_unlocked = maxi(difficulty_unlocked, setup.difficulty + 1)


static func load_from(storage: SaveStorage) -> ProfileStats:
	var data := SaveMigrator.migrate(storage.load_data(), VERSION, _migrations())
	var stats: Variant = data.get("stats", {})
	return from_dict(stats if stats is Dictionary else {})


func save_to(storage: SaveStorage) -> bool:
	return storage.save({"version": VERSION, "stats": to_dict()})


## Vrai si ce contenu n'avait jamais ete vu.
func mark_seen(kind: String, id: StringName) -> bool:
	var ids: Dictionary = seen.get_or_add(kind, {})
	if ids.has(String(id)):
		return false
	ids[String(id)] = true
	return true


func is_seen(kind: String, id: StringName) -> bool:
	return seen.get(kind, {}).has(String(id))


func record_purchase(artifact_id: StringName) -> void:
	artifact_purchases[String(artifact_id)] = purchases_of(artifact_id) + 1


func purchases_of(artifact_id: StringName) -> int:
	return artifact_purchases.get(String(artifact_id), 0)


## Les artefacts les plus achetes, le plus achete d'abord ; a egalite, l'id le plus petit (resultat stable).
func top_purchases(count: int) -> Array[String]:
	var ids: Array[String] = []
	ids.assign(artifact_purchases.keys())
	ids.sort_custom(func(a: String, b: String) -> bool:
		if artifact_purchases[a] != artifact_purchases[b]:
			return artifact_purchases[a] > artifact_purchases[b]
		return a < b)
	return ids.slice(0, count)


func total_purchases() -> int:
	var sum := 0
	for count: int in artifact_purchases.values():
		sum += count
	return sum


func total_tribulation_wins() -> int:
	var sum := 0
	for id: String in tribulations:
		sum += tribulations[id]["won"]
	return sum


## Vrai si ce contenu vient d'etre debloque (jamais deux fois).
func unlock(id: StringName) -> bool:
	if unlocked.has(String(id)):
		return false
	unlocked[String(id)] = true
	return true


func has_unlocked(id: StringName) -> bool:
	return unlocked.has(String(id))


## Vrai si ce succes vient d'etre obtenu (jamais deux fois).
func achieve(id: StringName) -> bool:
	if achievements.has(String(id)):
		return false
	achievements[String(id)] = true
	return true


func has_achievement(id: StringName) -> bool:
	return achievements.has(String(id))


func record_tribulation(id: StringName, won: bool) -> void:
	var result: Dictionary = tribulations.get_or_add(String(id), {"won": 0, "lost": 0})
	result["won" if won else "lost"] += 1


func tribulation_wins(id: StringName) -> int:
	return tribulations.get(String(id), {}).get("won", 0)


func tribulation_losses(id: StringName) -> int:
	return tribulations.get(String(id), {}).get("lost", 0)


## Ajoute une partie terminee ; au-dela de limit parties, les plus anciennes sortent.
func add_game(game: GameRecord, limit: int) -> void:
	games.append(game)
	while games.size() > maxi(1, limit):
		games.remove_at(0)


## Les champs des versions 2 et 3 sont optionnels : une sauvegarde plus ancienne reste valide telle quelle.
static func _migrations() -> Dictionary:
	var keep := func(data: Dictionary) -> Dictionary: return data
	return {1: keep, 2: keep}


static func _sorted_ids(ids: Dictionary) -> Array:
	var list: Array = ids.keys()
	list.sort()
	return list


static func _count(data: Dictionary, key: String) -> int:
	return maxi(0, SaveData.int_of(data, key))
