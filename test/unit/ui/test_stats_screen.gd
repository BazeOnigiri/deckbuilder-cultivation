extends GutTest
## Statistiques en rouleau : tuiles des grands chiffres, barres des mains les plus jouees, retour au menu.

const SCREEN := preload("res://ui/stats/stats_screen.tscn")


func test_tuiles_et_retour() -> void:
	var screen: Control = add_child_autofree(SCREEN.instantiate())
	assert_eq(screen.get_node("%Grid").get_child_count(), 4)
	watch_signals(screen)
	screen.get_node("%BackButton").pressed.emit()
	assert_signal_emitted(screen, "back_requested")


func test_barres_des_mains_les_plus_jouees() -> void:
	var screen: Control = SCREEN.instantiate()
	for i: int in 3:
		screen.profile.hands.record("main_paire")
	screen.profile.hands.record("main_brelan")
	add_child_autofree(screen)
	var bars: Array[Node] = screen.get_node("%Bars").get_children()
	assert_eq(bars.size(), 2)
	var top: ScrollTiles.InkBar = bars[0].get_child(1)
	assert_eq(top.fill, 1.0, "la main la plus jouee remplit sa barre")
	assert_almost_eq(bars[1].get_child(1).fill, 1.0 / 3.0, 0.001)


func test_aucune_main_jouee() -> void:
	var screen: Control = add_child_autofree(SCREEN.instantiate())
	assert_eq(screen.get_node("%Bars").get_child_count(), 1)


func test_rouleau_deja_deroule_si_on_reduit_les_animations() -> void:
	var screen: Control = SCREEN.instantiate()
	screen.settings = GameSettings.new()
	screen.settings.reduce_motion = true
	add_child_autofree(screen)
	assert_eq(screen.get_node("%Scroll")._open, 1.0)
