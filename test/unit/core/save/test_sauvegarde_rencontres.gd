extends GutTest
## Sauvegarde v4 : rencontre en cours (avant et apres le choix), rencontres vecues, main de moins. Migration v3.

const FIXTURE_DIR := "res://test/fixtures/"

var _content: GameContent


func before_all() -> void:
	_content = GameContent.load_default()


func _rng(seed_value: int = 5) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _through_json(data: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(data))


func _load(file_name: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_DIR + file_name))
	assert_true(parsed is Dictionary, file_name)
	return parsed


## Run dans une rencontre du contenu, entre deux goulots.
func _encounter(rng: RandomNumberGenerator) -> RunState:
	var run := _content.new_run(rng, RunSetup.custom("SAUVE", 1, false, ""))
	run.status = RunState.Status.BETWEEN_ROUNDS
	run.start_event(_content.event_by_id(&"evenement_marche_noir"))
	return run


func test_reprise_avant_le_choix() -> void:
	var rng := _rng()
	var run := _encounter(rng)
	assert_true(RunSnapshot.can_capture(run))
	var data := _through_json(RunSnapshot.capture(run, null, rng))
	assert_eq(int(data["version"]), 4)
	var restored := RunSnapshot.restore(data, _content, _rng(1))
	assert_false(RunSnapshot.resume_round(data, restored))
	assert_false(RunSnapshot.resume_announce(data, restored))
	assert_true(RunSnapshot.resume_event(data, restored, _content))
	assert_eq(restored.status, RunState.Status.ENCOUNTER)
	assert_eq(restored.current_event.id, &"evenement_marche_noir")
	assert_eq(restored.event_choice, -1)
	assert_true(restored.can_choose(0))


func test_reprise_apres_le_choix_sans_le_rejouer() -> void:
	var rng := _rng()
	var run := _encounter(rng)
	run.stones = 10
	assert_true(run.choose(0))
	var data := _through_json(RunSnapshot.capture(run, null, rng))
	var restored := RunSnapshot.restore(data, _content, _rng(1))
	assert_true(RunSnapshot.resume_event(data, restored, _content))
	assert_eq(restored.event_choice, 0)
	assert_eq(restored.event_outcome, run.event_outcome)
	assert_eq(restored.stones, run.stones, "cout deja paye, pas une seconde fois")
	assert_eq(restored.pills.size(), run.pills.size())
	assert_false(restored.can_choose(1))
	assert_not_null(restored.current_outcome())
	assert_true(restored.end_event())
	assert_eq(restored.status, RunState.Status.ANNOUNCING)


func test_rencontres_vecues_et_main_de_moins_gardees() -> void:
	var rng := _rng()
	var run := _encounter(rng)
	run.hand_penalty = 1
	run.choose(run.current_event.choices.size() - 1)
	run.end_event()
	var data := _through_json(RunSnapshot.capture(run, null, rng))
	var restored := RunSnapshot.restore(data, _content, _rng(1))
	assert_eq(restored.seen_events, run.seen_events)
	assert_eq(restored.event_realm, 1)
	assert_eq(restored.hand_penalty, 1)


func test_rencontre_retiree_du_jeu_annonce_le_goulot() -> void:
	var rng := _rng()
	var data := _through_json(RunSnapshot.capture(_encounter(rng), null, rng))
	data["event"]["id"] = "evenement_disparu"
	var restored := RunSnapshot.restore(data, _content, _rng(1))
	assert_true(RunSnapshot.resume_event(data, restored, _content))
	assert_eq(restored.status, RunState.Status.ANNOUNCING)


func test_choix_hors_bornes_reprend_avant_le_choix() -> void:
	var rng := _rng()
	var data := _through_json(RunSnapshot.capture(_encounter(rng), null, rng))
	data["event"]["choice"] = 9
	var restored := RunSnapshot.restore(data, _content, _rng(1))
	assert_true(RunSnapshot.resume_event(data, restored, _content))
	assert_eq(restored.event_choice, -1)


func test_migration_v3_vers_v4() -> void:
	var migrated := RunSnapshot.migrate({"version": 3, "cards": []})
	assert_eq(migrated["version"], 4)
	assert_eq(migrated["seen_events"], [])
	assert_eq(migrated["event_realm"], 0)
	assert_eq(migrated["hand_penalty"], 0)


func test_fixtures_v3_relues() -> void:
	var shop_data := _load("sauvegarde_v1_3_0_boutique.json")
	assert_eq(int(shop_data["version"]), 3)
	assert_false(shop_data.has("seen_events"))
	var run := RunSnapshot.restore(shop_data, _content, _rng())
	assert_not_null(run)
	assert_false(RunSnapshot.resume_event(shop_data, run, _content))
	assert_true(run.seen_events.is_empty())
	assert_eq(run.hand_penalty, 0)
	RunSnapshot.restore_shop(shop_data, run, _content, _rng())
	assert_true(run.leave_shop(), "en quittant la boutique : une rencontre ou l'annonce")
	var announce_data := _load("sauvegarde_v1_3_0_annonce.json")
	var announced := RunSnapshot.restore(announce_data, _content, _rng())
	assert_true(RunSnapshot.resume_announce(announce_data, announced))
	var round_data := _load("sauvegarde_v1_3_0_round.json")
	var in_round := RunSnapshot.restore(round_data, _content, _rng())
	assert_true(RunSnapshot.resume_round(round_data, in_round))
	assert_eq(in_round.status, RunState.Status.IN_ROUND)
