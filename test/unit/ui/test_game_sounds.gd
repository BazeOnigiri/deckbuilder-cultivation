extends GutTest
## Sons branches sur le jeu : chaque moment demande le bon son a l'autoload Sons (signal played).

const SCREEN := preload("res://ui/round/round_screen.tscn")

var _played: Array = []


func before_each() -> void:
	_played.clear()
	Sons.played.connect(_record)


func after_each() -> void:
	Sons.played.disconnect(_record)


func _record(id: StringName, step: int) -> void:
	_played.append([id, step])


func _ids() -> Array:
	return _played.map(func(entry: Array) -> StringName: return entry[0])


## Affronte le goulot annonce (rouleau d'annonce ouvert au depart d'une run), pour avoir un round en cours.
func _fight(screen: Control) -> Control:
	for overlay: Node in screen.get_children():
		if overlay is ScrollOverlay and not overlay.is_queued_for_deletion():
			for button: Button in overlay.find_children("*", "Button", true, false):
				if button.text == "UI_ANNOUNCE_FIGHT":
					button.pressed.emit()
					return screen
	return screen


func _screen() -> Control:
	var screen: Control = _fight(add_child_autofree(SCREEN.instantiate()))
	var feel := ScoreFeel.new()
	feel.start_delay = 0.0
	feel.step_delay = 0.0
	feel.end_delay = 0.0
	feel.roll_time = 0.0
	feel.announce_time = 0.0
	feel.orb_time = 0.0
	screen._sequence.feel = feel
	screen._side.feel = feel
	var end := RoundEndFeel.new()
	end.seal_time = 0.0
	end.wave_time = 0.0
	end.crystal_time = 0.0
	end.defeat_time = 0.0
	screen._round_end.feel = end
	return screen


func _play_cards(screen: Control, count: int) -> void:
	for i: int in count:
		(screen.get_node("%HandRow").get_child(i) as CardView).button_pressed = true
	screen.get_node("%PlayButton").pressed.emit()


## Une carte n'est pas un bouton d'interface : papier pose ou repris, pas le clic en bois.
func test_selection_de_carte_a_son_propre_son() -> void:
	var screen := _screen()
	var card := screen.get_node("%HandRow").get_child(0) as CardView
	_played.clear()
	card.button_pressed = true
	card.pressed.emit()
	card.button_pressed = false
	card.pressed.emit()
	assert_eq(_ids(), [&"carte_selection", &"carte_deselection"])


func test_selection_par_le_code_silencieuse() -> void:
	var screen := _screen()
	_played.clear()
	(screen.get_node("%HandRow").get_child(0) as CardView).button_pressed = true
	assert_false(_ids().has(&"carte_selection"), "trier ou vider la main ne fait pas de bruit")


func test_clic_et_survol_des_boutons() -> void:
	var button: Button = add_child_autofree(Button.new())
	button.pressed.emit()
	button.mouse_entered.emit()
	button.disabled = true
	button.mouse_entered.emit()
	assert_eq(_ids(), [&"ui_clic", &"ui_survol"], "pas de survol sur un bouton desactive")


func test_pioche_au_debut_du_round() -> void:
	_screen()
	assert_has(_ids(), &"carte_pioche")


func test_sequence_de_score_monte_dans_la_gamme() -> void:
	var screen := _screen()
	_played.clear()
	_play_cards(screen, 2)
	var ids := _ids()
	assert_has(ids, &"carte_jouee")
	assert_has(ids, &"annonce_main")
	var notes: Array = _played.filter(func(entry: Array) -> bool: return entry[0] == &"note_carte")
	assert_gt(notes.size(), 0, "une note par carte qui compte")
	for i: int in notes.size() - 1:
		assert_gt(notes[i + 1][1], notes[i][1], "chaque note plus haute que la precedente")
	assert_eq(_played.filter(func(entry: Array) -> bool:
		return entry[0] == &"orbe_impact" or entry[0] == &"multiplication").size(),
		notes.size() + ids.count(&"orbe_depart"), "un impact par orbe")


func test_defausse() -> void:
	var screen := _screen()
	(screen.get_node("%HandRow").get_child(0) as CardView).button_pressed = true
	_played.clear()
	screen.get_node("%DiscardButton").pressed.emit()
	assert_has(_ids(), &"carte_defausse")
	assert_has(_ids(), &"carte_pioche", "la main se complete")


func test_victoire_et_pierres() -> void:
	var screen := _screen()
	screen._round.target_score = 1
	_play_cards(screen, 1)
	await wait_until(func() -> bool: return screen.get_node("%ShopPanel").visible, 2.0)
	assert_has(_ids(), &"pierres")
	assert_has(_ids(), &"victoire")


func test_defaite() -> void:
	var screen := _screen()
	screen._round.target_score = 1000000
	screen._round.hands_left = 1
	_play_cards(screen, 1)
	await wait_physics_frames(2)
	assert_has(_ids(), &"defaite")
	assert_does_not_have(_ids(), &"victoire")
