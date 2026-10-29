class_name HandResult
extends RefCounted
## Resultat d'une evaluation : la main reconnue et les cartes qui comptent.

var definition: HandDefinition
var scoring_cards: Array[CardInstance]


func _init(p_definition: HandDefinition, p_scoring_cards: Array[CardInstance]) -> void:
	definition = p_definition
	scoring_cards = p_scoring_cards


## Les cartes qui comptent dans l'ordre, chacune repetee autant de fois qu'elle compte (talisman de recompte).
func scoring_sequence() -> Array[CardInstance]:
	var sequence: Array[CardInstance] = []
	for card: CardInstance in scoring_cards:
		for i: int in card.triggers():
			sequence.append(card)
	return sequence