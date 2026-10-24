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