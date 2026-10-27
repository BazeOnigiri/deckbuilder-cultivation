extends GutTest
## Menu principal : Nouvelle partie directe sans sauvegarde, rouleau de confirmation avec une run sauvegardee.

const MENU := preload("res://ui/menu/menu_screen.tscn")


func _menu(saved: bool) -> Control:
	var menu := MENU.instantiate()
	menu.settings = GameSettings.new()
	menu.settings.reduce_motion = true
	if saved:
		var content := GameContent.load_default()
		var run := content.new_run(RandomNumberGenerator.new())
		run.artifacts.assign(content.artifacts.slice(0, 2))
		menu.saved_run = run
	return add_child_autofree(menu)


func _overlay(menu: Node) -> ScrollOverlay:
	for child: Node in menu.get_children():
		if child is ScrollOverlay and not child.is_queued_for_deletion():
			return child
	return null


func test_nouvelle_partie_directe_sans_sauvegarde() -> void:
	var menu := _menu(false)
	watch_signals(menu)
	menu.get_node("%StartButton").pressed.emit()
	assert_signal_emitted(menu, "start_requested")
	assert_null(_overlay(menu))


func test_rouleau_de_confirmation_avec_une_sauvegarde() -> void:
	var menu := _menu(true)
	watch_signals(menu)
	menu.get_node("%StartButton").pressed.emit()
	var overlay := _overlay(menu)
	assert_not_null(overlay)
	assert_signal_not_emitted(menu, "start_requested", "rien ne commence avant le choix")
	var seals := overlay.find_children("*", "Button", true, false).filter(
		func(node: Node) -> bool: return (node as Button).theme_type_variation == &"SealButton" and node.visible)
	assert_eq(seals.size(), 2, "Continuer et Recommencer, pas de Fermer")
	var icons := overlay.find_children("*", "TextureRect", true, false).filter(
		func(node: Node) -> bool: return (node as TextureRect).texture is Texture2D and node.tooltip_text != "")
	assert_eq(icons.size(), 2, "un dessin par artefact de la run")


func test_echap_ferme_le_rouleau_de_partie() -> void:
	var menu := _menu(true)
	menu.get_node("%StartButton").pressed.emit()
	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	_overlay(menu)._unhandled_input(cancel)
	assert_null(_overlay(menu))


func test_titre_dans_la_police_des_sceaux() -> void:
	var menu := _menu(false)
	var title: Label = menu.get_node("%Title")
	var font: FontFile = load("res://ui/fonts/MaShanZheng-Sceaux.ttf")
	for i: int in title.text.length():
		assert_true(font.has_char(title.text.unicode_at(i)), title.text[i])


func test_les_cinq_phases_immobiles_si_on_reduit_les_animations() -> void:
	var menu := _menu(false)
	await wait_physics_frames(3)
	assert_eq(menu.get_node("%Orbit").angle, 0.0)


func test_credits_en_rouleau_avec_la_licence_de_godot() -> void:
	var menu := _menu(false)
	menu.get_node("%CreditsButton").pressed.emit()
	var overlay := _overlay(menu)
	assert_not_null(overlay)
	var text: RichTextLabel = overlay.find_children("*", "RichTextLabel", true, false)[0]
	assert_string_contains(text.text, Engine.get_license_text().substr(0, 40))
