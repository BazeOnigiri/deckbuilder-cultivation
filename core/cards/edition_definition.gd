class_name EditionDefinition
extends CardModifier
## Aura (lueur) d'une carte ou d'un artefact, cumulable avec une amelioration. Sur une carte, son effet joue quand
## la carte compte ; sur un artefact, une fois par main jouee.

@export var score_effect: ScoreEffect
## Faux : l'artefact qui la porte ne prend pas d'emplacement.
@export var takes_slot: bool = true
@export var for_cards: bool = true
@export var for_artifacts: bool = true
## Poids de tirage parmi les auras possibles (boutique, sceau de disciples).
@export var weight: float = 1.0
## Pierres ajoutees au prix d'un artefact en boutique qui la porte.
@export var price_bonus: int = 0


func is_valid() -> bool:
	# Une aura sans emplacement n'a de sens que sur un artefact.
	return (super() and weight > 0.0 and price_bonus >= 0 and (for_cards or for_artifacts)
		and (score_effect != null or not takes_slot) and (takes_slot or not for_cards))
