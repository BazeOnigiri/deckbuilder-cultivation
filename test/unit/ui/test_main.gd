extends GutTest
## Test de fumee : le jeu demarre sur le menu, avec les credits accessibles.

const MAIN := preload("res://ui/main/main.tscn")
const TEST_PROFILE := "user://test_profil_main.json"


func after_each() -> void:
	SaveStorage.new(TEST_PROFILE).delete()


func _main() -> Control:
	var instance := MAIN.instantiate()
	instance.profile_path = TEST_PROFILE
	return add_child_autofree(instance)


func test_demarre_sur_le_menu() -> void:
	var main := _main()
	assert_eq(main.get_child_count(), 1)
	assert_not_null(main.get_child(0).get_node_or_null("%StartButton"))
	assert_not_null(main.get_child(0).get_node_or_null("%StatsButton"))
	assert_not_null(main.get_child(0).get_node_or_null("%CreditsButton"))