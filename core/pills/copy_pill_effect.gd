class_name CopyPillEffect
extends PillEffect
## Ajoute au paquet une copie de chaque carte (meme element, meme rang, memes ameliorations), dans la pioche.


func apply(cards: Array[CardInstance], _deck: DeckState, run: RunState = null) -> void:
	for card: CardInstance in cards:
		var copy := run.add_card(card.data, card.ranks)
		copy.element = card.element
		copy.rank = card.rank
		copy.copy_modifiers_from(card)
