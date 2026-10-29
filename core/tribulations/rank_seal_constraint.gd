class_name RankSealConstraint
extends TribulationConstraint
## Les cartes de rang min_rank ou plus ne comptent pas (11 : les figures scellees).

@export var min_rank: int = 11


func counts(card: CardInstance) -> bool:
	return card.rank < min_rank
