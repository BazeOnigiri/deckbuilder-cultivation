extends GutTest
## Heritages : modificateurs de regles, regles effectives de la run, offre d'un heritage par royaume en boutique.


func _modifier(property: StringName, amount: int) -> RuleModifier:
	var modifier := RuleModifier.new()
	modifier.property = property
	modifier.amount = amount
	return modifier


func _legacy(id: String, modifiers: Array[RuleModifier], requires: StringName = &"", price: int = 10) -> LegacyDefinition:
	var legacy := LegacyDefinition.new()
	legacy.id = StringName(id)
	legacy.price = price
	legacy.requires = requires
	legacy.modifiers = modifiers
	return legacy


func _realm(order: int) -> RealmDefinition:
	var realm := RealmDefinition.new()
	realm.id = StringName("royaume_%d" % order)
	realm.order = order
	realm.base_score = 100
	var bottleneck := BottleneckDefinition.new()
	bottleneck.score_multiplier = 1.0
	realm.bottlenecks.append(bottleneck)
	return realm


func _run(stones: int) -> RunState:
	var rules := RoundRules.new()
	rules.hands_per_round = 4
	rules.discards_per_round = 3
	var economy := EconomyRules.new()
	economy.starting_stones = stones
	var realms: Array[RealmDefinition] = [_realm(1), _realm(2)]
	return RunState.new(null, rules, null, RunProgress.new(realms), economy)


func _shop_rules() -> ShopRules:
	var rules := ShopRules.new()
	rules.id = &"test"
	rules.offer_count = 1
	rules.max_artifacts = 5
	rules.reroll_base_cost = 5
	return rules


func _shop(run: RunState, legacies: Array[LegacyDefinition], seed_value: int = 1) -> ShopState:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return ShopState.new(run, [] as Array[ArtifactDefinition], [] as Array[ManualDefinition], [] as Array[PillDefinition],
		[] as Array[PackDefinition], legacies, DeckDefinition.new(), _shop_rules(), rng)


func test_modificateur_ajoute_sans_descendre_sous_zero() -> void:
	var rules := _shop_rules()
	_modifier(&"max_artifacts", 1).apply_to(rules)
	_modifier(&"reroll_base_cost", -9).apply_to(rules)
	_modifier(&"hands_per_round", 1).apply_to(rules)
	assert_eq(rules.max_artifacts, 6)
	assert_eq(rules.reroll_base_cost, 0)


func test_regles_effectives_sans_toucher_aux_regles_de_base() -> void:
	var run := _run(0)
	var base := run.round_rules()
	run.legacies.append(_legacy("h", [_modifier(&"hands_per_round", 1)] as Array[RuleModifier]))
	run.legacies.append(_legacy("d", [_modifier(&"discards_per_round", 2)] as Array[RuleModifier]))
	assert_eq(run.round_rules().hands_per_round, 5)
	assert_eq(run.round_rules().discards_per_round, 5)
	assert_eq(base.hands_per_round, 4, "regles de base intactes")


func test_un_heritage_propose_par_royaume() -> void:
	var run := _run(0)
	var legacies: Array[LegacyDefinition] = [_legacy("a", [_modifier(&"max_artifacts", 1)] as Array[RuleModifier]),
		_legacy("b", [_modifier(&"offer_count", 1)] as Array[RuleModifier])]
	var first := _shop(run, legacies).legacy_offer()
	assert_not_null(first)
	for seed_value: int in 10:
		assert_eq(_shop(run, legacies, seed_value).legacy_offer(), first, "meme royaume : meme heritage")
	run.progress.advance()
	_shop(run, legacies)
	assert_eq(run.legacy_offer_realm, 2, "nouveau royaume : nouveau tirage")


func test_prerequis_avant_l_amelioration() -> void:
	var run := _run(0)
	var base := _legacy("base", [_modifier(&"max_artifacts", 1)] as Array[RuleModifier])
	var upgrade := _legacy("plus", [_modifier(&"max_artifacts", 1)] as Array[RuleModifier], &"base")
	var legacies: Array[LegacyDefinition] = [upgrade, base]
	for seed_value: int in 10:
		run.legacy_offer_realm = 0
		assert_eq(_shop(run, legacies, seed_value).legacy_offer(), base)
	run.legacies.append(base)
	run.legacy_offer_realm = 0
	assert_eq(_shop(run, legacies).legacy_offer(), upgrade)


func test_achat_agit_tout_de_suite_sur_la_boutique() -> void:
	var run := _run(15)
	var legacies: Array[LegacyDefinition] = [_legacy("a", [_modifier(&"reroll_base_cost", -2)] as Array[RuleModifier])]
	var shop := _shop(run, legacies)
	assert_true(shop.buy_legacy())
	assert_eq(run.stones, 5)
	assert_eq(run.legacies.size(), 1)
	assert_null(shop.legacy_offer(), "achete : plus propose dans ce royaume")
	assert_eq(run.shop_rules(_shop_rules()).reroll_base_cost, 3)
	assert_eq(shop.reroll_cost, 3, "la relance en cours suit la nouvelle base")


func test_achat_refuse_sans_assez_de_pierres() -> void:
	var run := _run(9)
	var shop := _shop(run, [_legacy("a", [_modifier(&"max_artifacts", 1)] as Array[RuleModifier])] as Array[LegacyDefinition])
	assert_false(shop.buy_legacy())
	assert_eq(run.stones, 9)


func test_modificateur_sur_une_propriete_decimale() -> void:
	var rules := EconomyRules.new()
	rules.sell_fraction = 0.5
	_modifier(&"sell_fraction", 1).apply_to(rules)
	assert_eq(rules.sell_fraction, 1.5)
	_modifier(&"sell_fraction", -9).apply_to(rules)
	assert_eq(rules.sell_fraction, 0.0)
