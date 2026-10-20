class_name CardData
extends Resource
## Définition d'une carte : donnée statique, en lecture seule pendant une partie.
## L'état en jeu (bonus, modifications) vivra dans une classe séparée qui référence ce CardData,
## car une Resource chargée est partagée par tous ceux qui la chargent.

@export var id: StringName = &""
@export var element: Element.Type = Element.Type.BOIS
@export var rank: int = 0


## Fabrique pratique pour les tests et les outils de génération.
static func create(card_id: StringName, card_element: Element.Type, card_rank: int) -> CardData:
	var card: CardData = CardData.new()
	card.id = card_id
	card.element = card_element
	card.rank = card_rank
	return card