extends GutTest
## Statistiques en rouleau : une ligne par statistique, retour au menu.

const SCREEN := preload("res://ui/stats/stats_screen.tscn")


func test_une_ligne_par_statistique_et_retour() -> void:
	var screen: Control = add_child_autofree(SCREEN.instantiate())
	assert_eq(screen.get_node("%Grid").get_child_count(), 7)
	watch_signals(screen)
	screen.get_node("%BackButton").pressed.emit()
	assert_signal_emitted(screen, "back_requested")
