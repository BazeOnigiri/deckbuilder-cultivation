class_name HandResult
extends RefCounted
## Resultat d'une evaluation : la main reconnue et les cartes qui comptent.

var definition: HandDefinition
var scoring_cards: Array[CardInstance]


func _init(p_definition: HandDefinition, p_scoring_cards: Array[CardInstance]) -> void:
	definition = p_definition
	scoring_cards = p_scoring_cards