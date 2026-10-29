class_name FusePillEffect
extends PillEffect
## La carte de plus haut rang prend en plus le rang des autres (au plus le rang max du paquet) ; les autres quittent
## le paquet pour le reste de la run.


func apply(cards: Array[CardInstance], deck: DeckState, _run: RunState = null) -> void:
	var kept: CardInstance = cards[0]
	for card: CardInstance in cards:
		if card.rank > kept.rank:
			kept = card
	var others: Array[CardInstance] = cards.filter(func(card: CardInstance) -> bool: return card != kept)
	var rank := kept.rank
	for card: CardInstance in others:
		rank += card.rank
	kept.rank = mini(rank, kept.ranks.max_rank) if kept.ranks != null else rank
	deck.destroy(others)
