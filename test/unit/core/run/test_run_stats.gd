extends GutTest
## Statistiques d'une run : le meilleur coup retient aussi sa main, sauvegardee avec le reste.


func test_meilleur_coup_retient_sa_main() -> void:
	var stats := RunStats.new()
	stats.record_hand("main_paire", 100)
	stats.record_hand("main_brelan", 400)
	stats.record_hand("main_souffle", 50)
	assert_eq(stats.best_hand_score, 400)
	assert_eq(stats.best_hand_id, "main_brelan")


func test_aller_retour_avec_la_main_du_meilleur_coup() -> void:
	var stats := RunStats.new()
	stats.record_hand("main_paire", 100)
	assert_eq(RunStats.from_dict(stats.to_dict()).best_hand_id, "main_paire")


func test_ancienne_sauvegarde_sans_main_du_meilleur_coup() -> void:
	var stats := RunStats.from_dict({"best_hand_score": 250})
	assert_eq(stats.best_hand_score, 250)
	assert_eq(stats.best_hand_id, "")
	assert_eq(RunStats.from_dict({"best_hand_id": 12}).best_hand_id, "", "mauvais type")
