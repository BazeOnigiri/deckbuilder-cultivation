extends GutTest

const MAX_SELECTED := 5


func _rules(hand_size: int, hands: int, discards: int) -> RoundRules:
	var rules := RoundRules.new()
	rules.id = "test"
	rules.hand_size = hand_size
	rules.hands_per_round = hands
	rules.discards_per_round = discards
	rules.max_selected_cards = MAX_SELECTED
	return rules


## Une seule main "carte haute" sans bonus : le score d'un coup vaut le plus haut rang joue.
func _evaluator() -> HandEvaluator:
	var definition := HandDefinition.new()
	definition.id = "test"
	definition.base_comprehension = 1
	definition.level_qi = 10
	definition.detector = HighCardDetector.new()
	var definitions: Array[HandDefinition] = [definition]
	return HandEvaluator.new(definitions)


func _round(ranks: Array, hand_size: int, target: int, hands: int = 3, discards: int = 1, artifacts: Array = [], levels: HandLevels = null, constraint: TribulationConstraint = null) -> RoundState:
	var definition := DeckDefinition.new()
	for i: int in ranks.size():
		definition.cards.append(CardData.create(StringName("c%d" % i), Element.Type.BOIS, ranks[i]))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var deck := DeckState.new(definition, rng)
	var typed: Array[ArtifactDefinition] = []
	typed.assign(artifacts)
	var round_levels: HandLevels = levels if levels != null else HandLevels.new()
	var round_constraint: TribulationConstraint = constraint if constraint != null else TribulationConstraint.new()
	var round_state := RoundState.new(deck, _rules(hand_size, hands, discards), _evaluator(), target, typed, round_levels, round_constraint)
	round_state.start()
	return round_state


func _pick(round_state: RoundState, rank: int) -> Array[CardInstance]:
	var picked: Array[CardInstance] = []
	for card: CardInstance in round_state.hand():
		if card.rank == rank:
			picked.append(card)
			break
	return picked


func _first(round_state: RoundState, count: int) -> Array[CardInstance]:
	var picked: Array[CardInstance] = []
	for i: int in count:
		picked.append(round_state.hand()[i])
	return picked


func test_start_pioche_la_main() -> void:
	var r := _round([1, 2, 3, 4, 5, 6, 7, 8], 8, 100)
	assert_eq(r.hand().size(), 8)
	assert_eq(r.status, RoundState.Status.PLAYING)


func test_jouer_ajoute_le_score_et_consomme_une_main() -> void:
	var r := _round([1, 2, 3, 4, 5, 6, 7, 8], 8, 100)
	var context := r.play(_pick(r, 5))
	assert_not_null(context)
	assert_eq(r.score, 5)
	assert_eq(r.hands_left, 2)
	assert_eq(r.hand().size(), 7)


func test_victoire_quand_objectif_atteint() -> void:
	var r := _round([1, 2, 3, 4, 5, 6, 7, 8], 8, 8)
	watch_signals(r)
	r.play(_pick(r, 8))
	assert_eq(r.status, RoundState.Status.WON)
	assert_signal_emitted_with_parameters(r, "finished", [true])


func test_defaite_quand_plus_de_mains() -> void:
	var r := _round([1, 2, 3, 4, 5, 6, 7, 8], 8, 100, 1)
	watch_signals(r)
	r.play(_pick(r, 1))
	assert_eq(r.status, RoundState.Status.LOST)
	assert_signal_emitted_with_parameters(r, "finished", [false])


func test_defaite_quand_main_et_pioche_vides() -> void:
	var r := _round([5], 8, 100)
	r.play(_pick(r, 5))
	assert_eq(r.status, RoundState.Status.LOST)


func test_refuse_trop_de_cartes() -> void:
	var r := _round([1, 2, 3, 4, 5, 6, 7, 8], 8, 100)
	assert_null(r.play(_first(r, MAX_SELECTED + 1)))
	assert_eq(r.hands_left, 3)
	assert_eq(r.hand().size(), 8)


func test_refuse_selection_vide() -> void:
	var r := _round([1, 2, 3, 4, 5, 6, 7, 8], 8, 100)
	var empty: Array[CardInstance] = []
	assert_null(r.play(empty))
	assert_false(r.discard(empty))


func test_refuse_carte_hors_main() -> void:
	var r := _round([1, 2, 3, 4, 5, 6, 7, 8], 8, 100)
	var outsider: Array[CardInstance] = [CardInstance.new(99, CardData.create(&"x", Element.Type.FEU, 9))]
	assert_null(r.play(outsider))
	assert_eq(r.score, 0)
	assert_eq(r.hands_left, 3)


func test_refuse_apres_la_fin() -> void:
	var r := _round([1, 2, 3, 4, 5, 6, 7, 8], 8, 1)
	r.play(_pick(r, 8))
	assert_null(r.play(_pick(r, 7)))
	assert_false(r.discard(_pick(r, 7)))


