extends GutTest
## Touches changees dans les options : echange entre actions de jeu, refus des touches reservees, retour par defaut.


func after_each() -> void:
	KeyBindings.apply({})


func _has_key(action: StringName, keycode: int) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey and (event as InputEventKey).physical_keycode == keycode:
			return true
	return false


func test_chaque_action_de_jeu_a_une_touche_par_defaut() -> void:
	for action: StringName in KeyBindings.ACTIONS:
		assert_true(InputMap.has_action(action), "action absente : %s" % action)
		assert_false(KeyBindings.keys_of(action, {}).is_empty(), "pas de touche : %s" % action)


func test_aucune_touche_par_defaut_en_double() -> void:
	for action: StringName in KeyBindings.ACTIONS:
		for keycode: int in KeyBindings.keys_of(action, {}):
			assert_eq(KeyBindings.owner_of(keycode, {}), action, "touche %d" % keycode)


func test_nouvelle_touche_appliquee_a_l_inputmap() -> void:
	var bindings := {}
	assert_true(KeyBindings.rebind(bindings, &"discard_hand", KEY_K))
	KeyBindings.apply(bindings)
	assert_true(_has_key(&"discard_hand", KEY_K))
	assert_false(_has_key(&"discard_hand", KEY_D))


func test_touche_d_une_autre_action_echangee() -> void:
	var bindings := {}
	assert_true(KeyBindings.rebind(bindings, &"discard_hand", KEY_R))
	assert_eq(bindings, {"discard_hand": KEY_R, "sort_by_rank": KEY_D})
	assert_eq(KeyBindings.owner_of(KEY_D, bindings), &"sort_by_rank")


func test_touche_reservee_refusee() -> void:
	var bindings := {}
	assert_false(KeyBindings.rebind(bindings, &"discard_hand", KEY_ESCAPE))
	assert_false(KeyBindings.rebind(bindings, &"discard_hand", KEY_SPACE))
	assert_false(KeyBindings.rebind(bindings, &"discard_hand", KEY_1))
	assert_eq(bindings, {})


func test_manette_gardee_quand_la_touche_change() -> void:
	KeyBindings.apply({"play_hand": KEY_P})
	var joypad := InputMap.action_get_events(&"play_hand").filter(func(event: InputEvent) -> bool:
		return event is InputEventJoypadButton)
	assert_eq(joypad.size(), 1)


func test_retour_par_defaut() -> void:
	KeyBindings.apply({"play_hand": KEY_P})
	KeyBindings.apply({})
	assert_true(_has_key(&"play_hand", KEY_ENTER))
	assert_false(_has_key(&"play_hand", KEY_P))
