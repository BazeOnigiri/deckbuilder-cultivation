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


func test_artefacts_les_plus_achetes() -> void:
	var content := GameContent.load_default()
	var screen: Control = SCREEN.instantiate()
	screen.content = content
	for i: int in 4:
		screen.profile.record_purchase(content.artifacts[0].id)
	screen.profile.record_purchase(content.artifacts[1].id)
	screen.profile.record_purchase(&"artefact_disparu")
	add_child_autofree(screen)
	var bars: Array[Node] = screen.get_node("%Purchases").get_children()
	assert_eq(bars.size(), 2, "un artefact retire du jeu est ignore")
	assert_eq(bars[0].get_child(1).fill, 1.0)
	assert_almost_eq(bars[1].get_child(1).fill, 0.25, 0.001)


func test_taux_de_reussite_par_tribulation() -> void:
	var content := GameContent.load_default()
	var tribulation := Compendium.new(content, ProfileStats.new()).entries(Compendium.Kind.TRIBULATION)[0]
	var screen: Control = SCREEN.instantiate()
	screen.content = content
	screen.profile.record_tribulation(tribulation.id, true)
	screen.profile.record_tribulation(tribulation.id, false)
	add_child_autofree(screen)
	var rows: Array[Node] = screen.get_node("%Tribulations").get_children()
	assert_eq(rows.size(), 1, "seules les tribulations affrontees")
	var texts := rows[0].find_children("*", "Label", true, false).map(func(label: Label) -> String: return label.text)
	assert_has(texts, tr("UI_STATS_TRIBULATION_RATE") % [50, 1, 2])


func test_historique_en_rouleau_une_entree_par_partie_la_plus_recente_en_haut() -> void:
	var content := GameContent.load_default()
	var screen: Control = SCREEN.instantiate()
	screen.content = content
	screen.settings = GameSettings.new()
	screen.settings.reduce_motion = true
	for i: int in 2:
		var game := GameRecord.new()
		game.played_at = 1000 * (i + 1)
		game.artifacts = [String(content.artifacts[0].id), "artefact_disparu"]
		game.legacies = [String(content.legacies[0].id)]
		screen.profile.add_game(game, 20)
	add_child_autofree(screen)
	screen.get_node("%HistoryButton").pressed.emit()
	var overlay: ScrollOverlay = null
	for child: Node in screen.get_children():
		if child is ScrollOverlay:
			overlay = child
	assert_not_null(overlay)
	var slots := overlay.find_children("*", "ItemSlot", true, false)
	assert_eq(slots.size(), 4, "artefact et heritage de chaque partie, le contenu retire est ignore")
	var dates := overlay.find_children("*", "Label", true, false).filter(
		func(label: Label) -> bool: return label.text.contains(" - "))
	assert_eq(dates[0].text.substr(0, 16), GameHistory.date_text(2000), "la plus recente d'abord")


func test_historique_vide() -> void:
	var scroll := GameHistory.build(ProfileStats.new(), GameContent.load_default())
	add_child_autofree(scroll)
	assert_eq(scroll.find_children("*", "ItemSlot", true, false).size(), 0)
	assert_eq(scroll.find_children("*", "Label", true, false).size(), 1)


func test_texte_du_meilleur_coup_avec_sa_main() -> void:
	var content := GameContent.load_default()
	assert_eq(GameHistory.best_hand_text(900, "", content.hands), "900")
	assert_eq(GameHistory.best_hand_text(900, content.hands[0].id, content.hands), "900 (%s)" % tr(content.hands[0].name_key))
