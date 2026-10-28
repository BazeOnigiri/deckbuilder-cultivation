extends GutTest

var _content: GameContent


func before_all() -> void:
	_content = GameContent.load_default()


func _rng(seed_value: int = 7) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


## Une run entre deux goulots avec un peu de tout : pierres, artefact, pilule, niveau, carte modifiee.
func _run_in_shop(rng: RandomNumberGenerator) -> RunState:
	var run := _content.new_run(rng)
	run.progress.advance()
	run.status = RunState.Status.BETWEEN_ROUNDS
	run.stones = 17
	run.artifacts.append(_content.artifacts[0])
	run.pills.append(_content.pills[0])
	run.hand_levels.level_up("main_paire")
	run.stats.record_hand("main_paire", 120)
	var card: CardInstance = run.cards()[0]
	card.element = Element.Type.EAU
	card.rank = 9
	return run


## Une run en plein round, apres une defausse et une main jouee.
func _run_in_round(rng: RandomNumberGenerator) -> RunState:
	var run := _content.new_run(rng)
	run.start()
	var to_discard: Array[CardInstance] = [run.current_round.hand()[0]]
	run.current_round.discard(to_discard)
	var to_play: Array[CardInstance] = [run.current_round.hand()[0]]
	run.current_round.play(to_play)
	return run


## Simule l'aller-retour par le disque : les nombres reviennent en float, comme dans un vrai fichier.
func _through_json(data: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(data))


func test_aller_retour_complet() -> void:
	var rng := _rng()
	var run := _run_in_shop(rng)
	var modified: CardInstance = run.cards()[0]
	var data := _through_json(RunSnapshot.capture(run, _content.new_shop(run, rng), rng))
	var restored := RunSnapshot.restore(data, _content, _rng(999))
	assert_not_null(restored)
	assert_eq(restored.status, RunState.Status.BETWEEN_ROUNDS)
	assert_eq(restored.stones, 17)
	assert_eq(restored.artifacts, run.artifacts)
	assert_eq(restored.pills, run.pills)
	assert_eq(restored.hand_levels.level_of("main_paire"), 2)
	assert_eq(restored.stats.hands.count_of("main_paire"), 1)
	assert_eq(restored.progress.current_target(), run.progress.current_target())
	assert_eq(restored.cards().size(), run.cards().size())
	var same: Array = restored.cards().filter(func(c: CardInstance) -> bool: return c.uid == modified.uid)
	assert_eq(same[0].element, Element.Type.EAU)
	assert_eq(same[0].rank, 9)


func test_la_run_restauree_reprend_au_goulot_sauvegarde() -> void:
	var rng := _rng()
	var run := _run_in_shop(rng)
	var data := _through_json(RunSnapshot.capture(run, _content.new_shop(run, rng), rng))
	var restored := RunSnapshot.restore(data, _content, _rng())
	assert_false(RunSnapshot.resume_round(data, restored))
	assert_true(restored.next_round())
	assert_eq(restored.current_round.target_score, run.progress.current_target())
	assert_eq(restored.current_round.hand().size(), _content.round_rules.hand_size)


func test_etat_de_la_rng_conserve_exactement() -> void:
	var rng := _rng()
	var run := _run_in_shop(rng)
	var data := _through_json(RunSnapshot.capture(run, _content.new_shop(run, rng), rng))
	var expected: int = rng.randi()
	var restored_rng := _rng(999)
	RunSnapshot.restore(data, _content, restored_rng)
	assert_eq(restored_rng.randi(), expected)


func test_offres_de_boutique_conservees_sans_nouveau_tirage() -> void:
	var rng := _rng()
	var run := _run_in_shop(rng)
	var shop := _content.new_shop(run, rng)
	shop.reroll_cost = 8
	var data := _through_json(RunSnapshot.capture(run, shop, rng))
	var restored_rng := _rng()
	var restored := RunSnapshot.restore(data, _content, restored_rng)
	var state_before: int = restored_rng.state
	var restored_shop := RunSnapshot.restore_shop(data, restored, _content, restored_rng)
	assert_eq(restored_rng.state, state_before)
	assert_eq(restored_shop.offers, shop.offers)
	assert_eq(restored_shop.manual_offers, shop.manual_offers)
	assert_eq(restored_shop.pill_offers, shop.pill_offers)
	assert_eq(restored_shop.reroll_cost, 8)


