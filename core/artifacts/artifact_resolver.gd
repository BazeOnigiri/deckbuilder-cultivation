class_name ArtifactResolver
extends RefCounted
## Traduit les artefacts possedes en effets de score pour une main jouee.
## Ordre : artefacts dans l'ordre d'acquisition, puis le pipeline trie par phase.


static func effects_for(artifacts: Array[ArtifactDefinition], result: HandResult) -> Array[ScoreEffect]:
	var effects: Array[ScoreEffect] = []
	for triggered: TriggeredEffect in triggered_for(artifacts, result):
		effects.append(triggered.effect)
	return effects


## Les memes effets, avec l'artefact et la carte qui les ont declenches.
static func triggered_for(artifacts: Array[ArtifactDefinition], result: HandResult) -> Array[TriggeredEffect]:
	var triggered: Array[TriggeredEffect] = []
	for artifact: ArtifactDefinition in artifacts:
		for effect: ArtifactEffect in artifact.effects:
			match effect.trigger:
				ArtifactEffect.Trigger.HAND_PLAYED:
					if _matches(effect, result, null):
						triggered.append(TriggeredEffect.new(effect.score_effect, artifact))
				ArtifactEffect.Trigger.CARD_SCORED:
					for card: CardInstance in result.scoring_cards:
						if _matches(effect, result, card):
							triggered.append(TriggeredEffect.new(effect.score_effect, artifact, card))
	return triggered


static func _matches(effect: ArtifactEffect, result: HandResult, card: CardInstance) -> bool:
	return effect.condition == null or effect.condition.matches(result, card)
