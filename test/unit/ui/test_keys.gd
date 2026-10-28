extends GutTest
## Actions du clavier : definies dans l'InputMap, avec une touche, et reconnues par leur place.


func test_chaque_action_listee_a_une_touche() -> void:
	for entry: Array in Keys.LISTED:
		assert_true(InputMap.has_action(entry[0]), "action absente : %s" % entry[0])
		assert_ne(Keys.name_of(entry[0]), "", "pas de touche : %s" % entry[0])


func test_une_action_par_carte_de_la_main() -> void:
	var hand_size: int = (load("res://content/rules/regles_base.tres") as RoundRules).hand_size
	for i: int in hand_size:
		assert_true(InputMap.has_action(StringName(Keys.SELECT_PREFIX + str(i + 1))), "carte %d" % (i + 1))


func test_place_de_la_carte_choisie() -> void:
	var event := InputEventAction.new()
	event.action = &"select_card_3"
	event.pressed = true
	assert_eq(Keys.card_index(event, 8), 2)
	event.action = &"play_hand"
	assert_eq(Keys.card_index(event, 8), -1)
