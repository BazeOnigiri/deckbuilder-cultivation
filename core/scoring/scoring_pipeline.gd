class_name ScoringPipeline
extends RefCounted
## Score d'une main jouee. Ordre fixe : base de la main (selon son niveau), cartes qui comptent,
## puis effets phase par phase.


static func score(hand: HandResult, effects: Array[ScoreEffect], level: int = 1) -> ScoreContext:
	assert(hand != null, "score() demande une main reconnue")
	var definition := hand.definition
	var context := ScoreContext.new(hand)
	context.qi = definition.qi_at(level)
	context.comprehension = definition.comprehension_at(level)
	for card: CardInstance in hand.scoring_cards:
		context.qi += card.rank
	# Boucle par phase plutot que sort_custom : sort_custom n'est pas stable et perdrait l'ordre d'ajout.
	for phase: int in ScoreEffect.Phase.values():
		for effect: ScoreEffect in effects:
			if effect.phase == phase:
				effect.apply(context)
	return context