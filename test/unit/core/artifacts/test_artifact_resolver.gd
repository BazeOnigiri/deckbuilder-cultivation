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
