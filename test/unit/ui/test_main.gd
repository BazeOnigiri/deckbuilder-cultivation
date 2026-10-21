extends GutTest
## Test de fumee : le jeu demarre sur le menu.

const MAIN := preload("res://ui/main/main.tscn")


func test_demarre_sur_le_menu() -> void:
	var main: Control = add_child_autofree(MAIN.instantiate())
	assert_eq(main.get_child_count(), 1)
	assert_not_null(main.get_child(0).get_node_or_null("%StartButton"))