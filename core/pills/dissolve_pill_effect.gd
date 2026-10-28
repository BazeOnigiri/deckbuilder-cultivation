class_name DissolvePillEffect
extends PillEffect
## Les cartes quittent le paquet pour le reste de la run et rapportent stones_per_card pierres chacune.

@export var stones_per_card: int = 3


func apply(cards: Array[CardInstance], deck: DeckState, run: RunState = null) -> void:
	deck.destroy(cards)
	run.stones += stones_per_card * cards.size()
