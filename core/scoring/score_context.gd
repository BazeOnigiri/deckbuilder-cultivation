class_name ScoreContext
extends RefCounted
## Score en cours de calcul. Les effets le modifient, total() donne le resultat.

var hand: HandResult
var qi: int = 0
var comprehension: float = 0.0
## Chaque etape du calcul, dans l'ordre : l'affichage les rejoue une a une.
var steps: Array[ScoreStep] = []


func _init(p_hand: HandResult) -> void:
	hand = p_hand


func total() -> int:
	return floori(qi * comprehension)


## Note l'etat actuel comme une etape.
func record(kind: ScoreStep.Kind, card: CardInstance = null, effect: ScoreEffect = null, source: Resource = null) -> void:
	var step := ScoreStep.new()
	step.kind = kind
	step.qi = qi
	step.comprehension = comprehension
	step.card = card
	step.effect = effect
	step.source = source
	steps.append(step)
