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
