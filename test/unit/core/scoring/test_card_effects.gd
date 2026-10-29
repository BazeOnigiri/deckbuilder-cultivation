extends GutTest
## Ameliorations, auras et talismans dans le calcul du score : effets ranges par phase, recomptes, cartes gardees.

const C := preload("res://test/helpers/cards.gd")


func _effect(phase: ScoreEffect.Phase, amount: float) -> ScoreEffect:
	var effect := ScoreEffect.new()
	effect.phase = phase
	effect.amount = amount
	return effect


func _enhancement(scored: ScoreEffect = null, held: ScoreEffect = null) -> EnhancementDefinition:
	var enhancement := EnhancementDefinition.new()
	enhancement.id = &"test_amelioration"
	enhancement.scored_effect = scored
	enhancement.held_effect = held
	return enhancement


func _edition(effect: ScoreEffect) -> EditionDefinition:
	var edition := EditionDefinition.new()
	edition.id = &"test_aura"
	edition.score_effect = effect
	return edition


func _talisman(retriggers: int = 0, level_ups: int = 0) -> TalismanDefinition:
	var talisman := TalismanDefinition.new()
	talisman.id = &"test_talisman"
	talisman.retriggers = retriggers
	talisman.scored_level_ups = level_ups
	return talisman


## Main de base 10 Qi x 1, toutes les cartes donnees comptent.
func _hand(cards: Array[CardInstance]) -> HandResult:
	var definition := HandDefinition.new()
	definition.id = "test"
	definition.base_qi = 10
	definition.base_comprehension = 1
	return HandResult.new(definition, cards)


func _score(result: HandResult, held: Array[CardInstance] = []) -> ScoreContext:
	return ScoringPipeline.score_triggered(result, CardEffects.triggered_for(result, held))


func test_multiplication_apres_les_additions_meme_si_la_carte_vient_avant() -> void:
	var cards := C.hand([[C.BOIS, 5], [C.FEU, 3]])
	cards[0].enhancement = _enhancement(_effect(ScoreEffect.Phase.MULT_COMPREHENSION, 2.0))
	cards[1].enhancement = _enhancement(_effect(ScoreEffect.Phase.ADD_COMPREHENSION, 4.0))
	var context := _score(_hand(cards))
	# (10 + 5 + 3) x ((1 + 4) x 2)
	assert_eq(context.total(), 180)
	var last: ScoreStep = context.steps[-1]
	assert_eq(last.effect.phase, ScoreEffect.Phase.MULT_COMPREHENSION)
	assert_eq(last.card, cards[0])
	assert_eq(last.source, cards[0].enhancement)


func test_amelioration_et_aura_se_cumulent() -> void:
	var cards := C.hand([[C.BOIS, 5]])
	cards[0].enhancement = _enhancement(_effect(ScoreEffect.Phase.ADD_QI, 30.0))
	cards[0].edition = _edition(_effect(ScoreEffect.Phase.MULT_COMPREHENSION, 1.5))
	var context := _score(_hand(cards))
	assert_eq(context.qi, 45)
	assert_almost_eq(context.comprehension, 1.5, 0.001)


func test_talisman_d_echo_recompte_le_qi_et_les_effets() -> void:
	var cards := C.hand([[C.BOIS, 5]])
	cards[0].talisman = _talisman(1)
	cards[0].enhancement = _enhancement(_effect(ScoreEffect.Phase.ADD_COMPREHENSION, 2.0))
	var context := _score(_hand(cards))
	assert_eq(context.qi, 20)
	assert_almost_eq(context.comprehension, 5.0, 0.001)
	var card_steps := context.steps.filter(func(step: ScoreStep) -> bool: return step.kind == ScoreStep.Kind.CARD)
	assert_eq(card_steps.size(), 2)


func test_recompte_declenche_aussi_les_artefacts_de_carte() -> void:
	var cards := C.hand([[C.BOIS, 5]])
	cards[0].talisman = _talisman(1)
	var effect := ArtifactEffect.new()
	effect.trigger = ArtifactEffect.Trigger.CARD_SCORED
	effect.score_effect = _effect(ScoreEffect.Phase.ADD_QI, 7.0)
	var artifact := ArtifactDefinition.new()
	artifact.id = &"test"
	artifact.effects = [effect]
	var artifacts: Array[ArtifactDefinition] = [artifact]
	assert_eq(ArtifactResolver.triggered_for(artifacts, _hand(cards)).size(), 2)


func test_carte_gardee_en_main_multiplie() -> void:
	var played := C.hand([[C.BOIS, 5]])
	var held := C.hand([[C.FEU, 2], [C.EAU, 3]])
	held[0].enhancement = _enhancement(null, _effect(ScoreEffect.Phase.MULT_COMPREHENSION, 1.5))
	held[1].enhancement = _enhancement(_effect(ScoreEffect.Phase.ADD_QI, 99.0))
	var context := _score(_hand(played), held)
	# Le Qi de la carte gardee ne compte pas, seul l'effet de main gardee joue.
	assert_eq(context.qi, 15)
	assert_almost_eq(context.comprehension, 1.5, 0.001)


func test_carte_sans_amelioration_ne_change_rien() -> void:
	var cards := C.hand([[C.BOIS, 5], [C.FEU, 3]])
	assert_true(CardEffects.triggered_for(_hand(cards), []).is_empty())
	assert_eq(_score(_hand(cards)).total(), 18)


func test_pierres_et_niveaux_des_cartes_qui_comptent() -> void:
	var cards := C.hand([[C.BOIS, 5], [C.FEU, 3]])
	var treasure := _enhancement()
	treasure.scored_stones = 2
	cards[0].enhancement = treasure
	cards[0].talisman = _talisman(1, 1)
	cards[1].talisman = _talisman(0, 1)
	assert_eq(CardEffects.stones_for(_hand(cards)), 4, "recompte : deux fois les pierres")
	assert_eq(CardEffects.level_ups(_hand(cards)), 2, "un niveau par carte, recompte non double")


func test_carte_de_jade_se_brise_selon_la_rng() -> void:
	var cards := C.hand([[C.BOIS, 5], [C.FEU, 3], [C.EAU, 4], [C.TERRE, 6], [C.METAL, 7]])
	var jade := _enhancement()
	jade.break_chance = 0.5
	for card: CardInstance in cards:
		card.enhancement = jade
	var first := RandomNumberGenerator.new()
	first.seed = 42
	var second := RandomNumberGenerator.new()
	second.seed = 42
	var broken := CardEffects.roll_breaks(_hand(cards), first)
	assert_eq(broken, CardEffects.roll_breaks(_hand(cards), second), "meme graine, memes cartes brisees")
	jade.break_chance = 1.0
	assert_eq(CardEffects.roll_breaks(_hand(cards), first).size(), 5)
	jade.break_chance = 0.0
	assert_true(CardEffects.roll_breaks(_hand(cards), first).is_empty())


func test_carte_de_roc_a_un_qi_fixe() -> void:
	var cards := C.hand([[C.BOIS, 3]])
	var rock := _enhancement()
	rock.rankless = true
	rock.fixed_qi = 50
	cards[0].enhancement = rock
	assert_eq(cards[0].qi(), 50)
	assert_eq(_score(_hand(cards)).qi, 60)
