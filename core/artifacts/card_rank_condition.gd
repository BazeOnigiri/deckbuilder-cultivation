class_name CardRankCondition
extends ArtifactCondition
## Vraie pour une carte dont le rang est entre min_rank et max_rank (inclus). Toujours fausse sans carte.

@export var min_rank: int = 1
@export var max_rank: int = 9


func matches(_result: HandResult, card: CardInstance) -> bool:
	return card != null and card.rank >= min_rank and card.rank <= max_rank
