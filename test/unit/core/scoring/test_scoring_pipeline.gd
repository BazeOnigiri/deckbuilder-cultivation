extends GutTest

const C := preload("res://test/helpers/cards.gd")


func _hand(base_qi: int, base_comprehension: int, specs: Array) -> HandResult:
	var definition := HandDefinition.new()
	definition.id = "test"
	definition.base_qi = base_qi
	definition.base_comprehension = base_comprehension
	return HandResult.new(definition, C.hand(specs))


func _effect(phase: ScoreEffect.Phase, amount: float) -> ScoreEffect:
	var effect := ScoreEffect.new()
	effect.phase = phase
	effect.amount = amount
	return effect


func _no_effects() -> Array[ScoreEffect]:
	var effects: Array[ScoreEffect] = []
	return effects


func test_base_plus_rangs_des_cartes() -> void:
	var context := ScoringPipeline.score(_hand(10, 2, [[C.BOIS, 4], [C.FEU, 4]]), _no_effects())
	assert_eq(context.qi, 18)
	assert_eq(context.comprehension, 2.0)
	assert_eq(context.total(), 36)


func test_effets_appliques_par_phase_quel_que_soit_l_ordre() -> void:
	var effects: Array[ScoreEffect] = [
		_effect(ScoreEffect.Phase.MULT_COMPREHENSION, 2.0),
		_effect(ScoreEffect.Phase.ADD_COMPREHENSION, 3.0),
		_effect(ScoreEffect.Phase.ADD_QI, 10.0),
	]
	var context := ScoringPipeline.score(_hand(10, 2, [[C.BOIS, 4], [C.FEU, 4]]), effects)
	assert_eq(context.qi, 28)
	assert_eq(context.comprehension, 10.0)
	assert_eq(context.total(), 280)


func test_multiplications_se_composent() -> void:
	var effects: Array[ScoreEffect] = [
		_effect(ScoreEffect.Phase.MULT_COMPREHENSION, 2.0),
		_effect(ScoreEffect.Phase.MULT_COMPREHENSION, 3.0),
	]
	var context := ScoringPipeline.score(_hand(5, 1, [[C.FEU, 5]]), effects)
	assert_eq(context.comprehension, 6.0)
	assert_eq(context.total(), 60)


func test_total_arrondi_vers_le_bas() -> void:
	var effects: Array[ScoreEffect] = [_effect(ScoreEffect.Phase.MULT_COMPREHENSION, 1.5)]
	var context := ScoringPipeline.score(_hand(5, 1, [[C.FEU, 10]]), effects)
	assert_eq(context.total(), 22)


func test_effets_ne_modifient_pas_la_definition() -> void:
	var hand := _hand(10, 2, [[C.BOIS, 4]])
	var effects: Array[ScoreEffect] = [_effect(ScoreEffect.Phase.MULT_COMPREHENSION, 3.0)]
	ScoringPipeline.score(hand, effects)
	assert_eq(hand.definition.base_comprehension, 2)

func test_niveau_ajoute_les_gains_par_niveau() -> void:
	var hand := _hand(10, 2, [[C.BOIS, 4], [C.FEU, 4]])
	hand.definition.level_qi = 15
	hand.definition.level_comprehension = 1
	var context := ScoringPipeline.score(hand, _no_effects(), 3)
	assert_eq(context.qi, 10 + 2 * 15 + 8)
	assert_eq(context.comprehension, 4.0)

func test_etapes_dans_l_ordre_du_calcul() -> void:
	var hand := _hand(10, 2, [[C.BOIS, 4], [C.FEU, 3]])
	var effects: Array[ScoreEffect] = [
		_effect(ScoreEffect.Phase.MULT_COMPREHENSION, 2.0),
		_effect(ScoreEffect.Phase.ADD_QI, 5.0),
	]
	var steps := ScoringPipeline.score(hand, effects).steps
	var kinds: Array = steps.map(func(step: ScoreStep) -> ScoreStep.Kind: return step.kind)
	assert_eq(kinds, [ScoreStep.Kind.BASE, ScoreStep.Kind.CARD, ScoreStep.Kind.CARD, ScoreStep.Kind.EFFECT, ScoreStep.Kind.EFFECT])
	assert_eq(steps[0].qi, 10, "base")
	assert_eq(steps[1].card, hand.scoring_cards[0])
	assert_eq(steps[2].qi, 17, "apres les deux cartes")
	assert_eq(steps[3].effect, effects[1], "l'addition avant la multiplication")
	assert_eq(steps[4].comprehension, 4.0)


func test_derniere_etape_egale_le_score() -> void:
	var effects: Array[ScoreEffect] = [_effect(ScoreEffect.Phase.ADD_COMPREHENSION, 1.5)]
	var context := ScoringPipeline.score(_hand(10, 2, [[C.BOIS, 4]]), effects)
	assert_eq(context.steps[-1].qi, context.qi)
	assert_eq(context.steps[-1].comprehension, context.comprehension)


func test_etapes_gardent_la_source_et_la_carte() -> void:
	var hand := _hand(10, 2, [[C.BOIS, 4]])
	var artifact := ArtifactDefinition.new()
	var triggered: Array[TriggeredEffect] = [
		TriggeredEffect.new(_effect(ScoreEffect.Phase.ADD_QI, 2.0), artifact, hand.scoring_cards[0]),
	]
	var step: ScoreStep = ScoringPipeline.score_triggered(hand, triggered).steps[-1]
	assert_eq(step.source, artifact)
	assert_eq(step.card, hand.scoring_cards[0])


func test_figures_et_souverain_selon_les_rangs_du_paquet() -> void:
	var ranks: RankRules = load("res://content/rules/rangs.tres")
	var hand := _hand(0, 1, [[C.BOIS, 12], [C.FEU, 13], [C.EAU, 9]])
	for card: CardInstance in hand.scoring_cards:
		card.ranks = ranks
	assert_eq(ScoringPipeline.score(hand, _no_effects()).qi, 10 + 11 + 9)


func test_le_qi_suit_le_rang_change_par_une_pilule() -> void:
	var card := CardInstance.new(0, CardData.create(&"c", Element.Type.BOIS, 9), load("res://content/rules/rangs.tres"))
	card.rank = 13
	assert_eq(card.qi(), 11)
