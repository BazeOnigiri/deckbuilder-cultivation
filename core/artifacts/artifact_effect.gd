class_name ArtifactEffect
extends Resource
## Declencheur + condition (optionnelle) + ce que fait l'effet : un effet de score, des pierres, ou faire grandir
## l'artefact (grows). Un artefact simple n'est que des donnees.

## CARD_HELD : une fois par carte restee en main (pas jouee) quand une main est jouee.
## ROUND_WON : une fois quand le goulot est franchi. CARD_DISCARDED : une fois par carte defaussee.
enum Trigger {HAND_PLAYED, CARD_SCORED, CARD_HELD, ROUND_WON, CARD_DISCARDED}
## ROUND_WON seulement : stones est donne une fois, ou par main restante, ou par defausse restante.
enum Per {ONCE, HAND_LEFT, DISCARD_LEFT}

@export var trigger: Trigger = Trigger.HAND_PLAYED
## Vide = toujours vrai. Pour ROUND_WON il n'y a ni main ni carte : laisser vide.
@export var condition: ArtifactCondition
## Effet de score, pour les declencheurs d'une main jouee (HAND_PLAYED, CARD_SCORED, CARD_HELD).
@export var score_effect: ScoreEffect
## Pierres gagnees a chaque declenchement.
@export var stones: int = 0
@export var per: Per = Per.ONCE
## Vrai : chaque declenchement donne un cran a l'artefact (ArtifactDefinition.growth_step), garde toute la run.
@export var grows: bool = false


func is_valid() -> bool:
	var scores := trigger in [Trigger.HAND_PLAYED, Trigger.CARD_SCORED, Trigger.CARD_HELD]
	# Les pierres ne se donnent qu'a la fin du round ou a la defausse ; ces deux declencheurs n'ont pas de main jouee.
	var no_hand := trigger in [Trigger.ROUND_WON, Trigger.CARD_DISCARDED]
	if stones > 0 and not no_hand:
		return false
	if condition != null and (trigger == Trigger.ROUND_WON or (no_hand and condition.needs_hand())):
		return false
	return (score_effect != null and scores) or stones > 0 or grows
