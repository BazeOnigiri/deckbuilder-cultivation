extends GutTest

const HAND_SIZE := 8


func _realm(order: int, base_score: int, multipliers: Array) -> RealmDefinition:
	var realm := RealmDefinition.new()
	realm.id = StringName("royaume_%d" % order)
	realm.name_key = "TEST"
	realm.order = order
	realm.base_score = base_score
	for multiplier: float in multipliers:
		var bottleneck := BottleneckDefinition.new()
		bottleneck.id = &"goulot"
		bottleneck.name_key = "TEST"
		bottleneck.score_multiplier = multiplier
		bottleneck.reward = 3
		realm.bottlenecks.append(bottleneck)
	return realm


## Carte haute sans bonus : le score d'un coup vaut le plus haut rang joue.
func _evaluator() -> HandEvaluator:
	var definition := HandDefinition.new()
	definition.id = "test"
	definition.base_comprehension = 1
	definition.detector = HighCardDetector.new()
	var definitions: Array[HandDefinition] = [definition]
	return HandEvaluator.new(definitions)


func _run(realms: Array, hands: int = 3) -> RunState:
	var deck_definition := DeckDefinition.new()
	for rank: int in range(1, 11):
		deck_definition.cards.append(CardData.create(StringName("c%d" % rank), Element.Type.BOIS, rank))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var rules := RoundRules.new()
	rules.id = "test"
	rules.hand_size = HAND_SIZE
	rules.hands_per_round = hands
	rules.discards_per_round = 1
	rules.max_selected_cards = 5
	var typed: Array[RealmDefinition] = []
	typed.assign(realms)
	var economy := EconomyRules.new()
	economy.id = &"test"
	economy.starting_stones = 4
	economy.stones_per_hand_left = 1
	economy.interest_step = 5
	economy.interest_cap = 5
	return RunState.new(DeckState.new(deck_definition, rng), rules, _evaluator(), RunProgress.new(typed), economy)

func _play_one(run: RunState) -> void:
	var cards: Array[CardInstance] = [run.current_round.hand()[0]]
	run.current_round.play(cards)


func test_start_lance_le_premier_goulot() -> void:
	var run := _run([_realm(1, 100, [1.0, 2.0])])
	watch_signals(run)
	run.start()
	assert_signal_emitted(run, "round_started")
	assert_eq(run.status, RunState.Status.IN_ROUND)
	assert_eq(run.current_round.target_score, 100)
	assert_eq(run.current_round.hand().size(), HAND_SIZE)


func test_goulot_franchi_attend_le_suivant() -> void:
	var run := _run([_realm(1, 1, [1.0, 2.0])])
	watch_signals(run)
	run.start()
	_play_one(run)
	assert_eq(run.status, RunState.Status.BETWEEN_ROUNDS)
	assert_signal_emitted(run, "round_won")
	assert_signal_not_emitted(run, "finished")


func test_next_round_lance_le_goulot_suivant_avec_un_paquet_complet() -> void:
	var run := _run([_realm(1, 1, [1.0, 200.0])])
	run.start()
	var first_round := run.current_round
	_play_one(run)
	assert_true(run.next_round())
	assert_ne(run.current_round, first_round)
	assert_eq(run.status, RunState.Status.IN_ROUND)
	assert_eq(run.current_round.target_score, 200)
	assert_eq(run.current_round.hand().size(), HAND_SIZE)


func test_next_round_refuse_pendant_un_round() -> void:
	var run := _run([_realm(1, 100, [1.0, 2.0])])
	run.start()
	assert_false(run.next_round())


func test_defaite_termine_la_run() -> void:
	var run := _run([_realm(1, 1000, [1.0])], 1)
	watch_signals(run)
	run.start()
	_play_one(run)
	assert_eq(run.status, RunState.Status.LOST)
	assert_signal_emitted_with_parameters(run, "finished", [false])
	assert_false(run.next_round())


