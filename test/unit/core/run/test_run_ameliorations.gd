extends GutTest
## Ameliorations, talismans et auras d'artefact pendant une vraie run (contenu du jeu).

var _content: GameContent


func before_all() -> void:
	_content = GameContent.load_default()


func _run(seed_value: int = 3) -> RunState:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var run := _content.new_run(rng)
	run.start()
	return run


func _enhancement(id: StringName) -> EnhancementDefinition:
	for enhancement: EnhancementDefinition in _content.modifiers.enhancements:
		if enhancement.id == id:
			return enhancement
	return null


func _talisman(id: StringName) -> TalismanDefinition:
	for talisman: TalismanDefinition in _content.modifiers.talismans:
		if talisman.id == id:
			return talisman
	return null


func _first(run: RunState) -> Array[CardInstance]:
	var cards: Array[CardInstance] = [run.current_round.hand()[0]]
	return cards


func test_carte_de_jade_brisee_quitte_le_paquet() -> void:
	var run := _run()
	var played := _first(run)
	var jade := _enhancement(&"amelioration_jade").duplicate() as EnhancementDefinition
	jade.break_chance = 1.0
	played[0].enhancement = jade
	var context := run.current_round.play(played)
	assert_eq(context.broken, played)
	assert_false(run.cards().has(played[0]))


func test_carte_de_jade_meme_graine_meme_sort() -> void:
	var outcomes: Array = []
	for attempt: int in 2:
		var run := _run(11)
		var played: Array[CardInstance] = run.current_round.hand().slice(0, 5)
		for card: CardInstance in played:
			card.enhancement = _enhancement(&"amelioration_jade")
		var context := run.current_round.play(played)
		outcomes.append(context.broken.map(func(card: CardInstance) -> int: return card.uid))
	assert_eq(outcomes[0], outcomes[1])


func test_carte_de_tresor_donne_des_pierres() -> void:
	var run := _run()
	var before := run.stones
	var played := _first(run)
	played[0].enhancement = _enhancement(&"amelioration_tresor")
	run.current_round.play(played)
	assert_eq(run.stones, before + _enhancement(&"amelioration_tresor").scored_stones)


func test_talisman_d_eveil_monte_la_main_jouee() -> void:
	var run := _run()
	var played := _first(run)
	played[0].talisman = _talisman(&"talisman_eveil")
	var result := run.current_round.preview(played)
	run.current_round.play(played)
	assert_eq(run.hand_levels.level_of(result.definition.id), 2)


func test_talisman_d_alchimie_cree_une_pilule_a_la_defausse() -> void:
	var run := _run()
	var discarded := _first(run)
	discarded[0].talisman = _talisman(&"talisman_alchimie")
	assert_true(run.current_round.discard(discarded))
	assert_eq(run.pills.size(), 1)


func test_talisman_d_alchimie_sans_place_ne_cree_rien() -> void:
	var run := _run()
	for i: int in run.max_pills():
		run.pills.append(_content.pills[0])
	var discarded := _first(run)
	discarded[0].talisman = _talisman(&"talisman_alchimie")
	run.current_round.discard(discarded)
	assert_eq(run.pills.size(), run.max_pills())


func test_talisman_de_fortune_paye_en_fin_de_goulot() -> void:
	var run := _run()
	var held: CardInstance = run.current_round.hand()[1]
	held.talisman = _talisman(&"talisman_fortune")
	run.current_round.target_score = 1
	watch_signals(run)
	run.current_round.play(_first(run))
	var reward: RoundReward = get_signal_parameters(run, "round_won")[0]
	assert_eq(reward.cards, _talisman(&"talisman_fortune").held_stones)


func test_aura_d_artefact_joue_a_chaque_main() -> void:
	var run := _run()
	var mist: EditionDefinition = _content.modifiers.edition_by_id("aura_brume")
	run.add_artifact(_content.artifacts[0], mist)
	var result := run.current_round.preview(_first(run))
	var triggered := ArtifactResolver.triggered_for(run.artifacts, result, [], {}, run.artifact_editions)
	assert_true(triggered.any(func(effect: TriggeredEffect) -> bool: return effect.effect == mist.score_effect))


func test_aura_du_vide_ne_prend_pas_d_emplacement_et_part_a_la_vente() -> void:
	var run := _run()
	run.add_artifact(_content.artifacts[0], _content.modifiers.edition_by_id("aura_vide"))
	run.add_artifact(_content.artifacts[1])
	assert_eq(run.artifact_slots_used(), 1)
	assert_true(run.sell_artifact(0))
	assert_true(run.artifact_editions.is_empty())


func test_pilule_pose_amelioration_aura_et_talisman() -> void:
	for pill: PillDefinition in _content.pills:
		var imbue := pill.effect as ImbuePillEffect
		if imbue == null:
			continue
		var run := _run()
		run.pills.append(pill)
		var cards := _first(run)
		assert_true(run.use_pill(run.pills.size() - 1, cards), String(pill.id))
		if imbue.enhancement != null:
			assert_eq(cards[0].enhancement, imbue.enhancement, String(pill.id))
		if imbue.edition != null:
			assert_eq(cards[0].edition, imbue.edition, String(pill.id))
		if imbue.talisman != null:
			assert_eq(cards[0].talisman, imbue.talisman, String(pill.id))


func test_copie_garde_les_ameliorations() -> void:
	var run := _run()
	var cards := _first(run)
	cards[0].enhancement = _enhancement(&"amelioration_esprit")
	CopyPillEffect.new().apply(cards, null, run)
	var copies := run.cards().filter(func(card: CardInstance) -> bool: return card.uid != cards[0].uid and card.data == cards[0].data)
	assert_eq(copies.size(), 1)
	assert_eq(copies[0].enhancement, cards[0].enhancement)
