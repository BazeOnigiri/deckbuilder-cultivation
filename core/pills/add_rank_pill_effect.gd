class_name AddRankPillEffect
extends PillEffect
## Augmente le rang des cartes, sans depasser max_rank.

@export var amount: int = 1
@export var max_rank: int = 9


func apply(cards: Array[CardInstance], _deck: DeckState) -> void:
	for card: CardInstance in cards:
		card.rank = mini(card.rank + amount, max_rank)