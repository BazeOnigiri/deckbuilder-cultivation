extends GutTest
## Sauvegarde v3 : annonce du goulot, presages tires et en attente, presages d'une boutique. Migration depuis la v2.

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


func _ids(omens: Array[OmenDefinition]) -> Array:
	return omens.map(func(omen: OmenDefinition) -> String: return "" if omen == null else String(omen.id))


func _load(file_name: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_DIR + file_name))
	assert_true(parsed is Dictionary, file_name)
	return parsed


func test_reprise_sur_l_annonce() -> void:
	var rng := _rng()
	var run := _content.new_run(rng, RunSetup.custom("ANNONCE", 1, false, ""))
	run.announce()
	run.skip()
	run.take_omen(_content.omen_by_id(&"presage_don_celeste"))
	assert_true(RunSnapshot.can_capture(run))
	var data := _through_json(RunSnapshot.capture(run, null, rng))
	assert_eq(int(data["version"]), 3)
	var restored := RunSnapshot.restore(data, _content, _rng(1))
	assert_not_null(restored)
	assert_false(RunSnapshot.resume_round(data, restored))
	assert_true(RunSnapshot.resume_announce(data, restored), "on reprend sur l'annonce")
	assert_eq(restored.status, RunState.Status.ANNOUNCING)
	assert_eq(restored.progress.bottleneck_number(), 2)
	assert_eq(_ids(restored.omen_offers), _ids(run.omen_offers), "memes presages proposes, pas de nouveau tirage")
	assert_eq(_ids(restored.pending_omens), _ids(run.pending_omens))
	assert_has(_ids(restored.pending_omens), "presage_don_celeste")
	assert_eq(restored.stats.bottlenecks_skipped, 1)
	assert_true(restored.fight())


func test_boutique_garde_ses_presages() -> void:
	var rng := _rng()
	var run := _content.new_run(rng)
	run.take_omen(_content.omen_by_id(&"presage_marche_florissant"))
	run.take_omen(_content.omen_by_id(&"presage_relance_offerte"))
	run.status = RunState.Status.BETWEEN_ROUNDS
	var shop := _content.new_shop(run, rng)
	var data := _through_json(RunSnapshot.capture(run, shop, rng))
	var restored := RunSnapshot.restore(data, _content, _rng(1))
	var again := RunSnapshot.restore_shop(data, restored, _content, _rng(1))
	assert_eq(again.free_rerolls, 1)
	assert_eq(again.bonus_modifiers.size(), 1)
	assert_eq(again.bonus_modifiers[0].property, &"offer_count")
	assert_eq(again.reroll_price(), 0)


func test_migration_v2_vers_v3() -> void:
	var migrated := RunSnapshot.migrate({"version": 2, "cards": []})
	assert_eq(migrated["version"], 3)
	assert_eq(migrated["omens"], [])
	assert_eq(migrated["omen_offers"], [])
	assert_eq(migrated["omen_offers_realm"], 0)


func test_fixtures_v2_relues() -> void:
	var shop_data := _load("sauvegarde_v1_2_0_boutique.json")
	assert_eq(int(shop_data["version"]), 2)
	assert_false(shop_data.has("omens"))
	var run := RunSnapshot.restore(shop_data, _content, _rng())
	assert_not_null(run)
	assert_false(RunSnapshot.resume_announce(shop_data, run))
	assert_true(run.pending_omens.is_empty())
	var shop := RunSnapshot.restore_shop(shop_data, run, _content, _rng())
	assert_eq(shop.free_artifacts, 0)
	assert_true(run.announce(), "apres la boutique, le goulot suivant s'annonce")
	assert_false(run.omen_offers.is_empty(), "presages tires a la premiere annonce")
	var round_data := _load("sauvegarde_v1_2_0_round.json")
	var in_round := RunSnapshot.restore(round_data, _content, _rng())
	assert_not_null(in_round)
	assert_true(RunSnapshot.resume_round(round_data, in_round))
	assert_eq(in_round.status, RunState.Status.IN_ROUND)
