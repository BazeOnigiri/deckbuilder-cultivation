class_name SetElementPillEffect
extends PillEffect
## Change l'element des cartes.

@export var element: Element.Type = Element.Type.BOIS


func apply(cards: Array[CardInstance], _deck: DeckState, _run: RunState = null) -> void:
	for card: CardInstance in cards:
		card.element = element