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