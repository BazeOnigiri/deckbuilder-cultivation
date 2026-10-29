class_name ArtifactResolver
extends RefCounted
## Traduit les artefacts possedes en effets de score pour une main jouee, et regle les evenements hors score
## (defausse, goulot franchi) : pierres gagnees et crans des artefacts qui grandissent.
## Ordre : artefacts dans l'ordre d'acquisition, puis le pipeline trie par phase.
## stacks : crans de chaque artefact qui grandit, par id. Chaque cran ajoute growth_step a ses effets de score.

const HAND_TRIGGERS: Array[ArtifactEffect.Trigger] = [ArtifactEffect.Trigger.HAND_PLAYED,
	ArtifactEffect.Trigger.CARD_SCORED, ArtifactEffect.Trigger.CARD_HELD]


static func effects_for(artifacts: Array[ArtifactDefinition], result: HandResult, held: Array[CardInstance] = [],
		stacks: Dictionary = {}) -> Array[ScoreEffect]:
	var effects: Array[ScoreEffect] = []
	for triggered: TriggeredEffect in triggered_for(artifacts, result, held, stacks):
		effects.append(triggered.effect)
	return effects


## Les memes effets, avec l'artefact et la carte qui les ont declenches. held : cartes restees en main.
## editions : aura de chaque artefact, par id (RunState.artifact_editions) ; son effet suit ceux de l'artefact, une
## fois par main jouee.
static func triggered_for(artifacts: Array[ArtifactDefinition], result: HandResult, held: Array[CardInstance] = [],
		stacks: Dictionary = {}, editions: Dictionary = {}) -> Array[TriggeredEffect]:
	var triggered: Array[TriggeredEffect] = []
	for artifact: ArtifactDefinition in artifacts:
		for effect: ArtifactEffect in artifact.effects:
			if effect.score_effect == null or not HAND_TRIGGERS.has(effect.trigger):
				continue
			var score := _grown(artifact, effect.score_effect, stacks)
			# Un artefact qui n'a pas encore grandi (+0, x1) ne montre rien.
			if _is_neutral(score):
				continue
			for card: Variant in _hits(effect, result, held, []):
				triggered.append(TriggeredEffect.new(score, artifact, card))
		var edition: EditionDefinition = editions.get(artifact.id)
		if edition != null and edition.score_effect != null and result != null:
			triggered.append(TriggeredEffect.new(edition.score_effect, artifact))
	return triggered


## Apres une main jouee : les artefacts qui grandissent sur ce coup prennent leurs crans.
static func after_hand(artifacts: Array[ArtifactDefinition], stacks: Dictionary, result: HandResult,
		held: Array[CardInstance]) -> void:
	_settle(artifacts, stacks, HAND_TRIGGERS, result, held, [], {})


## Defausse : crans, et pierres gagnees (renvoyees).
static func after_discard(artifacts: Array[ArtifactDefinition], stacks: Dictionary, cards: Array[CardInstance]) -> int:
	return _settle(artifacts, stacks, [ArtifactEffect.Trigger.CARD_DISCARDED], null, [], cards, {})


## Goulot franchi : crans, et pierres gagnees (une fois, par main restante ou par defausse restante).
static func after_round_won(artifacts: Array[ArtifactDefinition], stacks: Dictionary, hands_left: int,
		discards_left: int) -> int:
	var counts := {ArtifactEffect.Per.HAND_LEFT: hands_left, ArtifactEffect.Per.DISCARD_LEFT: discards_left}
	return _settle(artifacts, stacks, [ArtifactEffect.Trigger.ROUND_WON], null, [], [], counts)


static func _settle(artifacts: Array[ArtifactDefinition], stacks: Dictionary, triggers: Array, result: HandResult,
		held: Array[CardInstance], discarded: Array[CardInstance], per_counts: Dictionary) -> int:
	var stones := 0
	for artifact: ArtifactDefinition in artifacts:
		for effect: ArtifactEffect in artifact.effects:
			if not triggers.has(effect.trigger):
				continue
			var hits := _hits(effect, result, held, discarded).size()
			if effect.grows and hits > 0:
				stacks[artifact.id] = stacks.get(artifact.id, 0) + hits
			stones += effect.stones * hits * per_counts.get(effect.per, 1)
	return stones


## Une entree par declenchement : la carte qui declenche, ou null pour un declenchement sans carte.
static func _hits(effect: ArtifactEffect, result: HandResult, held: Array[CardInstance], discarded: Array[CardInstance]) -> Array:
	match effect.trigger:
		ArtifactEffect.Trigger.HAND_PLAYED:
			return [null] if result != null and _matches(effect, result, null) else []
		ArtifactEffect.Trigger.CARD_SCORED:
			return [] if result == null else result.scoring_sequence().filter(func(card: CardInstance) -> bool:
				return _matches(effect, result, card))
		ArtifactEffect.Trigger.CARD_HELD:
			return [] if result == null else held.filter(func(card: CardInstance) -> bool:
				return _matches(effect, result, card))
		ArtifactEffect.Trigger.CARD_DISCARDED:
			return discarded.filter(func(card: CardInstance) -> bool: return _matches(effect, null, card))
		ArtifactEffect.Trigger.ROUND_WON:
			return [null]
	return []


## L'effet de score avec les crans de l'artefact : une copie, la ressource partagee ne change pas.
static func _grown(artifact: ArtifactDefinition, score: ScoreEffect, stacks: Dictionary) -> ScoreEffect:
	var count: int = stacks.get(artifact.id, 0)
	if artifact.growth_step == 0.0 or count == 0:
		return score
	var grown := score.duplicate() as ScoreEffect
	grown.amount += artifact.growth_step * count
	return grown


static func _is_neutral(score: ScoreEffect) -> bool:
	return is_equal_approx(score.amount, 1.0 if score.phase == ScoreEffect.Phase.MULT_COMPREHENSION else 0.0)


static func _matches(effect: ArtifactEffect, result: HandResult, card: CardInstance) -> bool:
	return effect.condition == null or effect.condition.matches(result, card)
