extends GutTest

var _content: GameContent
var _run: RunState


func before_each() -> void:
	_content = GameContent.load_default()
	_run = _content.new_run(RandomNumberGenerator.new())
	_run.start()


func test_pierres() -> void:
	var before := _run.stones
	DebugActions.add_stones(_run)
	assert_eq(_run.stones, before + DebugActions.STONES_GRANT)


func test_artefact_donne_une_seule_fois() -> void:
	assert_true(DebugActions.give_artifact(_run, _content.artifacts[0], _content.shop_rules))
	assert_false(DebugActions.give_artifact(_run, _content.artifacts[0], _content.shop_rules), "doublon")
	assert_eq(_run.artifacts.size(), 1)


func test_artefact_refuse_quand_les_emplacements_sont_pleins() -> void:
	var max_artifacts := _run.shop_rules(_content.shop_rules).max_artifacts
	for artifact: ArtifactDefinition in _content.artifacts:
		DebugActions.give_artifact(_run, artifact, _content.shop_rules)
	assert_eq(_run.artifacts.size(), max_artifacts)


func test_pilule_dans_la_limite() -> void:
	var max_pills := _run.shop_rules(_content.shop_rules).max_pills
	for i: int in max_pills:
		assert_true(DebugActions.give_pill(_run, _content.pills[0], _content.shop_rules))
	assert_false(DebugActions.give_pill(_run, _content.pills[0], _content.shop_rules))
	assert_eq(_run.pills.size(), max_pills)


func test_manuel_monte_la_main() -> void:
	var manual := _content.manuals[0]
	var before := _run.hand_levels.level_of(manual.hand.id)
	DebugActions.give_manual(_run, manual)
	assert_eq(_run.hand_levels.level_of(manual.hand.id), before + 1)


func test_heritage_efface_l_offre_et_refuse_le_doublon() -> void:
	var legacy := _content.legacies[0]
	_run.legacy_offer = legacy
	assert_true(DebugActions.give_legacy(_run, legacy))
	assert_null(_run.legacy_offer)
	assert_false(DebugActions.give_legacy(_run, legacy))
	assert_eq(_run.legacies.size(), 1)


func test_sceau_ouvert_sans_payer_et_un_seul_a_la_fois() -> void:
	var shop := _content.new_shop(_run, RandomNumberGenerator.new())
	var stones := _run.stones
	assert_true(DebugActions.open_pack(shop, _content.packs[0]))
	assert_not_null(shop.opening)
	assert_eq(_run.stones, stones)
	assert_false(DebugActions.open_pack(shop, _content.packs[1]))
	assert_false(DebugActions.open_pack(null, _content.packs[0]))


func test_gagner_le_goulot_donne_la_recompense_et_passe_au_suivant() -> void:
	var cleared := _run.stats.bottlenecks_cleared
	watch_signals(_run)
	assert_true(DebugActions.win_round(_run))
	assert_signal_emitted(_run, "round_won")
	assert_eq(_run.status, RunState.Status.BETWEEN_ROUNDS)
	assert_eq(_run.stats.bottlenecks_cleared, cleared + 1)
	assert_false(DebugActions.win_round(_run), "plus de round en cours")


func test_saut_a_un_goulot_relance_le_round() -> void:
	assert_true(DebugActions.jump_to(_run, 2, 3))
	assert_eq(_run.progress.realm_number(), 2)
	assert_eq(_run.progress.bottleneck_number(), 3)
	assert_eq(_run.status, RunState.Status.IN_ROUND)
	assert_eq(_run.current_round.target_score, _run.progress.current_target())


func test_saut_hors_des_royaumes_refuse() -> void:
	assert_false(DebugActions.jump_to(_run, 99, 1))
	assert_false(DebugActions.jump_to(_run, 1, 0))
	assert_eq(_run.progress.realm_number(), 1)
	assert_eq(_run.progress.bottleneck_number(), 1)


func test_saut_refuse_apres_la_fin_de_la_run() -> void:
	_run.status = RunState.Status.LOST
	assert_false(DebugActions.jump_to(_run, 1, 1))


func test_rencontre_ouverte_seulement_entre_deux_goulots() -> void:
	var event := _content.events[0]
	assert_false(DebugActions.start_event(_run, event), "pas pendant un round")
	DebugActions.win_round(_run)
	assert_true(DebugActions.start_event(_run, event))
	assert_eq(_run.status, RunState.Status.ENCOUNTER)
	assert_eq(_run.current_event, event)


func test_presage_donne() -> void:
	for omen: OmenDefinition in _content.omens:
		var run := _content.new_run(RandomNumberGenerator.new())
		run.start()
		DebugActions.give_omen(run, omen)
		var pending := omen.effect.timing() != OmenEffect.Timing.NOW
		assert_eq(run.pending_omens.has(omen), pending, String(omen.id))


func test_modificateurs_poses_sur_une_carte_de_la_main() -> void:
	var card: CardInstance = _run.current_round.hand()[0]
	var modifiers := _content.modifiers
	assert_true(DebugActions.imbue_card(card, modifiers.enhancements[0]))
	assert_true(DebugActions.imbue_card(card, modifiers.card_editions()[0]))
	assert_true(DebugActions.imbue_card(card, modifiers.talismans[0]))
	assert_eq(card.enhancement, modifiers.enhancements[0])
	assert_eq(card.edition, modifiers.card_editions()[0])
	assert_eq(card.talisman, modifiers.talismans[0])
	assert_false(DebugActions.imbue_card(null, modifiers.talismans[0]))
	for edition: EditionDefinition in modifiers.artifact_editions():
		if not edition.for_cards:
			assert_false(DebugActions.imbue_card(card, edition))
