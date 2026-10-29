class_name DebugPanel
extends VBoxContainer
## Menu debug (build de developpement seulement, ouvert par l'action debug_menu). Les choix sont lus dans les
## catalogues du contenu ; toute modification passe par DebugActions. Textes en dur : jamais montres au joueur.

## Une modification a eu lieu : l'ecran se redessine.
signal changed
## L'action change le round ou ouvre un sceau : le rouleau se ferme et l'ecran reprend la main.
signal close_requested
## Le round a ete relance par un saut : la boutique ouverte, s'il y en a une, n'a plus lieu d'etre.
signal round_restarted
signal pack_opened

var _run: RunState
var _content: GameContent
var _shop: ShopState
var _status: Label


## shop : la boutique ouverte, null pendant un round (les sceaux ne s'ouvrent qu'en boutique).
static func build(run: RunState, content: GameContent, shop: ShopState) -> DebugPanel:
	var panel := DebugPanel.new()
	panel._run = run
	panel._content = content
	panel._shop = shop
	panel._fill()
	return panel


func _fill() -> void:
	_status = Label.new()
	add_child(_status)
	var stones := Button.new()
	stones.text = "+%d pierres" % DebugActions.STONES_GRANT
	stones.pressed.connect(func() -> void:
		DebugActions.add_stones(_run)
		_done("pierres : %d" % _run.stones))
	add_child(stones)
	_give_row("Artefact", _content.artifacts, func(item: Resource) -> bool:
		return DebugActions.give_artifact(_run, item, _content.shop_rules))
	_give_row("Pilule", _content.pills, func(item: Resource) -> bool:
		return DebugActions.give_pill(_run, item, _content.shop_rules))
	_give_row("Manuel", _content.manuals, func(item: Resource) -> bool:
		DebugActions.give_manual(_run, item)
		return true)
	_give_row("Heritage", _content.legacies, func(item: Resource) -> bool:
		return DebugActions.give_legacy(_run, item))
	var pack_row := _give_row("Sceau", _content.packs, func(item: Resource) -> bool:
		if not DebugActions.open_pack(_shop, item):
			return false
		pack_opened.emit()
		close_requested.emit()
		return true)
	if _shop == null:
		for child: Node in pack_row.get_children():
			(child as Control).tooltip_text = "Seulement en boutique"
			if child is Button or child is OptionButton:
				child.disabled = true
	var win := Button.new()
	win.text = "Gagner le goulot en cours"
	win.pressed.connect(func() -> void:
		if DebugActions.win_round(_run):
			close_requested.emit()
		else:
			_done("aucun round en cours"))
	add_child(win)
	_jump_row()


## Une ligne « nom [liste] [Donner] » : la liste vient du catalogue, le bouton appelle give.
func _give_row(title: String, items: Array, give: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = title
	label.custom_minimum_size.x = get_theme_constant(&"text_width", &"ScrollPanel") / 4.0
	row.add_child(label)
	var choice := OptionButton.new()
	choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for item: Resource in items:
		choice.add_item(_name_of(item))
	row.add_child(choice)
	var button := Button.new()
	button.text = "Donner"
	button.pressed.connect(func() -> void:
		if choice.selected < 0:
			return
		var item: Resource = items[choice.selected]
		_done("%s : %s" % [title, "ok" if give.call(item) else "refuse"] + " (" + _name_of(item) + ")"))
	row.add_child(button)
	add_child(row)
	return row


func _jump_row() -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = "Aller au royaume / goulot"
	row.add_child(label)
	var realm := SpinBox.new()
	realm.min_value = 1
	realm.max_value = _run.progress.realm_count()
	realm.value = _run.progress.realm_number()
	row.add_child(realm)
	var bottleneck := SpinBox.new()
	bottleneck.min_value = 1
	bottleneck.max_value = _content.realms[0].bottlenecks.size()
	bottleneck.value = _run.progress.bottleneck_number()
	row.add_child(bottleneck)
	var go := Button.new()
	go.text = "Sauter"
	go.pressed.connect(func() -> void:
		if DebugActions.jump_to(_run, int(realm.value), int(bottleneck.value)):
			round_restarted.emit()
			close_requested.emit()
		else:
			_done("saut refuse"))
	row.add_child(go)
	add_child(row)


func _done(message: String) -> void:
	_status.text = message
	changed.emit()


func _name_of(item: Resource) -> String:
	if item is ManualDefinition:
		return tr(item.hand.name_key)
	return tr(item.name_key)
