class_name HandIsCondition
extends ArtifactCondition
## Vraie si la main jouee est l'une de hand_ids.

@export var hand_ids: Array[String] = []


func needs_hand() -> bool:
	return true


func matches(result: HandResult, _card: CardInstance) -> bool:
	return result != null and hand_ids.has(result.definition.id)