class_name ArtifactCondition
extends Resource
## Condition d'un effet d'artefact. card vaut null pour un declencheur HAND_PLAYED.


func matches(_result: HandResult, _card: CardInstance) -> bool:
	return true