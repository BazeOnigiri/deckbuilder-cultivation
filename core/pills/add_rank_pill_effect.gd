class_name AddRankPillEffect
extends PillEffect
## Change le rang des cartes de amount (negatif : baisse), entre 1 et le rang le plus haut de leur paquet (RankRules).

@export var amount: int = 1


func apply(cards: Array[CardInstance], _deck: DeckState, _run: RunState = null) -> void:
	for card: CardInstance in cards:
		# Une carte sans rangs de paquet (tests, outils) n'a pas de plafond.
		var cap: int = card.ranks.max_rank if card.ranks != null else card.rank + amount
		card.rank = clampi(card.rank + amount, 1, cap)
