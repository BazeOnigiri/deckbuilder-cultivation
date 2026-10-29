extends GutTest
## Annonce, passage d'un goulot et presages, sur le vrai contenu.

var _content: GameContent


func before_all() -> void:
	_content = GameContent.load_default()


func _run(seed_text: String = "PRESAGE") -> RunState:
	return _content.new_run(RandomNumberGenerator.new(), RunSetup.custom(seed_text, 1, false, ""))


func _omen(id: StringName) -> OmenDefinition:
	var omen := _content.omen_by_id(id)
	assert_not_null(omen, String(id))
	return omen


func _ids(omens: Array[OmenDefinition]) -> Array:
	return omens.map(func(omen: OmenDefinition) -> String: return "" if omen == null else String(omen.id))


func test_annonce_au_depart_puis_affronter() -> void:
	var run := _run()
	watch_signals(run)
	assert_true(run.announce())
	assert_signal_emitted(run, "announced")
	assert_eq(run.status, RunState.Status.ANNOUNCING)
	assert_null(run.current_round)
	assert_true(run.fight())
	assert_eq(run.status, RunState.Status.IN_ROUND)
	assert_not_null(run.current_round)
	assert_false(run.announce(), "pas d'annonce pendant un round")
	assert_false(run.fight())


func test_presages_tires_par_la_graine() -> void:
	var a := _run("GRAINE")
	a.announce()
	var b := _run("graine")
	b.announce()
	assert_eq(_ids(a.omen_offers), _ids(b.omen_offers))
	assert_eq(a.omen_offers.size(), a.progress.current_realm().bottlenecks.size())
	var differs := false
	for seed_text: String in ["A", "B", "C", "D", "E"]:
		var other := _run(seed_text)
		other.announce()
		differs = differs or _ids(other.omen_offers) != _ids(a.omen_offers)
	assert_true(differs, "une autre graine, d'autres presages")


func test_tribulation_sans_presage_et_impossible_a_passer() -> void:
	var run := _run()
	run.announce()
	var bottlenecks := run.progress.current_realm().bottlenecks
	for b: int in bottlenecks.size():
		assert_eq(run.omen_offers[b] == null, bottlenecks[b].constraint != null, "presage seulement si passable")
	while run.progress.current_bottleneck().constraint == null:
		assert_true(run.skip())
	assert_eq(run.status, RunState.Status.ANNOUNCING)
	assert_false(run.can_skip())
	assert_false(run.skip(), "on ne passe pas une tribulation")
	assert_true(run.fight())


func test_passer_avance_sans_round_ni_recompense() -> void:
	var run := _run()
	run.announce()
	var omen := run.current_omen()
	var stones := run.stones
	var stones_omen := omen != null and omen.effect is StonesOmenEffect
	watch_signals(run)
	assert_true(run.skip())
	assert_signal_emitted_with_parameters(run, "skipped", [omen])
	assert_eq(run.progress.bottleneck_number(), 2, "le goulot passe compte pour la progression")
	assert_eq(run.status, RunState.Status.ANNOUNCING, "le goulot suivant s'annonce")
	assert_null(run.current_round)
	assert_eq(run.stats.bottlenecks_skipped, 1)
	assert_eq(run.stats.bottlenecks_cleared, 0, "passe n'est pas vaincu")
	if not stones_omen:
		assert_eq(run.stones, stones, "aucune recompense en pierres")


func test_presages_du_royaume_tires_une_fois() -> void:
	var run := _run()
	run.announce()
	var first := _ids(run.omen_offers)
	run.skip()
	assert_eq(_ids(run.omen_offers), first, "meme royaume, memes presages")


func test_presage_de_pierres() -> void:
	var run := _run()
	var stones := run.stones
	var omen := _omen(&"presage_pluie_de_pierres")
	run.take_omen(omen)
	assert_eq(run.stones, stones + (omen.effect as StonesOmenEffect).amount)
	assert_true(run.pending_omens.is_empty(), "effet immediat")


