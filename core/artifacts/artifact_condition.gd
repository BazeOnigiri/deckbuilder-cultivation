class_name ArtifactCondition
extends Resource
## Condition d'un effet d'artefact. card vaut null pour un declencheur HAND_PLAYED ; pour CARD_HELD, c'est la
## carte gardee en main.


## Vrai si la condition lit la main jouee : elle n'a alors pas de sens sans main (ROUND_WON, CARD_DISCARDED).
func needs_hand() -> bool:
	return false


func matches(_result: HandResult, _card: CardInstance) -> bool:
	return true