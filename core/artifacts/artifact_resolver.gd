class_name ArtifactResolver
extends RefCounted
## Traduit les artefacts possedes en effets de score pour une main jouee.
## Ordre : artefacts dans l'ordre d'acquisition, puis le pipeline trie par phase.


static func effects_for(artifacts: Array[ArtifactDefinition], result: HandResult) -> Array[ScoreEffect]:
	var effects: Array[ScoreEffect] = []
	for artifact: ArtifactDefinition in artifacts:
		for effect: ArtifactEffect in artifact.effects:
			match effect.trigger:
				ArtifactEffect.Trigger.HAND_PLAYED:
					if _matches(effect, result, null):
						effects.append(effect.score_effect)
				ArtifactEffect.Trigger.CARD_SCORED:
					for card: CardInstance in result.scoring_cards:
						if _matches(effect, result, card):
							effects.append(effect.score_effect)
	return effects


static func _matches(effect: ArtifactEffect, result: HandResult, card: CardInstance) -> bool:
	return effect.condition == null or effect.condition.matches(result, card)