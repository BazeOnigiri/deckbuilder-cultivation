class_name ArtifactEffect
extends Resource
## Declencheur + condition (optionnelle) + effet de score. Un artefact simple n'est que des donnees.

enum Trigger {HAND_PLAYED, CARD_SCORED}

@export var trigger: Trigger = Trigger.HAND_PLAYED
## Vide = toujours vrai.
@export var condition: ArtifactCondition
@export var score_effect: ScoreEffect


func is_valid() -> bool:
	return score_effect != null