class_name ArtifactEffect
extends Resource
## Declencheur + condition (optionnelle) + effet de score. Un artefact simple n'est que des donnees.

## CARD_HELD : une fois par carte restee en main (pas jouee) quand une main est jouee.
enum Trigger {HAND_PLAYED, CARD_SCORED, CARD_HELD}

@export var trigger: Trigger = Trigger.HAND_PLAYED
## Vide = toujours vrai.
@export var condition: ArtifactCondition
@export var score_effect: ScoreEffect


func is_valid() -> bool:
	return score_effect != null