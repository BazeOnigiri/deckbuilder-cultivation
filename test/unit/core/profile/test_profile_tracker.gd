extends GutTest

## Garde le tracker en vie pendant le test : sinon il est libere et ses connexions de signaux avec lui.
var _tracker: ProfileTracker

func _run(realm_order: int, target: int, constraint: TribulationConstraint = null) -> RunState:
	var bottleneck := BottleneckDefinition.new()
	bottleneck.id = &"goulot"
	bottleneck.name_key = "TEST"
	bottleneck.score_multiplier = 1.0
	bottleneck.constraint = constraint
	var realm := RealmDefinition.new()
	realm.id = &"royaume"
	realm.name_key = "TEST"
	realm.order = realm_order
	realm.base_score = target
	realm.bottlenecks.append(bottleneck)
	var realms: Array[RealmDefinition] = [realm]
	var deck_definition := DeckDefinition.new()
	for rank: int in range(1, 11):
		deck_definition.cards.append(CardData.create(StringName("c%d" % rank), Element.Type.BOIS, rank))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var rules := RoundRules.new()
	rules.hand_size = 8
	rules.hands_per_round = 1
	rules.discards_per_round = 0
	rules.max_selected_cards = 5
	var hand := HandDefinition.new()
	hand.id = "test"
	hand.base_comprehension = 1
	hand.detector = HighCardDetector.new()
	var hands: Array[HandDefinition] = [hand]
	var economy := EconomyRules.new()
	economy.interest_step = 5
	return RunState.new(DeckState.new(deck_definition, rng), rules, HandEvaluator.new(hands), RunProgress.new(realms), economy)

func _play_highest(run: RunState) -> void:
	var best: CardInstance = run.current_round.hand()[0]
	for card: CardInstance in run.current_round.hand():
		if card.rank > best.rank:
			best = card
	var cards: Array[CardInstance] = [best]
	run.current_round.play(cards)


func test_compte_les_parties_lancees() -> void:
	var stats := ProfileStats.new()
	_tracker = ProfileTracker.new(stats)
	_tracker.track(_run(1, 100))
	assert_eq(stats.runs_started, 1)


func test_compte_les_victoires() -> void:
	var stats := ProfileStats.new()
	var run := _run(1, 1)
	_tracker = ProfileTracker.new(stats)
	_tracker.track(run)
	run.start()
	_play_highest(run)
	assert_eq(stats.runs_won, 1)


func test_retient_le_meilleur_royaume() -> void:
	var stats := ProfileStats.new()
	stats.best_realm = 1
	var run := _run(3, 100)
	_tracker = ProfileTracker.new(stats)
	_tracker.track(run)
	run.start()
	assert_eq(stats.best_realm, 3)


func test_retient_la_meilleure_main() -> void:
	var stats := ProfileStats.new()
	var run := _run(1, 1000)
	_tracker = ProfileTracker.new(stats)
	_tracker.track(run)
	run.start()
	_play_highest(run)
	assert_gt(stats.best_hand_score, 0)
	assert_eq(run.status, RunState.Status.LOST)
	assert_eq(stats.runs_won, 0)
	assert_eq(stats.hands.count_of("test"), 1)

func test_run_reprise_pas_comptee_comme_nouvelle() -> void:
	var stats := ProfileStats.new()
	_tracker = ProfileTracker.new(stats)
	_tracker.track(_run(1, 100), false)
	assert_eq(stats.runs_started, 0)

func test_une_main_jouee_signale_le_changement() -> void:
	var stats := ProfileStats.new()
	var run := _run(1, 1000)
	_tracker = ProfileTracker.new(stats)
	_tracker.track(run)
	run.start()
	var emitted := [0]
	_tracker.changed.connect(func() -> void: emitted[0] += 1)
	_play_highest(run)
	assert_gt(emitted[0], 0, "le profil doit etre ecrit apres une main")



func test_chaque_partie_terminee_entre_dans_l_historique() -> void:
	var stats := ProfileStats.new()
	var run := _run(1, 1000)
	run.seed_value = 42
	_tracker = ProfileTracker.new(stats)
	_tracker.clock = func() -> float: return 1000.0
	_tracker.track(run)
	run.start()
	_play_highest(run)
	assert_eq(stats.games.size(), 1)
	var game := stats.games[0]
	assert_false(game.won)
	assert_eq(game.played_at, 1000)
	assert_eq(game.realm_id, "royaume")
	assert_eq(game.bottleneck_id, "goulot")
	assert_eq(game.best_hand_id, "test")
	assert_eq(game.favorite_hand_id, "test")
	assert_gt(game.best_hand_score, 0)
	assert_eq(game.seed_text, "42")


