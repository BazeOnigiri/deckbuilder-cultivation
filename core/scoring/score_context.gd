class_name ScoreContext
extends RefCounted
## Score en cours de calcul. Les effets le modifient, total() donne le resultat.

var hand: HandResult
var qi: int = 0
var comprehension: float = 0.0


func _init(p_hand: HandResult) -> void:
	hand = p_hand


func total() -> int:
	return floori(qi * comprehension)