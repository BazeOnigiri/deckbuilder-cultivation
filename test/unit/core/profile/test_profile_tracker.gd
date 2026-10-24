extends GutTest

## Garde le tracker en vie pendant le test : sinon il est libere et ses connexions de signaux avec lui.
var _tracker: ProfileTracker

func _run(realm_order: int, target: int) -> RunState:
	var bottleneck := BottleneckDefinition.new()
	bottleneck.id = &"goulot"
	bottleneck.name_key = "TEST"
	bottleneck.score_multiplier = 1.0
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
	assert_eq(stats.hand_counts.get("test", 0), 1)