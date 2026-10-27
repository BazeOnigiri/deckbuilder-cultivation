extends GutTest
## Kit des menus : rouleau, rouleau par-dessus l'ecran, bouton a l'encre, lisibilite sur le papier.

const Contrast := preload("res://test/helpers/contrast.gd")
const THEME_PATH := "res://ui/theme/lavis_de_nuit.tres"
## Couleur la plus claire du papier (fin du degrade du bruit) : pire cas pour un texte sombre, et la plus sombre.
const PAPER_COLORS: Array[Color] = [Color(0.84, 0.79, 0.67, 1), Color(0.94, 0.9, 0.81, 1)]


func _overlay() -> ScrollOverlay:
	var parent: Control = add_child_autofree(Control.new())
	return ScrollOverlay.open(parent, "UI_CLOSE", Label.new(), false)


func test_rouleau_se_ferme_avec_echap() -> void:
	var overlay := _overlay()
	watch_signals(overlay)
	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	overlay._unhandled_input(cancel)
	assert_signal_emitted(overlay, "closed")
	assert_true(overlay.is_queued_for_deletion())


func test_rouleau_se_ferme_au_clic_a_cote() -> void:
	var overlay := _overlay()
	watch_signals(overlay)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	overlay._gui_input(click)
	assert_signal_emitted(overlay, "closed")


func test_sceau_fermer_ferme_et_peut_etre_retire() -> void:
	var overlay := _overlay()
	watch_signals(overlay)
	overlay._close.pressed.emit()
	assert_signal_emitted(overlay, "closed")
	var other := _overlay()
	other.hide_close()
	assert_false(other._close.visible)


func test_rouleau_deroule_puis_a_l_echelle_normale() -> void:
	var scroll: ScrollPanel = add_child_autofree(ScrollPanel.new())
	scroll.unroll(0.05)
	assert_lt(scroll.scale.y, 1.0, "enroule au depart")
	await wait_seconds(0.15)
	assert_eq(scroll.scale, Vector2.ONE)


func test_trait_de_pinceau_au_survol() -> void:
	var button: InkButton = add_child_autofree(InkButton.new())
	button.reduce_motion = true
	button.mouse_entered.emit()
	assert_eq(button.ink, 1.0)
	button.mouse_exited.emit()
	assert_eq(button.ink, 0.0)


func test_textes_lisibles_sur_le_papier() -> void:
	var theme: Theme = load(THEME_PATH)
	for type: String in ["ScrollTitle", "ScrollText", "ScrollCaption"]:
		for paper: Color in PAPER_COLORS:
			assert_gt(Contrast.ratio(theme.get_color("font_color", type), paper), 4.5, "%s sur le papier" % type)
	for state: String in ["font_color", "font_hover_color"]:
		for paper: Color in PAPER_COLORS:
			assert_gt(Contrast.ratio(theme.get_color(state, "InkButton"), paper), 4.5, "InkButton %s" % state)


func test_sceau_lisible() -> void:
	var theme: Theme = load(THEME_PATH)
	var seal: StyleBoxFlat = theme.get_stylebox("normal", "SealButton")
	assert_gt(Contrast.ratio(theme.get_color("font_color", "SealButton"), seal.bg_color), 4.5)


func test_ligne_nom_points_valeur() -> void:
	var icons: Array[Control] = [StoneIcon.new()]
	var line: HBoxContainer = add_child_autofree(ScrollRows.row("UI_INFO_STONES", "12", icons))
	assert_eq(line.get_child_count(), 4, "nom, points, valeur, icone")
	assert_eq((line.get_child(2) as Label).text, "12")
