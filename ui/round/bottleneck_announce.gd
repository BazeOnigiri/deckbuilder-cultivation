class_name BottleneckAnnounce
extends RefCounted
## Rouleau d'annonce du goulot, avant chaque round : les goulots du royaume en tablettes (celui en cours mis en avant),
## avec objectif, recompense, contrainte et presage. Affronter, ou Passer (sauf une tribulation) pour le presage.
## Ne se ferme que par ses deux actions.


static func open(parent: Node, run: RunState, on_fight: Callable, on_skip: Callable, animated: bool) -> ScrollOverlay:
	var body := VBoxContainer.new()
	body.add_theme_constant_override(&"separation", body.get_theme_constant(&"separation", &"ScrollPanel"))
	var tablets := HBoxContainer.new()
	tablets.alignment = BoxContainer.ALIGNMENT_CENTER
	var realm := run.progress.current_realm()
	for b: int in realm.bottlenecks.size():
		tablets.add_child(_tablet(run, realm, b))
	body.add_child(tablets)
	if run.hand_penalty > 0:
		var penalty := SideColumn.make_label(&"ScrollWarning")
		penalty.text = RunInfo.tr_key("UI_ANNOUNCE_HAND_PENALTY") % run.hand_penalty
		penalty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body.add_child(penalty)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(actions)
	var overlay := ScrollOverlay.open(parent, realm.title(), body, animated)
	overlay.dismissable = false
	overlay.hide_close()
	actions.add_child(_action("UI_ANNOUNCE_FIGHT", overlay, on_fight))
	if run.can_skip():
		actions.add_child(_action("UI_ANNOUNCE_SKIP", overlay, on_skip))
	# Affronter, pas le premier presage.
	overlay.initial_focus = actions
	return overlay


static func _action(key: String, overlay: ScrollOverlay, callback: Callable) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"SealButton"
	button.text = key
	button.pressed.connect(func() -> void:
		overlay.close()
		# Retire tout de suite : l'ecran dessous reprend le focus (Focus.trap) avant que le round ne le pose.
		overlay.get_parent().remove_child(overlay)
		callback.call())
	return button


## Le goulot en cours sur une tablette de jade, les autres sur une tuile.
static func _tablet(run: RunState, realm: RealmDefinition, index: int) -> PanelContainer:
	var bottleneck: BottleneckDefinition = realm.bottlenecks[index]
	var position := run.progress.bottleneck_position(index)
	var tablet := PanelContainer.new()
	tablet.theme_type_variation = &"HandTablet" if position == 0 else &"StatTile"
	tablet.custom_minimum_size.x = tablet.get_theme_constant(&"width", &"HandTablet")
	var column := VBoxContainer.new()
	tablet.add_child(column)
	column.add_child(SideColumn.make_label(&"ScrollCaption", RunInfo.POSITION_KEYS[position + 1]))
	column.add_child(SideColumn.make_label(&"ScrollTitle" if position == 0 else &"ScrollText", bottleneck.name_key))
	var target := SideColumn.make_label(&"ScrollText")
	target.text = RunInfo.tr_key("UI_INFO_TARGET_N") % run.target_for(realm, bottleneck)
	column.add_child(target)
	var reward := SideColumn.make_label(&"ScrollCaption")
	reward.text = RunInfo.tr_key("UI_ANNOUNCE_REWARD") % bottleneck.reward
	column.add_child(reward)
	if bottleneck.constraint != null:
		var constraint := SideColumn.make_label(&"ScrollWarning", bottleneck.constraint.description_key)
		constraint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(constraint)
		column.add_child(SideColumn.make_label(&"ScrollCaption", "UI_ANNOUNCE_NO_SKIP"))
	var omen: OmenDefinition = run.omen_offers[index] if index < run.omen_offers.size() else null
	if omen != null and position >= 0:
		column.add_child(SideColumn.make_label(&"ScrollCaption", "UI_ANNOUNCE_IF_SKIPPED"))
		var line := HBoxContainer.new()
		line.add_child(ContentSlots.of(omen))
		var omen_name := SideColumn.make_label(&"ScrollText", omen.name_key)
		omen_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		omen_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.add_child(omen_name)
		column.add_child(line)
	return tablet
