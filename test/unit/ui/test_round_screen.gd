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