func test_dernier_goulot_franchi_gagne_la_run() -> void:
	var run := _run([_realm(1, 1, [1.0])])
	watch_signals(run)
	run.start()
	_play_one(run)
	assert_eq(run.status, RunState.Status.WON)
	assert_signal_emitted_with_parameters(run, "finished", [true])
	assert_signal_not_emitted(run, "round_won")

func test_run_demarre_avec_les_pierres_de_depart() -> void:
	var run := _run([_realm(1, 100, [1.0])])
	assert_eq(run.stones, 4)


func test_goulot_franchi_rapporte_des_pierres() -> void:
	var run := _run([_realm(1, 1, [1.0, 2.0])])
	watch_signals(run)
	run.start()
	_play_one(run)
	# 4 de depart + 3 de base + 2 mains restantes + 0 d'interet (4 / 5).
	assert_eq(run.stones, 9)
	var reward: RoundReward = get_signal_parameters(run, "round_won")[0]
	assert_eq(reward.total(), 5)

func test_artefacts_de_la_run_agissent_dans_le_round() -> void:
	var score := ScoreEffect.new()
	score.phase = ScoreEffect.Phase.ADD_QI
	score.amount = 1000.0
	var effect := ArtifactEffect.new()
	effect.score_effect = score
	var artifact := ArtifactDefinition.new()
	artifact.effects.append(effect)
	var run := _run([_realm(1, 500, [1.0])])
	run.artifacts.append(artifact)
	run.start()
	_play_one(run)
	assert_eq(run.status, RunState.Status.WON)

func _fire_pill(max_cards: int = 2) -> PillDefinition:
	var effect := SetElementPillEffect.new()
	effect.element = Element.Type.FEU
	var pill := PillDefinition.new()
	pill.min_cards = 1
	pill.max_cards = max_cards
	pill.effect = effect
	return pill


func test_pilule_appliquee_puis_consommee() -> void:
	var run := _run([_realm(1, 100, [1.0])])
	run.pills.append(_fire_pill())
	run.start()
	var cards: Array[CardInstance] = [run.current_round.hand()[0]]
	assert_true(run.use_pill(0, cards))
	assert_eq(cards[0].element, Element.Type.FEU)
	assert_eq(run.pills.size(), 0)


func test_pilule_refusee_avec_trop_de_cartes() -> void:
	var run := _run([_realm(1, 100, [1.0])])
	run.pills.append(_fire_pill(1))
	run.start()
	var cards: Array[CardInstance] = [run.current_round.hand()[0], run.current_round.hand()[1]]
	assert_false(run.use_pill(0, cards))
	assert_eq(run.pills.size(), 1)


func test_pilule_refusee_sur_une_carte_hors_main() -> void:
	var run := _run([_realm(1, 100, [1.0])])
	run.pills.append(_fire_pill())
	run.start()
	var outsider: Array[CardInstance] = [CardInstance.new(99, CardData.create(&"x", Element.Type.EAU, 1))]
	assert_false(run.use_pill(0, outsider))
	assert_eq(outsider[0].element, Element.Type.EAU)


func test_pilule_refusee_hors_round() -> void:
	var run := _run([_realm(1, 1, [1.0, 2.0])])
	run.pills.append(_fire_pill())
	run.start()
	_play_one(run)
	assert_eq(run.status, RunState.Status.BETWEEN_ROUNDS)
	var cards: Array[CardInstance] = [run.current_round.hand()[0]]
	assert_false(run.use_pill(0, cards))

func test_contrainte_du_goulot_appliquee_au_round() -> void:
	var realm := _realm(1, 100, [1.0])
	var constraint := ReducedHandsConstraint.new()
	constraint.description_key = "TEST"
	constraint.amount = 2
	realm.bottlenecks[0].constraint = constraint
	var run := _run([realm], 3)
	run.start()
	assert_eq(run.current_round.hands_left, 1)

