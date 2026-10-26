extends GutTest
## Test de fumee de l'ecran : la scene se charge, se branche a la logique et affiche une main.

const SCREEN := preload("res://ui/round/round_screen.tscn")
const RULES_PATH := "res://content/rules/regles_base.tres"


func test_ecran_affiche_une_main_complete() -> void:
	var screen: Control = add_child_autofree(SCREEN.instantiate())
	var rules: RoundRules = load(RULES_PATH)
	assert_eq(screen.get_node("%HandRow").get_child_count(), rules.hand_size)


func test_boutons_desactives_sans_selection() -> void:
	var screen: Control = add_child_autofree(SCREEN.instantiate())
	assert_true(screen.get_node("%PlayButton").disabled)
	assert_true(screen.get_node("%DiscardButton").disabled)

func _resume(data: Dictionary) -> Control:
	var instance := SCREEN.instantiate()
	instance.resume_data = JSON.parse_string(JSON.stringify(data))
	return add_child_autofree(instance)


## Reprise dans la boutique : pas de round en cours, l'ecran ne doit pas planter.
func test_reprise_dans_la_boutique() -> void:
	var content := GameContent.load_default()
	var rng := RandomNumberGenerator.new()
	var run := content.new_run(rng)
	run.status = RunState.Status.BETWEEN_ROUNDS
	var screen := _resume(RunSnapshot.capture(run, content.new_shop(run, rng), rng))
	assert_true(screen.get_node("%ShopPanel").visible)
	assert_true(screen.get_node("%ContinueButton").visible)
	assert_eq(screen.get_node("%HandRow").get_child_count(), 0)


func test_reprise_en_plein_round() -> void:
	var content := GameContent.load_default()
	var rng := RandomNumberGenerator.new()
	var run := content.new_run(rng)
	run.start()
	var screen := _resume(RunSnapshot.capture(run, null, rng))
	assert_false(screen.get_node("%ShopPanel").visible)
	assert_eq(screen.get_node("%HandRow").get_child_count(), content.round_rules.hand_size)

func _instant_feel() -> ScoreFeel:
	var feel := ScoreFeel.new()
	feel.start_delay = 0.0
	feel.step_delay = 0.0
	feel.end_delay = 0.0
	feel.roll_time = 0.0
	feel.announce_time = 0.0
	return feel


func _play_first_card(screen: Control) -> void:
	(screen.get_node("%HandRow").get_child(0) as CardView).button_pressed = true
	screen.get_node("%PlayButton").pressed.emit()


func test_jouer_montre_le_score_puis_rend_la_main() -> void:
	var screen: Control = add_child_autofree(SCREEN.instantiate())
	screen._sequence.feel = _instant_feel()
	screen._side.feel = _instant_feel()
	var rules: RoundRules = load(RULES_PATH)
	_play_first_card(screen)
	assert_eq(screen.get_node("%HandRow").get_child_count(), rules.hand_size, "cartes jouees retirees, main repiochee")
	assert_eq(screen._side._round_qi.text, str(screen._round.score), "Qi du round a jour apres la sequence")
	assert_gt(screen._round.score, 0)
	assert_false(screen._scoring, "plus de sequence en cours")


func test_boutons_bloques_pendant_la_sequence() -> void:
	var screen: Control = add_child_autofree(SCREEN.instantiate())
	_play_first_card(screen)
	assert_true(screen._scoring)
	assert_true(screen.get_node("%PlayButton").disabled)
	assert_true(screen.get_node("%DiscardButton").disabled)
	assert_eq(screen._side._round_qi.text, "0", "le Qi du round attend la fin de la sequence")


func test_coup_sauvegarde_avant_la_fin_de_la_sequence() -> void:
	var storage := SaveStorage.new("user://test_round_screen_run.json")
	var instance := SCREEN.instantiate()
	instance.run_storage = storage
	var screen: Control = add_child_autofree(instance)
	var before := storage.load_data()
	_play_first_card(screen)
	assert_true(screen._scoring, "sequence en cours")
	assert_ne(storage.load_data(), before, "le coup est deja sauvegarde")
	storage.delete()