func test_presage_d_illumination_monte_la_main_la_plus_jouee() -> void:
	var run := _run()
	var omen := _omen(&"presage_illumination")
	var fallback := String((omen.effect as LevelHandOmenEffect).fallback_hand)
	run.take_omen(omen)
	assert_eq(run.hand_levels.level_of(fallback), 2, "aucune main jouee : la main de repli")
	run.stats.record_hand("main_brelan", 10)
	run.take_omen(omen)
	assert_eq(run.hand_levels.level_of("main_brelan"), 2)


func test_presage_de_carte_ajoute_une_carte_amelioree() -> void:
	var run := _run()
	var count := run.cards().size()
	run.take_omen(_omen(&"presage_talisman_inscrit"))
	assert_eq(run.cards().size(), count + 1)
	var newest: CardInstance = run.cards().reduce(func(a: CardInstance, b: CardInstance) -> CardInstance:
		return a if a.uid > b.uid else b)
	assert_not_null(newest.enhancement, "la carte ajoutee est amelioree")


func test_presage_d_artefact_gratuit_a_la_prochaine_boutique() -> void:
	var run := _run()
	run.stones = 0
	run.take_omen(_omen(&"presage_don_celeste"))
	assert_eq(run.pending_omens.size(), 1, "attend la boutique")
	var shop := _content.new_shop(run, RandomNumberGenerator.new())
	assert_true(run.pending_omens.is_empty(), "consomme par la boutique")
	assert_false(shop.offers.is_empty())
	assert_eq(shop.price_of(0), 0)
	assert_true(shop.buy(0), "achat sans pierre")
	assert_eq(run.stones, 0)
	assert_eq(shop.free_artifacts, 0, "un seul artefact gratuit")
	if not shop.offers.is_empty():
		assert_gt(shop.price_of(0), 0)


func test_presage_de_sceau_gratuit() -> void:
	var run := _run()
	run.stones = 0
	run.take_omen(_omen(&"presage_sceau_offert"))
	var shop := _content.new_shop(run, RandomNumberGenerator.new())
	assert_false(shop.pack_offers.is_empty())
	assert_eq(shop.pack_price(0), 0)
	assert_true(shop.buy_pack(0))
	assert_eq(shop.free_packs, 0)


func test_presage_de_relance_gratuite() -> void:
	var run := _run()
	run.stones = 0
	run.take_omen(_omen(&"presage_relance_offerte"))
	var shop := _content.new_shop(run, RandomNumberGenerator.new())
	var cost := shop.reroll_cost
	assert_eq(shop.reroll_price(), 0)
	assert_true(shop.reroll())
	assert_eq(shop.reroll_cost, cost, "la relance gratuite ne fait pas monter le prix")
	assert_eq(shop.reroll_price(), cost)
	assert_false(shop.can_reroll(), "la suivante se paie")


func test_presage_de_marche_ajoute_une_offre() -> void:
	var plain := _run()
	var with_omen := _run()
	with_omen.take_omen(_omen(&"presage_marche_florissant"))
	var count := func(shop: ShopState) -> int:
		return shop.offers.size() + shop.manual_offers.size() + shop.pill_offers.size()
	var before: int = count.call(_content.new_shop(plain, RandomNumberGenerator.new()))
	var shop := _content.new_shop(with_omen, RandomNumberGenerator.new())
	assert_eq(count.call(shop), before + 1)
	assert_eq(count.call(_content.new_shop(with_omen, RandomNumberGenerator.new())), before, "une seule boutique en profite")


func test_presage_d_interets_doubles_au_prochain_goulot() -> void:
	var run := _run()
	run.stones = 25
	run.take_omen(_omen(&"presage_interets_doubles"))
	run.start()
	var rewards: Array[RoundReward] = []
	run.round_won.connect(rewards.append)
	run.current_round.finished.emit(true)
	var normal := RoundReward.compute(run.economy(), 0, 0, 25).interest
	assert_eq(rewards[0].interest, normal * 2)
	assert_true(run.pending_omens.is_empty())
