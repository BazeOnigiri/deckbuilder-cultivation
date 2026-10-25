extends GutTest
## Tests de fumee : menu de depart, bouton Continuer selon la sauvegarde.

const MAIN := preload("res://ui/main/main.tscn")
const TEST_PROFILE := "user://test_profil_main.json"
const TEST_RUN := "user://test_run_main.json"


func after_each() -> void:
	SaveStorage.new(TEST_PROFILE).delete()
	SaveStorage.new(TEST_RUN).delete()


func _main() -> Control:
	var instance := MAIN.instantiate()
	instance.profile_path = TEST_PROFILE
	instance.run_path = TEST_RUN
	return add_child_autofree(instance)


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
	assert_not_null(menu.get_node_or_null("%CreditsButton"))


func test_continuer_cache_sans_sauvegarde() -> void:
	var menu := _main().get_child(0)
	assert_false(menu.get_node("%ContinueButton").visible)


func test_continuer_visible_avec_une_sauvegarde() -> void:
	_write_saved_run()
	var menu := _main().get_child(0)
	assert_true(menu.get_node("%ContinueButton").visible)