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
	var rules: RoundRules = load(RULES_PATH)
	_play_first_card(screen)
	assert_eq(screen.get_node("%HandRow").get_child_count(), rules.hand_size, "cartes jouees retirees, main repiochee")
	assert_ne(screen.get_node("%LastHand").text, "", "resultat affiche apres la sequence")
	assert_false(screen._scoring, "plus de sequence en cours")


func test_boutons_bloques_pendant_la_sequence() -> void:
	var screen: Control = add_child_autofree(SCREEN.instantiate())
	_play_first_card(screen)
	assert_true(screen._scoring)
	assert_true(screen.get_node("%PlayButton").disabled)
	assert_true(screen.get_node("%DiscardButton").disabled)
	assert_eq(screen.get_node("%LastHand").text, "", "le resultat attend la fin de la sequence")


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