func test_graine_inconnue_champ_vide() -> void:
	var stats := ProfileStats.new()
	var run := _run(1, 1)
	_tracker = ProfileTracker.new(stats)
	_tracker.track(run)
	run.start()
	_play_highest(run)
	assert_true(stats.games[0].won)
	assert_eq(stats.games[0].seed_text, "")


func test_historique_borne_par_les_regles() -> void:
	var stats := ProfileStats.new()
	var rules := ProfileRules.new()
	rules.history_size = 2
	_tracker = ProfileTracker.new(stats, rules)
	for i: int in 3:
		var run := _run(1, 1000)
		_tracker.clock = func() -> float: return float(i)
		_tracker.track(run)
		run.start()
		_play_highest(run)
	assert_eq(stats.games.size(), 2)
	assert_eq(stats.games[0].played_at, 1, "la plus ancienne est sortie")


func test_tribulation_victoires_et_defaites() -> void:
	var stats := ProfileStats.new()
	var constraint := TribulationConstraint.new()
	constraint.description_key = "X"
	_tracker = ProfileTracker.new(stats)
	var won_run := _run(1, 1, constraint)
	_tracker.track(won_run)
	won_run.start()
	_play_highest(won_run)
	var lost_run := _run(1, 1000, constraint)
	_tracker.track(lost_run)
	lost_run.start()
	_play_highest(lost_run)
	assert_eq(stats.tribulation_wins(&"goulot"), 1)
	assert_eq(stats.tribulation_losses(&"goulot"), 1)
	assert_true(stats.is_seen("tribulation", &"goulot"))


func test_goulot_sans_contrainte_n_est_pas_une_tribulation() -> void:
	var stats := ProfileStats.new()
	var run := _run(1, 1)
	_tracker = ProfileTracker.new(stats)
	_tracker.track(run)
	run.start()
	_play_highest(run)
	assert_true(stats.tribulations.is_empty())
	assert_false(stats.is_seen("tribulation", &"goulot"))


func test_ce_que_la_run_possede_est_vu() -> void:
	var content := GameContent.load_default()
	var stats := ProfileStats.new()
	var run := _run(1, 100)
	run.artifacts.append(content.artifacts[0])
	run.pills.append(content.pills[0])
	run.legacies.append(content.legacies[0])
	_tracker = ProfileTracker.new(stats)
	_tracker.track(run)
	assert_true(stats.is_seen("artifact", content.artifacts[0].id))
	assert_true(stats.is_seen("pill", content.pills[0].id))
	assert_true(stats.is_seen("legacy", content.legacies[0].id))


func test_la_boutique_montre_puis_compte_les_achats() -> void:
	var content := GameContent.load_default()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var run := content.new_run(rng)
	run.stones = 1000
	var shop := content.new_shop(run, rng)
	var stats := ProfileStats.new()
	_tracker = ProfileTracker.new(stats)
	_tracker.track_shop(shop)
	for artifact: ArtifactDefinition in shop.offers:
		assert_true(stats.is_seen("artifact", artifact.id), "offert donc vu")
	for pack: PackDefinition in shop.pack_offers:
		assert_true(stats.is_seen("pack", pack.id))
	if not shop.offers.is_empty():
		var bought: ArtifactDefinition = shop.offers[0]
		assert_true(shop.buy(0))
		assert_eq(stats.purchases_of(bought.id), 1)
	# La relance montre de nouvelles offres : elles sont vues aussi.
	assert_true(shop.reroll())
	for manual: ManualDefinition in shop.manual_offers:
		assert_true(stats.is_seen("manual", manual.id))
	for pill: PillDefinition in shop.pill_offers:
		assert_true(stats.is_seen("pill", pill.id))


func test_choix_d_un_sceau_ouvert_vus() -> void:
	var content := GameContent.load_default()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var run := content.new_run(rng)
	run.stones = 1000
	var shop := content.new_shop(run, rng)
	var stats := ProfileStats.new()
	_tracker = ProfileTracker.new(stats)
	_tracker.track_shop(shop)
	var index := -1
	for i: int in shop.pack_offers.size():
		if shop.pack_offers[i].kind != PackDefinition.Kind.CARD:
			index = i
	assert_gt(index, -1, "un sceau de contenu est propose avec cette graine")
	assert_true(shop.buy_pack(index))
	for choice: Resource in shop.opening.choices:
		assert_true(stats.is_seen(Compendium.KEYS[Compendium.kind_of(choice)], choice.id))
