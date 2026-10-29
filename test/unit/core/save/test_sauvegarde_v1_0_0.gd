extends GutTest
## Vraies sauvegardes ecrites par la v1.0.0 (test/fixtures) : sans heritages, crans d'artefacts, sceaux ni ouverture.
## Elles doivent toujours se relire sans erreur dans le format courant.

const FIXTURE_DIR := "res://test/fixtures/"

var _content: GameContent


func before_all() -> void:
	_content = GameContent.load_default()


func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	return rng


func _load(file_name: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_DIR + file_name))
	assert_true(parsed is Dictionary, file_name)
	return parsed


func test_la_fixture_n_a_pas_les_cles_de_la_v1_1() -> void:
	for file_name: String in ["sauvegarde_v1_0_0_boutique.json", "sauvegarde_v1_0_0_round.json"]:
		var data := _load(file_name)
		for key: String in ["legacies", "legacy_offer", "legacy_offer_realm", "artifact_stacks"]:
			assert_false(data.has(key), key)
	var shop: Dictionary = _load("sauvegarde_v1_0_0_boutique.json")["shop"]
	assert_false(shop.has("packs"))
	assert_false(shop.has("opening"))


func test_boutique_v1_0_0_reprise() -> void:
	var data := _load("sauvegarde_v1_0_0_boutique.json")
	var run := RunSnapshot.restore(data, _content, _rng())
	assert_not_null(run)
	assert_eq(run.status, RunState.Status.BETWEEN_ROUNDS)
	assert_eq(run.stones, 14)
	assert_eq(run.artifacts.size(), 1)
	assert_true(run.legacies.is_empty())
	assert_null(run.legacy_offer)
	assert_true(run.artifact_stacks.is_empty())
	var shop := RunSnapshot.restore_shop(data, run, _content, _rng())
	assert_eq(shop.offers.size(), 1)
	assert_eq(shop.pill_offers.size(), 1)
	assert_eq(shop.reroll_cost, 5)
	assert_null(shop.opening)
	assert_true(shop.pack_offers.is_empty(), "pas de sceaux dans une boutique v1.0.0")
	assert_true(run.next_round())


func test_round_v1_0_0_repris() -> void:
	var data := _load("sauvegarde_v1_0_0_round.json")
	var run := RunSnapshot.restore(data, _content, _rng())
	assert_not_null(run)
	assert_true(RunSnapshot.resume_round(data, run))
	assert_eq(run.stones, 9)
	assert_eq(run.artifacts.size(), 1)
	assert_eq(run.pills.size(), 1)
	var round_state := run.current_round
	assert_eq(round_state.hands_left, data["round"]["hands_left"])
	var to_play: Array[CardInstance] = [round_state.hand()[0]]
	assert_not_null(round_state.play(to_play))
