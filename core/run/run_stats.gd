class_name RunStats
extends RefCounted
## Statistiques de la run en cours, affichees dans la fenetre Infos. Neuves a chaque run.

var hands := HandTally.new()
var best_hand_score: int = 0
var discards_used: int = 0
var stones_earned: int = 0
var bottlenecks_cleared: int = 0


func record_hand(hand_id: String, score: int) -> void:
	hands.record(hand_id)
	best_hand_score = maxi(best_hand_score, score)


func to_dict() -> Dictionary:
	return {
		"hand_counts": hands.to_dict(),
		"best_hand_score": best_hand_score,
		"discards_used": discards_used,
		"stones_earned": stones_earned,
		"bottlenecks_cleared": bottlenecks_cleared,
	}


static func from_dict(data: Variant) -> RunStats:
	var stats := RunStats.new()
	if not data is Dictionary:
		return stats
	stats.hands = HandTally.from_dict(data.get("hand_counts", {}))
	stats.best_hand_score = maxi(0, SaveData.int_of(data, "best_hand_score"))
	stats.discards_used = maxi(0, SaveData.int_of(data, "discards_used"))
	stats.stones_earned = maxi(0, SaveData.int_of(data, "stones_earned"))
	stats.bottlenecks_cleared = maxi(0, SaveData.int_of(data, "bottlenecks_cleared"))
	return stats