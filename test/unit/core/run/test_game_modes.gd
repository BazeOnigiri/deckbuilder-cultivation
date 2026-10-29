extends GutTest
## Modes de partie sur le vrai contenu : graine, tribulations tirees, difficultes, defis, mode sans fin.

var _content: GameContent


func before_all() -> void:
	_content = GameContent.load_default()


func _run(setup: RunSetup) -> RunState:
	return _content.new_run(RandomNumberGenerator.new(), setup)


## Ce qui distingue deux parties : ordre de la pioche, tribulations tirees, premiere main.
func _fingerprint(run: RunState) -> Array:
	run.start()
	var hand: Array = run.current_round.hand().map(func(card: CardInstance) -> int: return card.uid)
	var tribulations: Array = run.progress.tribulations().map(func(b: BottleneckDefinition) -> StringName: return b.id)
	return [hand, tribulations, run.piles()]


func test_meme_graine_memes_options_meme_partie() -> void:
	var a := _fingerprint(_run(RunSetup.custom("WUXING", 1, true, "")))
	var b := _fingerprint(_run(RunSetup.custom("wuxing", 1, true, "")))
	assert_eq(a, b)
	assert_ne(_fingerprint(_run(RunSetup.custom("AUTRE", 1, true, ""))), a)


func test_partie_du_jour_identique_pour_une_date() -> void:
	var time := int(Time.get_unix_time_from_datetime_string("2026-10-29T08:00:00"))
	assert_eq(_fingerprint(_run(RunSetup.for_daily(time))), _fingerprint(_run(RunSetup.for_daily(time + 3600))))


func test_tribulations_tirees_sans_repetition() -> void:
	var run := _run(RunSetup.custom("TIRAGE", 1, true, ""))
	var ids: Array = run.progress.tribulations().map(func(b: BottleneckDefinition) -> StringName: return b.id)
	assert_eq(ids.size(), _content.realms.size())
	var unique := {}
	for id: StringName in ids:
		unique[id] = true
	assert_eq(unique.size(), mini(ids.size(), _content.tribulations.size()), "pas de doublon tant que le pool suffit")
	for realm: RealmDefinition in run.progress.realms():
		assert_eq(realm.bottlenecks.size(), 3, "seule la tribulation change")
		assert_null(realm.bottlenecks[0].constraint)


func test_mode_classique_garde_les_tribulations_du_contenu() -> void:
	var run := _run(RunSetup.custom("TIRAGE", 1, false, ""))
	var fixed := RunProgress.new(_content.realms).tribulations()
	assert_eq(run.progress.tribulations(), fixed)


func test_tirage_different_selon_la_graine() -> void:
	var differs := false
	var first := _run(RunSetup.custom("G0", 1, true, "")).progress.tribulations()
	for i: int in range(1, 6):
		differs = differs or _run(RunSetup.custom("G%d" % i, 1, true, "")).progress.tribulations() != first
	assert_true(differs)


func test_difficultes_cumulees_et_appliquees() -> void:
	var top: int = _content.difficulties[-1].level
	var run := _run(RunSetup.custom("D", top, false, ""))
	var expected := _content.round_rules.duplicate()
	var economy := _content.economy.duplicate()
	var shop := _content.shop_rules.duplicate()
	for difficulty: DifficultyDefinition in _content.difficulties:
		for modifier: RuleModifier in difficulty.modifiers:
			modifier.apply_to(expected)
			modifier.apply_to(economy)
			modifier.apply_to(shop)
	var rules := run.round_rules()
	assert_eq(rules.hands_per_round, expected.hands_per_round)
	assert_eq(rules.discards_per_round, expected.discards_per_round)
	assert_lt(rules.hands_per_round, _content.round_rules.hands_per_round)
	assert_gt(rules.target_percent, 100)
	assert_eq(run.economy().interest_cap, economy.interest_cap)
	assert_eq(run.shop_rules(_content.shop_rules).reroll_base_cost, shop.reroll_base_cost)
	assert_true(rules.is_valid(), "les regles restent jouables au plus haut niveau")
	run.start()
	var base := RunProgress.target_for(run.progress.current_realm(), run.progress.current_bottleneck())
	assert_eq(run.current_round.target_score, roundi(base * rules.target_percent / 100.0))


