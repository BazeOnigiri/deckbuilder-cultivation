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