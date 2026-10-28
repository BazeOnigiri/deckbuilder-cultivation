class_name AddRankPillEffect
extends PillEffect
## Augmente le rang des cartes, sans depasser le rang le plus haut de leur paquet (RankRules).

@export var amount: int = 1


func apply(cards: Array[CardInstance], _deck: DeckState) -> void:
	for card: CardInstance in cards:
		# Une carte sans rangs de paquet (tests, outils) n'a pas de plafond.
		var cap: int = card.ranks.max_rank if card.ranks != null else card.rank + amount
		card.rank = mini(card.rank + amount, cap)