func test_niveau_un_sans_modificateur() -> void:
	var run := _run(RunSetup.custom("D", 1, false, ""))
	assert_true(run.modifiers.is_empty())
	assert_eq(run.round_rules(), _content.round_rules)


func test_heritages_s_ajoutent_a_la_difficulte() -> void:
	var run := _run(RunSetup.custom("D", 7, false, ""))
	var before := run.round_rules().hands_per_round
	var legacy := _content.legacy_by_id(&"heritage_meridien")
	run.legacies.append(legacy)
	assert_eq(run.round_rules().hands_per_round, before + 1)


func test_defis_appliques() -> void:
	for challenge: ChallengeDefinition in _content.challenges:
		var run := _run(RunSetup.for_challenge(challenge, "DEFI"))
		assert_eq(run.setup.challenge, challenge)
		for artifact: ArtifactDefinition in challenge.artifacts:
			assert_has(run.artifacts, artifact)
		for legacy: LegacyDefinition in challenge.legacies:
			assert_has(run.legacies, legacy)
		assert_eq(run.cards().size(), _content.deck_for(run.setup).cards.size())
		run.start()
		assert_eq(run.current_round.hand().size(), run.round_rules().hand_size, String(challenge.id))
		# La boutique se cree meme sans marchandise (defi de l'ermite).
		var rng := RandomNumberGenerator.new()
		assert_not_null(_content.new_shop(run, rng))


func test_defi_sans_marchandise() -> void:
	var run := _run(RunSetup.for_challenge(_content.challenge_by_id(&"defi_ermite"), "DEFI"))
	var shop := _content.new_shop(run, RandomNumberGenerator.new())
	assert_eq(shop.offers.size() + shop.manual_offers.size() + shop.pill_offers.size(), 0)


func test_mode_sans_fin_genere_des_royaumes_croissants() -> void:
	var run := _run(RunSetup.custom("SANSFIN", 1, true, ""))
	var count := run.progress.realm_count()
	assert_false(run.continue_endless(_content.tribulations, RandomNumberGenerator.new()), "pas avant la victoire")
	run.status = RunState.Status.WON
	var rng := RandomNumberGenerator.new()
	var last := run.progress.realms()[-1]
	assert_true(run.continue_endless(_content.tribulations, rng))
	assert_true(run.endless)
	assert_eq(run.status, RunState.Status.BETWEEN_ROUNDS)
	assert_eq(run.progress.realm_count(), count + 1)
	var realm := run.progress.current_realm()
	assert_eq(realm.number, 1)
	assert_eq(realm.order, last.order + 1)
	assert_eq(realm.base_score, roundi(BalanceModel.round_to_digits(last.base_score * _content.endless_growth,
		_content.balance.significant_digits)), "meme formule que l'equilibrage")
	assert_gt(realm.base_score, last.base_score)
	assert_not_null(RunProgress.tribulation_of(realm))
	assert_ne(RunProgress.tribulation_of(realm), RunProgress.tribulation_of(last), "pas deux fois de suite")
	assert_true(run.next_round())
	assert_eq(run.current_round.target_score, run.target_for(realm, realm.bottlenecks[0]))


## La croissance generee suit celle que l'equilibrage a ecrite entre les derniers royaumes du contenu.
func test_croissance_sans_fin_coherente_avec_le_contenu() -> void:
	var realms := RunProgress.new(_content.realms).realms()
	var written := float(realms[-1].base_score) / realms[-2].base_score
	assert_almost_eq(_content.endless_growth, written, written * 0.1)
