extends GutTest

const C := preload("res://test/helpers/cards.gd")


func _result(hand_id: String, specs: Array) -> HandResult:
	var definition := HandDefinition.new()
	definition.id = hand_id
	return HandResult.new(definition, C.hand(specs))


func _effect(trigger: ArtifactEffect.Trigger, condition: ArtifactCondition, amount: float) -> ArtifactEffect:
	var score := ScoreEffect.new()
	score.phase = ScoreEffect.Phase.ADD_QI
	score.amount = amount
	var effect := ArtifactEffect.new()
	effect.trigger = trigger
	effect.condition = condition
	effect.score_effect = score
	return effect


func _artifacts(effects: Array) -> Array[ArtifactDefinition]:
	var artifact := ArtifactDefinition.new()
	artifact.effects.assign(effects)
	var artifacts: Array[ArtifactDefinition] = [artifact]
	return artifacts


func _element(element: Element.Type) -> CardElementCondition:
	var condition := CardElementCondition.new()
	condition.element = element
	return condition


func test_main_jouee_sans_condition_donne_un_effet() -> void:
	var artifacts := _artifacts([_effect(ArtifactEffect.Trigger.HAND_PLAYED, null, 10.0)])
	var effects := ArtifactResolver.effects_for(artifacts, _result("main_paire", [[C.FEU, 4], [C.EAU, 4]]))
	assert_eq(effects.size(), 1)


func test_condition_sur_la_main() -> void:
	var condition := HandIsCondition.new()
	condition.hand_ids = ["main_paire"]
	var artifacts := _artifacts([_effect(ArtifactEffect.Trigger.HAND_PLAYED, condition, 10.0)])
	assert_eq(ArtifactResolver.effects_for(artifacts, _result("main_paire", [[C.FEU, 4]])).size(), 1)
	assert_eq(ArtifactResolver.effects_for(artifacts, _result("main_brelan", [[C.FEU, 4]])).size(), 0)


func test_carte_comptee_un_effet_par_carte_qui_correspond() -> void:
	var artifacts := _artifacts([_effect(ArtifactEffect.Trigger.CARD_SCORED, _element(Element.Type.FEU), 4.0)])
	var result := _result("main_brelan", [[C.FEU, 6], [C.EAU, 6], [C.FEU, 6]])
	assert_eq(ArtifactResolver.effects_for(artifacts, result).size(), 2)


func test_carte_comptee_sans_condition_compte_toutes_les_cartes() -> void:
	var artifacts := _artifacts([_effect(ArtifactEffect.Trigger.CARD_SCORED, null, 1.0)])
	var result := _result("main_brelan", [[C.FEU, 6], [C.EAU, 6], [C.BOIS, 6]])
	assert_eq(ArtifactResolver.effects_for(artifacts, result).size(), 3)


func test_condition_de_rang_bornes_incluses() -> void:
	var condition := CardRankCondition.new()
	condition.min_rank = 1
	condition.max_rank = 3
	var artifacts := _artifacts([_effect(ArtifactEffect.Trigger.CARD_SCORED, condition, 6.0)])
	var result := _result("main_ascension", [[C.FEU, 1], [C.EAU, 2], [C.BOIS, 3], [C.TERRE, 4], [C.METAL, 5]])
	assert_eq(ArtifactResolver.effects_for(artifacts, result).size(), 3, "rangs 1, 2 et 3")
	assert_false(condition.matches(result, null), "sans carte : jamais vraie")


func test_condition_sur_le_nombre_de_cartes_qui_comptent() -> void:
	var condition := ScoringCountCondition.new()
	condition.max_count = 3
	var artifacts := _artifacts([_effect(ArtifactEffect.Trigger.HAND_PLAYED, condition, 1.0)])
	assert_eq(ArtifactResolver.effects_for(artifacts, _result("main_brelan", [[C.FEU, 6], [C.EAU, 6], [C.BOIS, 6]])).size(), 1)
	var long := _result("main_full", [[C.FEU, 6], [C.EAU, 6], [C.BOIS, 6], [C.FEU, 2], [C.EAU, 2]])
	assert_eq(ArtifactResolver.effects_for(artifacts, long).size(), 0, "5 cartes : trop longue")