func _particles(screen: Control) -> int:
	return screen._sequence.find_children("*", "CPUParticles2D", false, false).size()


func test_cartes_qui_comptent_lachent_du_qi() -> void:
	var screen: Control = add_child_autofree(SCREEN.instantiate())
	screen._sequence.feel = _instant_feel()
	_play_first_card(screen)
	assert_gt(_particles(screen), 0)


func test_pas_de_particules_si_on_reduit_les_animations() -> void:
	var instance := SCREEN.instantiate()
	instance.settings = GameSettings.new()
	instance.settings.reduce_motion = true
	var screen: Control = add_child_autofree(instance)
	screen._sequence.feel = _instant_feel()
	_play_first_card(screen)
	assert_eq(_particles(screen), 0)


func test_colonne_affiche_objectif_et_compteurs() -> void:
	var screen: Control = add_child_autofree(SCREEN.instantiate())
	var side: SideColumn = screen.get_node("%SideColumn")
	assert_eq(side._target.text, str(screen._round.target_score))
	assert_eq(side._hands.text, str(screen._round.hands_left))
	assert_eq(side._stones.text, str(screen._run.stones))
	assert_eq(side._realm.text, tr("UI_SIDE_OF") % [1, screen._run.progress.realm_count()])


func test_selection_montre_l_apercu_de_la_main() -> void:
	var screen: Control = add_child_autofree(SCREEN.instantiate())
	var side: SideColumn = screen.get_node("%SideColumn")
	assert_eq(side._hand_name.text, tr("UI_SIDE_NO_HAND"))
	(screen.get_node("%HandRow").get_child(0) as CardView).button_pressed = true
	assert_ne(side._hand_name.text, tr("UI_SIDE_NO_HAND"))
	assert_ne(side._qi.text, "-")


func test_bouton_options_demande_les_reglages() -> void:
	var screen: Control = add_child_autofree(SCREEN.instantiate())
	watch_signals(screen)
	screen.get_node("%SideColumn").options_requested.emit()
	assert_signal_emitted(screen, "options_requested")


func test_rangee_haute_montre_tous_les_emplacements() -> void:
	var screen: Control = add_child_autofree(SCREEN.instantiate())
	var rules := GameContent.load_default().shop_rules
	var items: ItemRow = screen.get_node("%ItemRow")
	assert_eq(items._artifact_slots.get_child_count(), maxi(rules.max_artifacts, screen._run.artifacts.size()))
	assert_eq(items._pill_slots.get_child_count(), rules.max_pills)


func test_clic_sur_une_pilule_l_utilise() -> void:
	var screen: Control = add_child_autofree(SCREEN.instantiate())
	screen._run.pills.append(screen.content.pill_by_id(&"pilule_feu_celeste"))
	var view := screen.get_node("%HandRow").get_child(0) as CardView
	view.button_pressed = true
	var slot := screen.get_node("%ItemRow")._pill_slots.get_child(0) as ItemSlot
	assert_false(slot.disabled)
	slot.pressed.emit()
	assert_eq(screen._run.pills.size(), 0, "pilule consommee")
	assert_eq(view.card.element, Element.Type.FEU)


func _shown_cards(screen: Control) -> Array[CardInstance]:
	var cards: Array[CardInstance] = []
	for view: CardView in screen.get_node("%HandRow").get_children():
		cards.append(view.card)
	return cards


func test_tri_par_element_regroupe_les_elements() -> void:
	var screen: Control = add_child_autofree(SCREEN.instantiate())
	screen.get_node("%SortElement").button_pressed = true
	var cards := _shown_cards(screen)
	for i: int in cards.size() - 1:
		assert_true(cards[i].element < cards[i + 1].element
			or (cards[i].element == cards[i + 1].element and cards[i].rank <= cards[i + 1].rank))


