extends GutTest
## Clavier, manette, tactile : focus initial des rouleaux, evenements avales derriere un voile, infobulle au focus,
## vente de l'objet qui a le focus, noms des boutons de manette.


## Note les evenements qui lui arrivent : place avant un voile, il ne doit plus rien recevoir.
class Spy extends Control:
	var received: Array[InputEvent] = []

	func _unhandled_input(event: InputEvent) -> void:
		received.append(event)


func _joypad(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	return event


func _behind() -> Array:
	var parent: Control = add_child_autofree(Control.new())
	var spy := Spy.new()
	parent.add_child(spy)
	var button := Button.new()
	parent.add_child(button)
	return [parent, spy, button]


func test_rouleau_donne_le_focus_a_son_premier_bouton() -> void:
	var setup := _behind()
	var body := VBoxContainer.new()
	var choice := Button.new()
	body.add_child(choice)
	ScrollOverlay.open(setup[0], "UI_CLOSE", body, false)
	await wait_process_frames(1)
	assert_true(choice.has_focus())
	assert_eq((setup[2] as Button).focus_behavior_recursive, Control.FOCUS_BEHAVIOR_DISABLED)


func test_rouleau_sans_bouton_donne_le_focus_au_sceau_fermer() -> void:
	var setup := _behind()
	var overlay := ScrollOverlay.open(setup[0], "UI_CLOSE", Label.new(), false)
	await wait_process_frames(1)
	assert_true(overlay._close.has_focus())


func test_fermer_le_rouleau_rend_le_focus() -> void:
	var setup := _behind()
	var button: Button = setup[2]
	button.grab_focus()
	var overlay := ScrollOverlay.open(setup[0], "UI_CLOSE", Label.new(), false)
	assert_false(button.has_focus())
	overlay.close()
	await wait_process_frames(1)
	assert_true(button.has_focus())
	assert_eq(button.focus_behavior_recursive, Control.FOCUS_BEHAVIOR_INHERITED)


func test_rouleau_avale_les_boutons_de_manette() -> void:
	var setup := _behind()
	ScrollOverlay.open(setup[0], "UI_CLOSE", Label.new(), false)
	get_viewport().push_input(_joypad(JOY_BUTTON_X))
	assert_eq((setup[1] as Spy).received.size(), 0)


func test_sans_rouleau_le_bouton_arrive_a_l_ecran() -> void:
	var setup := _behind()
	get_viewport().push_input(_joypad(JOY_BUTTON_X))
	assert_eq((setup[1] as Spy).received.size(), 1)


func test_vue_du_paquet_avale_les_boutons_de_manette() -> void:
	var setup := _behind()
	var viewer := DeckViewer.new()
	(setup[0] as Control).add_child(viewer)
	get_viewport().push_input(_joypad(JOY_BUTTON_X))
	assert_eq((setup[1] as Spy).received.size(), 0)
	assert_true(is_instance_valid(viewer))


func _instance() -> CardInstance:
	return CardInstance.new(0, CardData.create(&"c", Element.Type.BOIS, 7), load("res://content/rules/rangs.tres"))


func _card() -> CardView:
	var view := CardView.new()
	view.card = _instance()
	return add_child_autofree(view)


func test_infobulle_montree_au_focus_visible() -> void:
	var view := _card()
	var tip: FocusTip = view.get_node(^"FocusTip")
	view.grab_focus()
	assert_true(tip.is_shown())
	view.release_focus()
	assert_false(tip.is_shown())


func test_pas_d_infobulle_au_focus_cache() -> void:
	var view := _card()
	view.grab_focus(true)
	assert_false((view.get_node(^"FocusTip") as FocusTip).is_shown())


func test_carte_reduite_sans_focus() -> void:
	var frame: Control = add_child_autofree(CardView.small(_instance(), 0.5))
	assert_eq((frame.get_child(0) as Control).focus_mode, Control.FOCUS_NONE)


func _row_with_artifact() -> ItemRow:
	var row: ItemRow = add_child_autofree(ItemRow.new())
	var artifact := ArtifactDefinition.new()
	artifact.glyph = "a"
	var artifacts: Array[ArtifactDefinition] = [artifact]
	row.show_artifacts(artifacts, 2, [3])
	return row


func test_touche_de_vente_sur_l_artefact_qui_a_le_focus() -> void:
	var row := _row_with_artifact()
	watch_signals(row)
	(row._artifact_slots.get_child(0) as Control).grab_focus()
	assert_true(row.press_hovered_item())
	assert_true(row.press_hovered_item())
	assert_signal_emitted_with_parameters(row, "artifact_sell_requested", [0])


func test_emplacement_libre_sans_focus() -> void:
	var row := _row_with_artifact()
	assert_eq((row._artifact_slots.get_child(0) as Control).focus_mode, Control.FOCUS_ALL)
	assert_eq((row._artifact_slots.get_child(1) as Control).focus_mode, Control.FOCUS_NONE)


func test_appui_long_propose_la_vente_sans_vendre() -> void:
	var row := _row_with_artifact()
	watch_signals(row)
	var tip: FocusTip = row._artifact_slots.get_child(0).get_node(^"FocusTip")
	tip.long_pressed.emit()
	tip.long_pressed.emit()
	assert_not_null(row._seal)
	assert_signal_not_emitted(row, "artifact_sell_requested")


func test_focus_garde_quand_la_rangee_est_refaite() -> void:
	var row: ItemRow = add_child_autofree(ItemRow.new())
	var pills: Array[PillDefinition] = [PillDefinition.new(), PillDefinition.new()]
	pills[0].glyph = "a"
	pills[1].glyph = "b"
	var usable: Array[bool] = [true, true]
	row.show_pills(pills, 2, usable)
	(row._pill_slots.get_child(1) as Control).grab_focus()
	row.show_pills(pills, 2, usable)
	assert_true((row._pill_slots.get_child(1) as Control).has_focus())


func test_noms_des_boutons_de_manette() -> void:
	assert_eq(Keys.name_of(&"play_hand", true), "Y")
	assert_eq(Keys.name_of(&"ui_accept", true), "A")
	assert_eq(Keys.name_of(&"sort_by_rank", true), "LT")
	assert_ne(Keys.name_of(&"play_hand", false), "Y")


func test_chaque_action_listee_a_un_bouton_de_manette() -> void:
	for entry: Array in Keys.LISTED:
		if entry[0] != &"select_card_1":
			assert_ne(Keys.name_of(entry[0], true), Keys.name_of(entry[0], false), "pas de bouton : %s" % entry[0])
