extends GutTest
## Tests de fumee : menu de depart, bouton Continuer selon la sauvegarde.

const MAIN := preload("res://ui/main/main.tscn")
const TEST_PROFILE := "user://test_profil_main.json"
const TEST_RUN := "user://test_run_main.json"
const TEST_SETTINGS := "user://test_reglages_main.json"


func after_each() -> void:
	SaveStorage.new(TEST_PROFILE).delete()
	SaveStorage.new(TEST_RUN).delete()
	SaveStorage.new(TEST_SETTINGS).delete()


func _main() -> Control:
	var instance := MAIN.instantiate()
	instance.profile_path = TEST_PROFILE
	instance.run_path = TEST_RUN
	instance.settings_path = TEST_SETTINGS
	return add_child_autofree(instance)


## L'ecran affiche : _swap ajoute le nouveau a la fin, l'ancien n'est libere qu'a la frame suivante.
func _current_screen(main: Node) -> Node:
	return main.get_child(main.get_child_count() - 1)


func _write_saved_run() -> void:
	var content := GameContent.load_default()
	var rng := RandomNumberGenerator.new()
	var run := content.new_run(rng)
	run.status = RunState.Status.BETWEEN_ROUNDS
	SaveStorage.new(TEST_RUN).save(RunSnapshot.capture(run, content.new_shop(run, rng), rng))


func test_demarre_sur_le_menu() -> void:
	var menu := _main().get_child(0)
	assert_not_null(menu.get_node_or_null("%StartButton"))
	assert_not_null(menu.get_node_or_null("%StatsButton"))
	assert_not_null(menu.get_node_or_null("%OptionsButton"))
	assert_not_null(menu.get_node_or_null("%CreditsButton"))


func test_continuer_cache_sans_sauvegarde() -> void:
	var menu := _main().get_child(0)
	assert_false(menu.get_node("%ContinueButton").visible)


func test_continuer_visible_avec_une_sauvegarde() -> void:
	_write_saved_run()
	var menu := _main().get_child(0)
	assert_true(menu.get_node("%ContinueButton").visible)


func test_options_sauvegarde_reduire_les_animations() -> void:
	var main := _main()
	main.get_child(0).get_node("%OptionsButton").pressed.emit()
	var options := _current_screen(main)
	options.get_node("%ReduceMotion").button_pressed = true
	assert_true(GameSettings.load_from(SaveStorage.new(TEST_SETTINGS)).reduce_motion)
	options.get_node("%BackButton").pressed.emit()
	assert_not_null(_current_screen(main).get_node_or_null("%OptionsButton"), "retour au menu")


func test_options_affichent_le_reglage_sauvegarde() -> void:
	var saved := GameSettings.new()
	saved.reduce_motion = true
	saved.save_to(SaveStorage.new(TEST_SETTINGS))
	var main := _main()
	main.get_child(0).get_node("%OptionsButton").pressed.emit()
	assert_true(_current_screen(main).get_node("%ReduceMotion").button_pressed)



func test_options_depuis_la_run_gardent_la_run() -> void:
	var main := _main()
	main._show_run({})
	var run_screen: Node = main._screen
	run_screen.get_node("%SideColumn").options_requested.emit()
	var veil := _current_screen(main)
	var options := veil.get_child(0)
	assert_not_null(options.get_node_or_null("%ReduceMotion"))
	# Bug : Entree ou 1 a 8 jouaient la main derriere le voile des options.
	assert_false(run_screen.is_processing_unhandled_input(), "touches de la run coupees sous les options")
	options.get_node("%BackButton").pressed.emit()
	await wait_physics_frames(1)
	assert_false(is_instance_valid(veil), "voile ferme")
	assert_true(run_screen.is_processing_unhandled_input(), "touches rendues a la run")
	assert_true(is_instance_valid(run_screen) and run_screen.is_inside_tree(), "la run continue")


func after_all() -> void:
	Engine.time_scale = 1.0


func test_vitesse_de_jeu_appliquee_au_moteur() -> void:
	var main := _main()
	main.get_child(0).get_node("%OptionsButton").pressed.emit()
	var options := _current_screen(main)
	options.get_node("%GameSpeed").select(2)
	options.get_node("%GameSpeed").item_selected.emit(2)
	assert_eq(Engine.time_scale, GameSettings.GAME_SPEEDS[2])
	assert_eq(GameSettings.load_from(SaveStorage.new(TEST_SETTINGS)).game_speed, GameSettings.GAME_SPEEDS[2])
	Engine.time_scale = 1.0


func test_options_du_menu_sans_boutons_de_run() -> void:
	var main := _main()
	main.get_child(0).get_node("%OptionsButton").pressed.emit()
	assert_false(_current_screen(main).get_node("%RunButtons").visible)


func test_retour_au_menu_depuis_la_run() -> void:
	var main := _main()
	main._show_run({})
	main._screen.get_node("%SideColumn").options_requested.emit()
	var options := _current_screen(main).get_child(0)
	assert_true(options.get_node("%RunButtons").visible)
	options.get_node("%MenuButton").pressed.emit()
	await wait_physics_frames(1)
	assert_not_null(main._screen.get_node_or_null("%OptionsButton"), "menu affiche")
	assert_false(SaveStorage.new(TEST_RUN).load_data().is_empty(), "la run reste a continuer")


func test_nouvelle_partie_depuis_la_run_apres_confirmation() -> void:
	var main := _main()
	main._show_run({})
	var old_run: Node = main._screen
	old_run.get_node("%SideColumn").options_requested.emit()
	var options := _current_screen(main).get_child(0)
	options.get_node("%NewRunButton").pressed.emit()
	assert_true(old_run == main._screen, "rien ne change avant la confirmation")
	options._confirm_button.pressed.emit()
	await wait_physics_frames(1)
	assert_false(is_instance_valid(old_run), "ancienne run fermee")
	assert_not_null(main._screen.get_node_or_null("%SideColumn"), "nouvelle run")
