class_name ScoringCountCondition
extends ArtifactCondition
## Vraie si la main a entre min_count et max_count cartes qui comptent (inclus) : recompense les mains courtes.

@export var min_count: int = 1
@export var max_count: int = 5


func matches(result: HandResult, _card: CardInstance) -> bool:
	return result.scoring_cards.size() >= min_count and result.scoring_cards.size() <= max_count
