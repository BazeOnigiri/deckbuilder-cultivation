class_name ScoringPipeline
extends RefCounted
## Score d'une main jouee. Ordre fixe : base de la main (selon son niveau), cartes qui comptent,
## puis effets phase par phase. Chaque etape est notee dans context.steps.


static func score(hand: HandResult, effects: Array[ScoreEffect], level: int = 1) -> ScoreContext:
	var triggered: Array[TriggeredEffect] = []
	for effect: ScoreEffect in effects:
		triggered.append(TriggeredEffect.new(effect))
	return score_triggered(hand, triggered, level)


## Comme score(), en gardant d'ou vient chaque effet dans les etapes.
static func score_triggered(hand: HandResult, effects: Array[TriggeredEffect], level: int = 1) -> ScoreContext:
	assert(hand != null, "score() demande une main reconnue")
	var definition := hand.definition
	var context := ScoreContext.new(hand)
	context.qi = definition.qi_at(level)
	context.comprehension = definition.comprehension_at(level)
	context.record(ScoreStep.Kind.BASE)
	for card: CardInstance in hand.scoring_cards:
		context.qi += card.rank
		context.record(ScoreStep.Kind.CARD, card)
	# Boucle par phase plutot que sort_custom : sort_custom n'est pas stable et perdrait l'ordre d'ajout.
	for phase: int in ScoreEffect.Phase.values():
		for triggered: TriggeredEffect in effects:
			if triggered.effect.phase == phase:
				triggered.effect.apply(context)
				context.record(ScoreStep.Kind.EFFECT, triggered.card, triggered.effect, triggered.source)
	return context
