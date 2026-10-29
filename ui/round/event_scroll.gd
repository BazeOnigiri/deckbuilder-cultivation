class_name EventScroll
extends RefCounted
## Rouleau d'une rencontre : glyphe et recit, puis les choix en sceaux (cout et issues lisibles, choix indisponible
## grise avec sa raison). Une fois le choix fait, le meme rouleau montre l'issue tiree et un sceau Continuer.
## Ne se ferme que par ses actions.


## on_choose(index) : un choix est pris. on_done() : l'issue a ete lue.
static func open(parent: Node, run: RunState, on_choose: Callable, on_done: Callable, animated: bool) -> ScrollOverlay:
	var event := run.current_event
	var body := VBoxContainer.new()
	body.add_theme_constant_override(&"separation", body.get_theme_constant(&"separation", &"ScrollPanel"))
	var story := HBoxContainer.new()
	var seal := SideColumn.make_label(&"PathSeal")
	seal.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	seal.text = event.glyph
	story.add_child(seal)
	story.add_child(_text(&"ScrollText", event.text_key, body.get_theme_constant(&"text_width", &"ScrollPanel")))
	body.add_child(story)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(actions)
	var overlay := ScrollOverlay.open(parent, event.title_key, body, animated)
	overlay.dismissable = false
	overlay.hide_close()
	var outcome := run.current_outcome()
	if outcome == null:
		for i: int in event.choices.size():
			actions.add_child(_choice(run, i, overlay, on_choose.bind(i)))
	else:
		var result := VBoxContainer.new()
		result.add_child(_text(&"ScrollText", outcome.text_key, body.get_theme_constant(&"text_width", &"ScrollPanel")))
		result.add_child(_text(&"ScrollCaption", outcome.describe(), 0))
		var done := _seal("UI_EVENT_CONTINUE", overlay, on_done)
		done.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		result.add_child(done)
		actions.add_child(result)
	overlay.initial_focus = actions
	return overlay


## Un choix sur une tablette : sceau, cout, issues avec leur chance, raison s'il est indisponible.
static func _choice(run: RunState, index: int, overlay: ScrollOverlay, callback: Callable) -> PanelContainer:
	var choice: EventChoice = run.current_event.choices[index]
	var tablet := PanelContainer.new()
	tablet.theme_type_variation = &"StatTile"
	var width := tablet.get_theme_constant(&"width", &"HandTablet")
	tablet.custom_minimum_size.x = width
	var column := VBoxContainer.new()
	tablet.add_child(column)
	var button := _seal(choice.label_key, overlay, callback)
	column.add_child(button)
	if choice.cost != null:
		column.add_child(_text(&"ScrollCaption", choice.cost.describe(), width))
	for i: int in choice.outcomes.size():
		var line := choice.outcomes[i].describe()
		if choice.outcomes.size() > 1:
			line = RunInfo.tr_key("UI_EVENT_CHANCE") % [choice.percent_of(i), line]
		column.add_child(_text(&"ScrollText", line, width))
	var reason := run.event_blocked_reason(index)
	if not reason.is_empty():
		button.disabled = true
		# Le focus va au premier choix possible ; la raison reste lisible sous le sceau.
		button.focus_mode = Control.FOCUS_NONE
		column.add_child(_text(&"ScrollWarning", reason, width))
	return tablet


static func _seal(key: String, overlay: ScrollOverlay, callback: Callable) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"SealButton"
	button.text = key
	button.pressed.connect(func() -> void:
		overlay.close()
		# Retire tout de suite : l'ecran dessous reprend le focus (Focus.trap) avant le rouleau suivant.
		overlay.get_parent().remove_child(overlay)
		callback.call())
	return button


## width 0 : largeur du contenu.
static func _text(type: StringName, text: String, width: int) -> Label:
	var label := SideColumn.make_label(type, text)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = width
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label