func test_pilule_qui_vide_la_main_fait_repiocher() -> void:
	var effect := DestroyPillEffect.new()
	var pill := PillDefinition.new()
	pill.min_cards = 1
	pill.max_cards = HAND_SIZE
	pill.effect = effect
	var run := _run([_realm(1, 100, [1.0])])
	run.pills.append(pill)
	run.start()
	var all_cards: Array[CardInstance] = []
	all_cards.assign(run.current_round.hand())
	assert_true(run.use_pill(0, all_cards))
	assert_eq(run.current_round.hand().size(), 2)
	assert_eq(run.status, RunState.Status.IN_ROUND)

func test_stats_de_run_comptent_les_mains() -> void:
	var run := _run([_realm(1, 1000, [1.0])])
	run.start()
	_play_one(run)
	assert_eq(run.stats.hands.count_of("test"), 1)
	assert_gt(run.stats.best_hand_score, 0)


func test_stats_de_run_comptent_les_defausses() -> void:
	var run := _run([_realm(1, 1000, [1.0])])
	run.start()
	var cards: Array[CardInstance] = [run.current_round.hand()[0]]
	run.current_round.discard(cards)
	assert_eq(run.stats.discards_used, 1)


func test_stats_de_run_comptent_les_goulots_et_les_pierres() -> void:
	var run := _run([_realm(1, 1, [1.0, 2.0])])
	run.start()
	_play_one(run)
	assert_eq(run.stats.bottlenecks_cleared, 1)
	assert_eq(run.stats.stones_earned, 5)

func _artifact_priced(price: int) -> ArtifactDefinition:
	var artifact := ArtifactDefinition.new()
	artifact.id = StringName("a%d" % price)
	artifact.price = price
	return artifact


## Vente : la moitie du prix, arrondie en dessous ; l'emplacement est libere.
func test_vente_rend_la_moitie_arrondie_en_dessous() -> void:
	var run := _run([_realm(1, 100, [1.0])])
	run.artifacts.assign([_artifact_priced(5), _artifact_priced(4)])
	assert_true(run.sell_artifact(0))
	assert_eq(run.stones, 4 + 2)
	assert_eq(run.artifacts.size(), 1)
	assert_eq(run.artifacts[0].price, 4)


func test_vente_refusee_hors_des_artefacts() -> void:
	var run := _run([_realm(1, 100, [1.0])])
	run.artifacts.assign([_artifact_priced(5)])
	assert_false(run.sell_artifact(1))
	assert_false(run.sell_artifact(-1))
	assert_eq(run.stones, 4)
	assert_eq(run.artifacts.size(), 1)


## Un artefact vendu en plein round n'agit plus a la main suivante : le round partage la liste de la run.
func test_artefact_vendu_quitte_le_round() -> void:
	var run := _run([_realm(1, 1000, [1.0])])
	run.start()
	run.artifacts.append(_artifact_priced(2))
	run.sell_artifact(0)
	assert_true(run.current_round._artifacts.is_empty())


## Les pierres d'un artefact s'ajoutent a la recompense du goulot ; ses crans quittent la run avec lui.
func test_pierres_d_artefact_au_goulot_et_crans_vendus() -> void:
	var run := _run([_realm(1, 1, [1.0, 2.0])])
	var artifact := _artifact_priced(2)
	var effect := ArtifactEffect.new()
	effect.trigger = ArtifactEffect.Trigger.ROUND_WON
	effect.stones = 3
	effect.grows = true
	artifact.effects.append(effect)
	run.artifacts.append(artifact)
	watch_signals(run)
	run.start()
	_play_one(run)
	var reward: RoundReward = get_signal_parameters(run, "round_won")[0]
	assert_eq(reward.artifacts, 3)
	assert_eq(run.artifact_stacks[artifact.id], 1)
	run.sell_artifact(0)
	assert_false(run.artifact_stacks.has(artifact.id))
