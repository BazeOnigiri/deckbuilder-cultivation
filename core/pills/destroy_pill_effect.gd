class_name DestroyPillEffect
extends PillEffect
## Retire definitivement les cartes du paquet pour le reste de la run.


func apply(cards: Array[CardInstance], deck: DeckState) -> void:
	deck.destroy(cards)