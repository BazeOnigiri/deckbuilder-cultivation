extends GutTest
## Sauvegarde des ameliorations, auras et talismans des cartes, des auras d'artefact, et migration v1 -> v2.

var _content: GameContent


func before_all() -> void:
	_content = GameContent.load_default()


func _rng(seed_value: int = 7) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _through_json(data: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(data))


func test_cartes_et_artefacts_relus_avec_leurs_ameliorations() -> void:
	var rng := _rng()
	var run := _content.new_run(rng)
	run.progress.advance()
	run.status = RunState.Status.BETWEEN_ROUNDS
	var card: CardInstance = run.cards()[0]
	card.enhancement = _content.modifiers.enhancements[0]
	card.edition = _content.modifiers.card_editions()[0]
	card.talisman = _content.modifiers.talismans[0]
	var artifact_edition: EditionDefinition = _content.modifiers.artifact_editions()[0]
	run.add_artifact(_content.artifacts[0], artifact_edition)
	var data := _through_json(RunSnapshot.capture(run, _content.new_shop(run, rng), rng))
	assert_eq(data["version"], RunSnapshot.VERSION)
	var restored := RunSnapshot.restore(data, _content, _rng(1))
	var again: CardInstance = restored.cards().filter(func(c: CardInstance) -> bool: return c.uid == card.uid)[0]
	assert_eq(again.enhancement, card.enhancement)
	assert_eq(again.edition, card.edition)
	assert_eq(again.talisman, card.talisman)
	assert_eq(restored.artifact_editions[_content.artifacts[0].id], artifact_edition)
	assert_false(restored.pill_pool.is_empty(), "la run relue peut creer des pilules")


func test_modificateur_inconnu_ignore() -> void:
	var rng := _rng()
	var run := _content.new_run(rng)
	run.progress.advance()
	run.status = RunState.Status.BETWEEN_ROUNDS
	var data := _through_json(RunSnapshot.capture(run, _content.new_shop(run, rng), rng))
	data["cards"][0]["enhancement"] = "amelioration_supprimee"
	data["cards"][0]["edition"] = "aura_vide"
	var restored := RunSnapshot.restore(data, _content, _rng(1))
	assert_eq(restored.cards().size(), run.cards().size())
	for card: CardInstance in restored.cards():
		assert_null(card.enhancement)
		assert_null(card.edition, "l'aura du vide ne va pas sur une carte")


func test_migration_v1_vers_v2() -> void:
	var v1 := {"version": 1, "cards": [{"uid": 0, "card": "carte_bois_1", "element": 0, "rank": 1}]}
	var migrated := RunSnapshot.migrate(v1)
	assert_eq(migrated["version"], RunSnapshot.VERSION)
	assert_eq(migrated["cards"][0]["enhancement"], "")
	assert_eq(migrated["artifact_editions"], {})


func test_sauvegardes_v1_0_0_relues_sans_ameliorations() -> void:
	for file_name: String in ["sauvegarde_v1_0_0_boutique.json", "sauvegarde_v1_0_0_round.json"]:
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://test/fixtures/" + file_name))
		var run := RunSnapshot.restore(data, _content, _rng())
		assert_not_null(run, file_name)
		for card: CardInstance in run.cards():
			assert_true(card.modifiers().is_empty(), file_name)
		assert_true(run.artifact_editions.is_empty(), file_name)