func test_tri_garde_la_selection() -> void:
	var screen: Control = add_child_autofree(SCREEN.instantiate())
	var view := screen.get_node("%HandRow").get_child(0) as CardView
	view.button_pressed = true
	screen.get_node("%SortElement").button_pressed = true
	assert_eq(screen._selected(), [view.card] as Array[CardInstance])


func test_pioche_affiche_les_cartes_restantes() -> void:
	var screen: Control = add_child_autofree(SCREEN.instantiate())
	var pile: DeckPile = screen.get_node("%DeckPile")
	assert_eq(pile._count.text, tr("UI_SIDE_OF") % [screen._round.draw_count(), screen._round.deck_size()])
	assert_lt(screen._round.draw_count(), screen._round.deck_size())


func test_clic_sur_la_pioche_montre_tout_le_paquet() -> void:
	var screen: Control = add_child_autofree(SCREEN.instantiate())
	screen.get_node("%DeckPile").pressed.emit()
	var viewer: DeckViewer = _viewer(screen)
	assert_not_null(viewer)
	var views: Array[CardView] = []
	var greyed: int = 0
	for view: Node in viewer.find_children("*", "CardView", true, false):
		views.append(view)
		if (view as CardView).modulate != Color.WHITE:
			greyed += 1
	assert_eq(views.size(), screen._round.deck_size())
	assert_eq(greyed, screen._round.deck_size() - screen._round.draw_count())
	viewer.close()
	await wait_process_frames(1)
	assert_null(_viewer(screen), "ferme au clic")


func test_pioche_inactive_pendant_la_sequence() -> void:
	var screen: Control = add_child_autofree(SCREEN.instantiate())
	_play_first_card(screen)
	assert_false(screen.get_node("%DeckPile").enabled)
	screen._show_deck()
	assert_null(_viewer(screen))


func _viewer(screen: Node) -> DeckViewer:
	for child: Node in screen.get_children():
		if child is DeckViewer and not child.is_queued_for_deletion():
			return child
	return null


## Annonce du nom de la main : la sequence se termine, avec ou sans animations, et le tableau redevient visible.
func _short_announce_feel() -> ScoreFeel:
	var feel := _instant_feel()
	feel.announce_time = 0.05
	return feel


func _play_with_announce(reduce_motion: bool) -> Control:
	var instance := SCREEN.instantiate()
	instance.settings = GameSettings.new()
	instance.settings.reduce_motion = reduce_motion
	var screen: Control = add_child_autofree(instance)
	screen._sequence.feel = _short_announce_feel()
	_play_first_card(screen)
	return screen


func test_annonce_puis_fin_de_sequence() -> void:
	var screen := _play_with_announce(false)
	assert_true(screen._scoring, "l'annonce retient la sequence")
	await wait_until(func() -> bool: return not screen._scoring, 2.0)
	assert_false(screen._scoring)
	assert_eq(screen._sequence.find_children("*", "PanelContainer", false, false).size(), 0, "sceau d'annonce parti")


func test_annonce_sans_animations() -> void:
	var screen := _play_with_announce(true)
	await wait_until(func() -> bool: return not screen._scoring, 2.0)
	assert_false(screen._scoring)


func _instant_end() -> RoundEndFeel:
	var feel := RoundEndFeel.new()
	feel.seal_time = 0.0
	feel.wave_time = 0.0
	feel.crystal_time = 0.0
	feel.defeat_time = 0.0
	return feel


func _instant_screen() -> Control:
	var screen: Control = add_child_autofree(SCREEN.instantiate())
	screen._sequence.feel = _instant_feel()
	screen._side.feel = _instant_feel()
	screen._round_end.feel = _instant_end()
	return screen


func test_ambiance_du_goulot_au_debut_du_round() -> void:
	var screen: Control = SCREEN.instantiate()
	var ids: Array[StringName] = []
	screen.ambiance_changed.connect(ids.append)
	add_child_autofree(screen)
	assert_eq(ids.back(), screen._run.progress.current_bottleneck().id)