func test_round_en_cours_restaure_a_l_identique() -> void:
	var rng := _rng()
	var run := _run_in_round(rng)
	var data := _through_json(RunSnapshot.capture(run, null, rng))
	var restored_rng := _rng(999)
	var restored := RunSnapshot.restore(data, _content, restored_rng)
	assert_true(RunSnapshot.resume_round(data, restored))
	assert_eq(restored.status, RunState.Status.IN_ROUND)
	assert_eq(restored.current_round.score, run.current_round.score)
	assert_eq(restored.current_round.hands_left, run.current_round.hands_left)
	assert_eq(restored.current_round.discards_left, run.current_round.discards_left)
	assert_eq(restored.current_round.target_score, run.current_round.target_score)
	assert_eq(restored.piles(), run.piles())
	assert_eq(restored_rng.randi(), rng.randi())


func test_round_repris_se_joue_normalement() -> void:
	var rng := _rng()
	var run := _run_in_round(rng)
	var data := _through_json(RunSnapshot.capture(run, null, rng))
	var restored := RunSnapshot.restore(data, _content, _rng())
	RunSnapshot.resume_round(data, restored)
	var hands_before: int = restored.current_round.hands_left
	var to_play: Array[CardInstance] = [restored.current_round.hand()[0]]
	assert_not_null(restored.current_round.play(to_play))
	assert_eq(restored.current_round.hands_left, hands_before - 1)
	assert_eq(restored.stats.hands.total(), 2)


func test_carte_hors_des_piles_remise_dans_la_pioche() -> void:
	var rng := _rng()
	var run := _run_in_round(rng)
	var data := _through_json(RunSnapshot.capture(run, null, rng))
	var draw: Array = data["piles"]["draw"]
	draw.remove_at(0)
	draw.append(draw[0])
	var restored := RunSnapshot.restore(data, _content, _rng())
	assert_eq(restored.cards().size(), run.cards().size())


func test_sauvegardes_inutilisables_refusees() -> void:
	var rng := _rng()
	var run := _run_in_shop(rng)
	var good := _through_json(RunSnapshot.capture(run, _content.new_shop(run, rng), rng))
	assert_null(RunSnapshot.restore({}, _content, _rng()))
	var future := good.duplicate(true)
	future["version"] = RunSnapshot.VERSION + 1
	assert_null(RunSnapshot.restore(future, _content, _rng()))
	var bad_progress := good.duplicate(true)
	bad_progress["progress"] = {"realm": 99, "bottleneck": 0}
	assert_null(RunSnapshot.restore(bad_progress, _content, _rng()))
	var no_cards := good.duplicate(true)
	no_cards["cards"] = []
	assert_null(RunSnapshot.restore(no_cards, _content, _rng()))
	var bad_rng := good.duplicate(true)
	bad_rng["rng_state"] = 12.5
	assert_null(RunSnapshot.restore(bad_rng, _content, _rng()))


func test_contenu_inconnu_ignore() -> void:
	var rng := _rng()
	var run := _run_in_shop(rng)
	var data := _through_json(RunSnapshot.capture(run, _content.new_shop(run, rng), rng))
	data["artifacts"] = ["artefact_supprime", String(_content.artifacts[0].id)]
	var restored := RunSnapshot.restore(data, _content, _rng())
	assert_eq(restored.artifacts.size(), 1)


func test_capture_selon_l_etat_de_la_run() -> void:
	var run := _content.new_run(_rng())
	assert_false(RunSnapshot.can_capture(run))
	run.start()
	assert_true(RunSnapshot.can_capture(run))
	run.status = RunState.Status.LOST
	assert_false(RunSnapshot.can_capture(run))


## Bug : resume_round et restore_shop lisaient la sauvegarde brute, sans migration.
## Ici une fausse version 0 rangeait les offres sous « objets » et le round sous « manche ».
func test_boutique_et_round_lus_apres_migration() -> void:
	RunSnapshot.migrations = {0: func(old: Dictionary) -> Dictionary:
		var save := old.duplicate(true)
		if save.has("manche"):
			save["round"] = save["manche"]
		if save.has("shop"):
			save["shop"]["artifacts"] = save["shop"]["objets"]
		return save}
	var rng := _rng()
	var run := _run_in_shop(rng)
	var shop := _content.new_shop(run, rng)
	var data := _through_json(RunSnapshot.capture(run, shop, rng))
	data["version"] = 0
	data["shop"]["objets"] = data["shop"]["artifacts"]
	data["shop"].erase("artifacts")
	var restored := RunSnapshot.restore(data, _content, _rng())
	assert_eq(RunSnapshot.restore_shop(data, restored, _content, _rng()).offers, shop.offers)
	var playing := _run_in_round(_rng())
	var round_data := _through_json(RunSnapshot.capture(playing, null, rng))
	round_data["version"] = 0
	round_data["manche"] = round_data["round"]
	round_data.erase("round")
	assert_true(RunSnapshot.resume_round(round_data, RunSnapshot.restore(round_data, _content, _rng())))
	RunSnapshot.migrations = {}