func test_condition_de_carte_sur_main_jouee_jamais_vraie() -> void:
	var artifacts := _artifacts([_effect(ArtifactEffect.Trigger.HAND_PLAYED, _element(Element.Type.FEU), 4.0)])
	assert_eq(ArtifactResolver.effects_for(artifacts, _result("main_paire", [[C.FEU, 4]])).size(), 0)


func test_ordre_d_acquisition_conserve() -> void:
	var first := _artifacts([_effect(ArtifactEffect.Trigger.HAND_PLAYED, null, 1.0)])
	var second := _artifacts([_effect(ArtifactEffect.Trigger.HAND_PLAYED, null, 2.0)])
	var artifacts: Array[ArtifactDefinition] = [first[0], second[0]]
	var effects := ArtifactResolver.effects_for(artifacts, _result("main_paire", [[C.FEU, 4]]))
	assert_eq(effects[0].amount, 1.0)
	assert_eq(effects[1].amount, 2.0)

func test_effet_declenche_garde_son_artefact_et_sa_carte() -> void:
	var artifacts := _artifacts([
		_effect(ArtifactEffect.Trigger.HAND_PLAYED, null, 10.0),
		_effect(ArtifactEffect.Trigger.CARD_SCORED, _element(C.FEU), 2.0),
	])
	var result := _result("main_paire", [[C.FEU, 4], [C.EAU, 4]])
	var triggered := ArtifactResolver.triggered_for(artifacts, result)
	assert_eq(triggered.size(), 2)
	assert_eq(triggered[0].source, artifacts[0])
	assert_null(triggered[0].card, "main jouee : pas de carte")
	assert_eq(triggered[1].card, result.scoring_cards[0], "la carte Feu")


## CARD_HELD : une fois par carte gardee en main qui remplit la condition, jamais pour les cartes jouees.
func test_carte_gardee_en_main() -> void:
	var artifacts := _artifacts([_effect(ArtifactEffect.Trigger.CARD_HELD, _element(Element.Type.FEU), 3.0)])
	var result := _result("main_paire", [[C.FEU, 4], [C.FEU, 4]])
	var held := C.hand([[C.FEU, 2], [C.EAU, 9], [C.FEU, 7]])
	var triggered := ArtifactResolver.triggered_for(artifacts, result, held)
	assert_eq(triggered.size(), 2, "deux cartes Feu gardees")
	assert_eq(triggered[0].card, held[0])
	assert_eq(ArtifactResolver.effects_for(artifacts, result).size(), 0, "rien de garde : rien")


## Dans un round, les cartes gardees sont celles qui restent en main apres le coup.
func test_round_compte_les_cartes_gardees() -> void:
	var artifacts := _artifacts([_effect(ArtifactEffect.Trigger.CARD_HELD, null, 3.0)])
	var deck_definition := DeckDefinition.new()
	for rank: int in range(1, 6):
		deck_definition.cards.append(CardData.create(StringName("c%d" % rank), Element.Type.BOIS, rank))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var rules := RoundRules.new()
	rules.hand_size = 5
	rules.hands_per_round = 2
	rules.max_selected_cards = 5
	var definition := HandDefinition.new()
	definition.id = "test"
	definition.base_comprehension = 1
	definition.detector = HighCardDetector.new()
	var hands: Array[HandDefinition] = [definition]
	var round_state := RoundState.new(DeckState.new(deck_definition, rng), rules, HandEvaluator.new(hands), 1000, artifacts,
		HandLevels.new(), TribulationConstraint.new())
	round_state.start()
	var played: Array[CardInstance] = [round_state.hand()[0]]
	var context := round_state.play(played)
	assert_eq(context.qi, played[0].qi() + 4 * 3, "4 cartes gardees, +3 Qi chacune")


