class_name DestroyPillEffect
extends PillEffect
## Retire definitivement les cartes du paquet pour le reste de la run, de la main comme des autres piles (rencontre).


func apply(cards: Array[CardInstance], deck: DeckState, _run: RunState = null) -> void:
	deck.remove(cards)
