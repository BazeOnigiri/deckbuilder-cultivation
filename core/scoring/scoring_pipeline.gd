class_name ScoringPipeline
extends RefCounted
## Score d'une main jouee. Ordre fixe : base de la main, cartes qui comptent, puis effets phase par phase.


static func score(hand: HandResult, effects: Array[ScoreEffect]) -> ScoreContext:
	assert(hand != null, "score() demande une main reconnue")
	var context := ScoreContext.new(hand)
	context.qi = hand.definition.base_qi
	context.comprehension = hand.definition.base_comprehension
	for card: CardInstance in hand.scoring_cards:
		context.qi += card.data.rank
	# Boucle par phase plutot que sort_custom : sort_custom n'est pas stable et perdrait l'ordre d'ajout.
	for phase: int in ScoreEffect.Phase.values():
		for effect: ScoreEffect in effects:
			if effect.phase == phase:
				effect.apply(context)
	return context