func _stones_effect(trigger: ArtifactEffect.Trigger, stones: int, per: ArtifactEffect.Per = ArtifactEffect.Per.ONCE,
		condition: ArtifactCondition = null) -> ArtifactEffect:
	var effect := ArtifactEffect.new()
	effect.trigger = trigger
	effect.stones = stones
	effect.per = per
	effect.condition = condition
	return effect


func test_pierres_au_goulot_une_fois_ou_par_main_restante() -> void:
	var artifacts := _artifacts([_stones_effect(ArtifactEffect.Trigger.ROUND_WON, 3),
		_stones_effect(ArtifactEffect.Trigger.ROUND_WON, 1, ArtifactEffect.Per.HAND_LEFT)])
	assert_eq(ArtifactResolver.after_round_won(artifacts, {}, 2, 1), 3 + 2)


func test_pierres_par_carte_defaussee_qui_remplit_la_condition() -> void:
	var artifacts := _artifacts([_stones_effect(ArtifactEffect.Trigger.CARD_DISCARDED, 1, ArtifactEffect.Per.ONCE,
		_element(Element.Type.BOIS))])
	assert_eq(ArtifactResolver.after_discard(artifacts, {}, C.hand([[C.BOIS, 2], [C.FEU, 3], [C.BOIS, 9]])), 2)


## Un artefact qui grandit : rien tant qu'il n'a pas de cran, puis growth_step par cran sur son effet de score.
func test_artefact_qui_grandit() -> void:
	var grow := ArtifactEffect.new()
	grow.trigger = ArtifactEffect.Trigger.CARD_DISCARDED
	grow.grows = true
	var artifacts := _artifacts([_effect(ArtifactEffect.Trigger.HAND_PLAYED, null, 0.0), grow])
	artifacts[0].id = &"bambou"
	artifacts[0].growth_step = 4.0
	var stacks := {}
	var result := _result("main_paire", [[C.FEU, 4]])
	assert_eq(ArtifactResolver.effects_for(artifacts, result, [], stacks).size(), 0, "+0 : rien a montrer")
	ArtifactResolver.after_discard(artifacts, stacks, C.hand([[C.FEU, 2], [C.EAU, 3]]))
	assert_eq(stacks[&"bambou"], 2)
	var effects := ArtifactResolver.effects_for(artifacts, result, [], stacks)
	assert_eq(effects.size(), 1)
	assert_eq(effects[0].amount, 8.0)
	assert_eq(artifacts[0].effects[0].score_effect.amount, 0.0, "la ressource partagee ne change pas")


func test_condition_de_main_sans_main_ne_plante_pas() -> void:
	var hand := HandIsCondition.new()
	hand.hand_ids = ["main_paire"]
	assert_false(hand.matches(null, null))
	assert_false(ScoringCountCondition.new().matches(null, null))


func test_validation_conditions_et_pierres() -> void:
	var hand := HandIsCondition.new()
	hand.hand_ids = ["main_paire"]
	var discard := _effect(ArtifactEffect.Trigger.CARD_DISCARDED, hand, 1.0)
	discard.stones = 1
	assert_false(discard.is_valid(), "condition de main sur une defausse")
	discard.condition = _element(Element.Type.FEU)
	assert_true(discard.is_valid(), "condition de carte sur une defausse")
	var won := ArtifactEffect.new()
	won.trigger = ArtifactEffect.Trigger.ROUND_WON
	won.stones = 2
	assert_true(won.is_valid())
	won.condition = _element(Element.Type.FEU)
	assert_false(won.is_valid(), "aucune condition sur ROUND_WON")
	var played := ArtifactEffect.new()
	played.trigger = ArtifactEffect.Trigger.HAND_PLAYED
	played.stones = 2
	assert_false(played.is_valid(), "pierres hors ROUND_WON / CARD_DISCARDED")
