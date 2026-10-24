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