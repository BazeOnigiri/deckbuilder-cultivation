class_name ScrollOverlay
extends PanelContainer
## Rouleau ouvert par-dessus l'ecran, sur un voile : titre, contenu, sceau Fermer.
## Se ferme au clic hors du rouleau, avec Echap (ui_cancel) ou par le sceau. Remplace les fenetres natives.

signal closed

var _scroll := ScrollPanel.new()
var _body := VBoxContainer.new()
var _title := SideColumn.make_label(&"ScrollTitle")
var _close := Button.new()


## parent : ou poser le voile. body : le contenu du rouleau. animated faux : pas de deroulement.
static func open(parent: Node, title_key: String, body: Control, animated: bool = true) -> ScrollOverlay:
	var overlay := ScrollOverlay.new()
	overlay._title.text = title_key
	overlay._body.add_child(body)
	parent.add_child(overlay)
	overlay._scroll.unroll(overlay.get_theme_constant(&"unroll_ms", &"ScrollPanel") / 1000.0 if animated else 0.0)
	return overlay


func _ready() -> void:
	theme_type_variation = &"Veil"
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	var center := CenterContainer.new()
	center.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(center)
	center.add_child(_scroll)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override(&"separation", get_theme_constant(&"separation", &"ScrollPanel"))
	_scroll.add_child(layout)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(_title)
	layout.add_child(_body)
	_close.theme_type_variation = &"SealButton"
	_close.text = "UI_CLOSE"
	_close.size_flags_horizontal = SIZE_SHRINK_CENTER
	_close.pressed.connect(close)
	layout.add_child(_close)
	Focus.trap(self)
	# Apres open() : le contenu et hide_close() sont poses.
	_grab_initial_focus.call_deferred()


func _grab_initial_focus() -> void:
	if is_inside_tree() and not Focus.grab_first(_body):
		Focus.grab_first(_close)


## Pour les rouleaux qui ont leurs propres actions (ex. Continuer / Recommencer) : le sceau Fermer est retire.
func hide_close() -> void:
	_close.hide()


func close() -> void:
	if is_queued_for_deletion():
		return
	closed.emit()
	queue_free()


func _gui_input(event: InputEvent) -> void:
	# Le rouleau prend ses propres clics : ce qui arrive ici est tombe a cote.
	# La molette est aussi un bouton de souris : seuls les vrais clics ferment.
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		accept_event()
		close()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
	elif event is InputEventKey or event.is_action_type():
		# Rouleau ouvert : les touches et boutons de la partie (jouer, defausser...) n'agissent pas derriere lui.
		get_viewport().set_input_as_handled()
