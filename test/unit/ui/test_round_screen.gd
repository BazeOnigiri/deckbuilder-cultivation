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