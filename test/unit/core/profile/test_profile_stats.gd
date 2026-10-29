extends GutTest

const PATH := "user://test_profile_stats.json"


func after_each() -> void:
	SaveStorage.new(PATH).delete()


func test_aller_retour_sur_disque() -> void:
	var storage := SaveStorage.new(PATH)
	var stats := ProfileStats.new()
	stats.runs_started = 3
	stats.runs_won = 1
	stats.best_realm = 2
	stats.best_hand_score = 840
	stats.hands.counts = {"main_paire": 12, "main_brelan": 3}
	assert_true(stats.save_to(storage))
	var loaded := ProfileStats.load_from(storage)
	assert_eq(loaded.to_dict(), stats.to_dict())


func test_valeurs_invalides_remises_a_zero() -> void:
	var stats := ProfileStats.from_dict({"runs_started": "beaucoup", "runs_won": - 5, "best_realm": 2.0})
	assert_eq(stats.runs_started, 0)
	assert_eq(stats.runs_won, 0)
	assert_eq(stats.best_realm, 2)
	assert_eq(stats.best_hand_score, 0)
	assert_eq(stats.hands.total(), 0)


func test_aide_proposee_une_fois_a_la_premiere_partie() -> void:
	var stats := ProfileStats.new()
	assert_true(stats.should_offer_help())
	stats.help_offered = true
	assert_false(stats.should_offer_help())
	assert_true(ProfileStats.from_dict(stats.to_dict()).help_offered, "sauvegarde")
	var played := ProfileStats.new()
	played.runs_started = 1
	assert_false(played.should_offer_help(), "profil qui a deja joue")


func test_ancien_profil_sans_le_champ_aide() -> void:
	assert_false(ProfileStats.from_dict({"runs_started": 2}).help_offered)
	assert_false(ProfileStats.from_dict({"help_offered": "oui"}).help_offered)


func _game(played_at: int) -> GameRecord:
	var game := GameRecord.new()
	game.played_at = played_at
	game.won = true
	game.realm_id = "royaume_fondations"
	game.bottleneck_id = "goulot_grand"
	game.bottlenecks_cleared = 4
	game.best_hand_score = 900
	game.best_hand_id = "main_paire"
	game.favorite_hand_id = "main_brelan"
	game.artifacts = ["artefact_a", "artefact_b"]
	game.legacies = ["heritage_a"]
	game.seed_text = "123"
	return game


func test_contenu_vu_une_seule_fois() -> void:
	var stats := ProfileStats.new()
	assert_false(stats.is_seen("artifact", &"a"))
	assert_true(stats.mark_seen("artifact", &"a"))
	assert_false(stats.mark_seen("artifact", &"a"), "deja vu")
	assert_true(stats.is_seen("artifact", &"a"))
	assert_false(stats.is_seen("pill", &"a"), "par categorie")


func test_historique_borne_a_n_parties() -> void:
	var stats := ProfileStats.new()
	for i: int in 5:
		stats.add_game(_game(i), 3)
	assert_eq(stats.games.size(), 3)
	assert_eq(stats.games[0].played_at, 2, "les plus anciennes sortent")
	assert_eq(stats.games[2].played_at, 4)


func test_stats_par_contenu() -> void:
	var stats := ProfileStats.new()
	for i: int in 3:
		stats.record_purchase(&"epee")
	stats.record_purchase(&"bouclier")
	stats.record_purchase(&"arc")
	stats.record_purchase(&"arc")
	assert_eq(stats.top_purchases(2), ["epee", "arc"], "par achats, puis par id")
	stats.record_tribulation(&"foudre", true)
	stats.record_tribulation(&"foudre", false)
	stats.record_tribulation(&"foudre", false)
	assert_eq(stats.tribulation_wins(&"foudre"), 1)
	assert_eq(stats.tribulation_losses(&"foudre"), 2)
	assert_eq(stats.tribulation_wins(&"inconnue"), 0)


func test_aller_retour_des_champs_de_la_version_2() -> void:
	var storage := SaveStorage.new(PATH)
	var stats := ProfileStats.new()
	stats.mark_seen("artifact", &"a")
	stats.mark_seen("legacy", &"h")
	stats.record_purchase(&"a")
	stats.record_tribulation(&"foudre", true)
	stats.add_game(_game(1700000000), 20)
	assert_true(stats.save_to(storage))
	var loaded := ProfileStats.load_from(storage)
	assert_eq(loaded.to_dict(), stats.to_dict())
	assert_true(loaded.is_seen("legacy", &"h"))
	assert_eq(loaded.games[0].artifacts, ["artefact_a", "artefact_b"])
	assert_eq(loaded.games[0].seed_text, "123")


func test_migration_d_un_profil_de_version_1() -> void:
	var storage := SaveStorage.new(PATH)
	storage.save({"version": 1, "stats": {"runs_started": 7, "runs_won": 2, "best_realm": 3, "best_hand_score": 500,
		"hand_counts": {"main_paire": 4}}})
	var loaded := ProfileStats.load_from(storage)
	assert_eq(loaded.runs_started, 7)
	assert_eq(loaded.runs_won, 2)
	assert_eq(loaded.hands.count_of("main_paire"), 4)
	assert_true(loaded.seen.is_empty())
	assert_true(loaded.games.is_empty())
	assert_true(loaded.artifact_purchases.is_empty())
	assert_true(loaded.tribulations.is_empty())
	assert_true(loaded.save_to(storage))
	assert_eq(storage.load_data()["version"], ProfileStats.VERSION)


func test_champs_de_la_version_2_abimes_ignores() -> void:
	var stats := ProfileStats.from_dict({"seen": {"artifact": ["a", 3], "pill": "pas une liste"}, "artifact_purchases": {"a": - 2, "b": 3},
		"tribulations": {"x": {"won": "oui", "lost": 2}, "y": 5}, "games": [{"won": "oui", "artifacts": [1, "z"]}, 12]})
	assert_true(stats.is_seen("artifact", &"a"))
	assert_false(stats.is_seen("pill", &"a"))
	assert_eq(stats.purchases_of(&"a"), 0)
	assert_eq(stats.purchases_of(&"b"), 3)
	assert_eq(stats.tribulation_losses(&"x"), 2)
	assert_eq(stats.tribulation_wins(&"x"), 0)
	assert_false(stats.tribulations.has("y"))
	assert_eq(stats.games.size(), 1)
	assert_false(stats.games[0].won)
	assert_eq(stats.games[0].artifacts, ["z"])