func test_victoire_puis_boutique() -> void:
	var screen := _instant_screen()
	var ids: Array[StringName] = []
	screen.ambiance_changed.connect(ids.append)
	screen._round.target_score = 1
	_play_first_card(screen)
	await wait_until(func() -> bool: return screen.get_node("%ShopPanel").visible, 2.0)
	assert_true(screen.get_node("%ShopPanel").visible, "boutique ouverte apres le sceau")
	assert_true(screen.get_node("%ContinueButton").visible)
	assert_false(screen.get_node("%HandRow").visible, "la main laisse la place a la boutique")
	assert_eq(ids.back(), &"boutique")
	assert_eq(screen._last_hand.text, "", "pas de texte de victoire dans la boutique : les cristaux montrent le gain")
	screen.get_node("%ContinueButton").pressed.emit()
	assert_eq(ids.back(), screen._run.progress.current_bottleneck().id, "ambiance du goulot suivant")
	assert_true(screen.get_node("%HandRow").visible, "main revenue au round suivant")


func test_echec_recouvre_l_ecran_et_mene_au_menu() -> void:
	var screen := _instant_screen()
	screen._round.target_score = 1000000
	screen._round.hands_left = 1
	watch_signals(screen)
	_play_first_card(screen)
	await wait_physics_frames(2)
	var buttons: Array[Node] = screen._round_end.find_children("*", "Button", true, false)
	assert_eq(buttons.size(), 1, "bouton du menu sur l'encre")
	assert_eq(screen._round_end.mouse_filter, Control.MOUSE_FILTER_STOP, "l'encre prend les clics")
	(buttons[0] as Button).pressed.emit()
	assert_signal_emitted(screen, "menu_requested")


## Rythme reel de round_end_feel.tres : la victoire doit rendre la main (bug : le sceau libere tuait son tween).
func test_victoire_animee_puis_boutique() -> void:
	var screen: Control = add_child_autofree(SCREEN.instantiate())
	screen._sequence.feel = _instant_feel()
	screen._side.feel = _instant_feel()
	screen._round.target_score = 1
	_play_first_card(screen)
	await wait_until(func() -> bool: return screen.get_node("%ShopPanel").visible, 4.0)
	assert_true(screen.get_node("%ShopPanel").visible)


## Plus de tableau au-dessus des cartes : le decompte passe par la colonne.
func test_decompte_affiche_dans_la_colonne() -> void:
	var screen: Control = add_child_autofree(SCREEN.instantiate())
	screen._sequence.feel = _instant_feel()
	var side: SideColumn = screen.get_node("%SideColumn")
	var last: Array = []
	screen._sequence.tally_changed.connect(func(qi: int, comprehension: float) -> void:
		last.assign([side._qi.text, qi, comprehension]))
	watch_signals(screen._sequence)
	_play_first_card(screen)
	assert_signal_emitted(screen._sequence, "hand_named")
	assert_false(last.is_empty(), "la colonne a recu le compteur")
	assert_eq(last[0], str(last[1]), "case Qi a jour")
	assert_eq(roundi(last[1] * last[2]), screen._round.score, "derniere etape : Qi x Comprehension = score du coup")
	assert_null(screen._sequence.get("_board"), "plus de tableau")


func test_meditant_rempli_selon_l_objectif() -> void:
	var screen: Control = add_child_autofree(SCREEN.instantiate())
	var side: SideColumn = screen.get_node("%SideColumn")
	var shader := side._meditant.material as ShaderMaterial
	side._target_score = 200
	side._set_shown_score(50)
	assert_almost_eq(shader.get_shader_parameter(&"fill"), 0.25, 0.001)
	side._set_shown_score(500)
	assert_eq(shader.get_shader_parameter(&"fill"), 1.0, "plafonne a l'objectif")


func test_victoire_double_onde_et_ciel_dore() -> void:
	var end := RoundEnd.new()
	add_child_autofree(end)
	end._wave()
	assert_eq(end.find_children("*", "ColorRect", false, false).size(), 3, "deux ondes et l'eclair du ciel")
