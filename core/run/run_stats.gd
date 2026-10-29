class_name RunStats
extends RefCounted
## Statistiques de la run en cours, affichees dans la fenetre Infos. Neuves a chaque run.

var hands := HandTally.new()
var best_hand_score: int = 0
## Main du meilleur coup, "" si aucun coup joue.
var best_hand_id: String = ""
var discards_used: int = 0
var stones_earned: int = 0
var bottlenecks_cleared: int = 0
## Goulots passes sans les combattre (presages).
var bottlenecks_skipped: int = 0


func record_hand(hand_id: String, score: int) -> void:
	hands.record(hand_id)
	if score > best_hand_score:
		best_hand_score = score
		best_hand_id = hand_id


func to_dict() -> Dictionary:
	return {
		"hand_counts": hands.to_dict(),
		"best_hand_score": best_hand_score,
		"best_hand_id": best_hand_id,
		"discards_used": discards_used,
		"stones_earned": stones_earned,
		"bottlenecks_cleared": bottlenecks_cleared,
		"bottlenecks_skipped": bottlenecks_skipped,
	}


static func from_dict(data: Variant) -> RunStats:
	var stats := RunStats.new()
	if not data is Dictionary:
		return stats
	stats.hands = HandTally.from_dict(data.get("hand_counts", {}))
	stats.best_hand_score = maxi(0, SaveData.int_of(data, "best_hand_score"))
	var best_id: Variant = data.get("best_hand_id", "")
	stats.best_hand_id = best_id if best_id is String else ""
	stats.discards_used = maxi(0, SaveData.int_of(data, "discards_used"))
	stats.stones_earned = maxi(0, SaveData.int_of(data, "stones_earned"))
	stats.bottlenecks_cleared = maxi(0, SaveData.int_of(data, "bottlenecks_cleared"))
	stats.bottlenecks_skipped = maxi(0, SaveData.int_of(data, "bottlenecks_skipped"))
	return stats