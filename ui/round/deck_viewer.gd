class_name DeckViewer
extends PanelContainer
## Tout le paquet de la run sur un voile, une rangee par element, cartes par rang.
## Les cartes hors de la pioche (en main, jouees, defaussees) sont grisees. Un clic ou Echap ferme.
## Apparence dans le Theme (types Veil et DeckViewer).

signal closed

var _rows := VBoxContainer.new()


func _ready() -> void:
	theme_type_variation = &"Veil"
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	var center := CenterContainer.new()
	center.mouse_filter = MOUSE_FILTER_IGNORE
	_rows.mouse_filter = MOUSE_FILTER_IGNORE
	_rows.add_theme_constant_override(&"separation", get_theme_constant(&"row_separation", &"DeckViewer"))
	center.add_child(_rows)
	add_child(center)


## in_draw_pile(card) -> bool : vrai si la carte peut encore etre piochee.
func show_deck(cards: Array[CardInstance], in_draw_pile: Callable) -> void:
	for child: Node in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	var title := SideColumn.make_label(&"SideTitle", "UI_DECK_VIEW")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rows.add_child(title)
	for element: int in Element.Type.values():
		var of_element := cards.filter(func(card: CardInstance) -> bool: return card.element == element)
		of_element.sort_custom(func(a: CardInstance, b: CardInstance) -> bool: return a.rank < b.rank)
		var left: int = of_element.filter(in_draw_pile).size()
		_rows.add_child(_row(element, of_element, left, in_draw_pile))
	var hint := SideColumn.make_label(&"SideCaption")
	hint.text = Keys.text_of("UI_DECK_VIEW_CLOSE")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rows.add_child(hint)


func _row(element: int, cards: Array, left: int, in_draw_pile: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = MOUSE_FILTER_IGNORE
	var count := SideColumn.make_label(&"SideCaption")
	count.text = tr("ELEMENT_" + Element.to_id(element).to_upper()) + "\n" + tr("UI_SIDE_OF") % [left, cards.size()]
	count.custom_minimum_size.x = get_theme_constant(&"label_width", &"DeckViewer")
	row.add_child(count)
	var card_scale: float = get_theme_constant(&"card_percent", &"DeckViewer") / 100.0
	var used := get_theme_color(&"used_color", &"DeckViewer")
	for card: CardInstance in cards:
		row.add_child(CardView.small(card, card_scale, Color.WHITE if in_draw_pile.call(card) else used))
	return row


func close() -> void:
	closed.emit()
	queue_free()


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed:
		accept_event()
		close()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"show_deck"):
		get_viewport().set_input_as_handled()
		close()
	elif event is InputEventKey:
		get_viewport().set_input_as_handled()