func test_defausse_repioche_et_consomme_une_defausse() -> void:
	var r := _round([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 8, 100, 3, 1)
	assert_true(r.discard(_first(r, 2)))
	assert_eq(r.discards_left, 0)
	assert_eq(r.hand().size(), 8)
	assert_false(r.discard(_first(r, 1)))

func test_artefact_ajoute_son_effet_au_score() -> void:
	var score := ScoreEffect.new()
	score.phase = ScoreEffect.Phase.ADD_QI
	score.amount = 10.0
	var effect := ArtifactEffect.new()
	effect.score_effect = score
	var artifact := ArtifactDefinition.new()
	artifact.effects.append(effect)
	var r := _round([1, 2, 3, 4, 5, 6, 7, 8], 8, 100, 3, 1, [artifact])
	r.play(_pick(r, 5))
	assert_eq(r.score, 15)

func test_niveau_de_main_augmente_le_score() -> void:
	var levels := HandLevels.new()
	levels.level_up("test")
	var r := _round([1, 2, 3, 4, 5, 6, 7, 8], 8, 100, 3, 1, [], levels)
	r.play(_pick(r, 5))
	assert_eq(r.score, 15)

func test_carte_scellee_ne_compte_pas() -> void:
	var seal := ElementSealConstraint.new()
	seal.element = Element.Type.BOIS
	var r := _round([1, 2, 3, 4, 5, 6, 7, 8], 8, 100, 3, 1, [], null, seal)
	var context := r.play(_pick(r, 5))
	assert_not_null(context)
	assert_eq(r.score, 0)
	assert_eq(context.hand.scoring_cards.size(), 0)


func test_tribulation_retire_une_main() -> void:
	var constraint := ReducedHandsConstraint.new()
	constraint.amount = 1
	var r := _round([1, 2, 3, 4, 5, 6, 7, 8], 8, 100, 3, 1, [], null, constraint)
	assert_eq(r.hands_left, 2)


func test_tribulation_reduit_la_main() -> void:
	var constraint := ReducedHandSizeConstraint.new()
	constraint.amount = 2
	var r := _round([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 8, 100, 3, 1, [], null, constraint)
	assert_eq(r.hand().size(), 6)
	r.discard(_first(r, 1))
	assert_eq(r.hand().size(), 6)

func test_main_vide_hors_coup_repioche() -> void:
	var r := _round([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 8, 100)
	var all_cards: Array[CardInstance] = []
	all_cards.assign(r.hand())
	assert_true(r.hand().size() == 8)
	_destroy(r, all_cards)
	r.ensure_playable()
	assert_eq(r.hand().size(), 2)
	assert_eq(r.status, RoundState.Status.PLAYING)


func test_main_et_pioche_vides_hors_coup_font_perdre() -> void:
	var r := _round([1, 2, 3, 4, 5, 6, 7, 8], 8, 100)
	var all_cards: Array[CardInstance] = []
	all_cards.assign(r.hand())
	_destroy(r, all_cards)
	r.ensure_playable()
	assert_eq(r.status, RoundState.Status.LOST)


## Passe par une pilule de destruction, comme en jeu.
func _destroy(r: RoundState, cards: Array[CardInstance]) -> void:
	var deck: DeckState = r.get("_deck")
	DestroyPillEffect.new().apply(cards, deck)

func test_apercu_reconnait_la_main_sans_jouer() -> void:
	var r := _round([1, 2, 3, 4, 5, 6, 7, 8], 8, 100)
	var hand_before: Array[CardInstance] = r.hand().duplicate()
	var result := r.preview(_pick(r, 5))
	assert_not_null(result)
	assert_eq(result.definition.id, "test")
	assert_eq(r.score, 0)
	assert_eq(r.hands_left, 3)
	assert_eq(r.hand(), hand_before)


func test_apercu_d_une_selection_invalide_est_nul() -> void:
	var r := _round([1, 2, 3, 4, 5, 6, 7, 8], 8, 100)
	var empty: Array[CardInstance] = []
	assert_null(r.preview(empty))
	assert_null(r.preview(_first(r, MAX_SELECTED + 1)))


func test_pioche_diminue_quand_on_pioche() -> void:
	var r := _round([1, 2, 3, 4, 5, 6, 7, 8, 9, 1], 8, 100)
	assert_eq(r.deck_size(), 10)
	assert_eq(r.draw_count(), 2)
	r.discard(_first(r, 2))
	assert_eq(r.draw_count(), 0, "deux cartes repiochees")


func test_carte_scellee_reconnue_avant_de_jouer() -> void:
	var seal := ElementSealConstraint.new()
	seal.element = Element.Type.FEU
	var r := _round([1, 2, 3, 4, 5, 6, 7, 8], 8, 100, 3, 1, [], null, seal)
	var card: CardInstance = r.hand()[0]
	assert_true(r.counts(card), "carte de bois : pas scellee")
	card.element = Element.Type.FEU
	assert_false(r.counts(card))
