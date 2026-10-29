class_name ItemRow
extends HBoxContainer
## Rangee haute de l'ecran de round : emplacements d'artefacts a gauche, de pilules a droite.
## Affichage seulement : round_screen lui passe le contenu de la run, et recoit pill_pressed.

signal pill_pressed(index: int)
## Second clic sur un artefact (ou clic sur son sceau « Vendre ») : le vendre.
signal artifact_sell_requested(index: int)

## Bond d'un artefact qui se declenche : meme rythme que la sequence de score.
var feel: ScoreFeel = preload("res://ui/round/score_feel.tres")
var settings: GameSettings = GameSettings.new()

var _artifact_caption := SideColumn.make_label(&"SideCaption")
var _artifact_slots := HBoxContainer.new()
var _pill_caption := SideColumn.make_label(&"SideCaption")
var _pill_slots := HBoxContainer.new()
## Emplacement de chaque artefact affiche, pour le faire bondir pendant la sequence.
var _slot_of: Dictionary[ArtifactDefinition, ItemSlot] = {}
## Artefact dont le sceau « Vendre (n) » est montre, -1 si aucun ; prix de vente de chaque artefact affiche.
var _selling: int = -1
var _sell_prices: Array = []
var _seal: Button


func _ready() -> void:
	add_child(_group(_artifact_caption, _artifact_slots))
	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(spacer)
	add_child(_group(_pill_caption, _pill_slots))


## sell_prices[i] : pierres rendues par la vente de l'artefact i. Vide : artefacts non vendables.
## stacks : crans des artefacts qui grandissent (RunState.artifact_stacks), rappeles dans leur infobulle.
func show_artifacts(artifacts: Array[ArtifactDefinition], max_count: int, sell_prices: Array = [], stacks: Dictionary = {}) -> void:
	_artifact_caption.text = tr("UI_ITEMS_ARTIFACTS") % [artifacts.size(), max_count]
	_clear(_artifact_slots)
	_slot_of.clear()
	_selling = -1
	_seal = null
	_sell_prices = sell_prices
	for i: int in maxi(max_count, artifacts.size()):
		var slot := _slot(ItemSlot.Kind.ARTIFACT, _artifact_slots)
		if i < artifacts.size():
			slot.picture = artifacts[i].icon
			slot.rarity = artifacts[i].rarity
			_fill(slot, artifacts[i].glyph, artifacts[i].name_key, artifacts[i].description_key)
			if artifacts[i].growth_step != 0.0:
				slot.description += "\n" + tr("UI_ARTIFACT_STACKS") % stacks.get(artifacts[i].id, 0)
			_slot_of[artifacts[i]] = slot
			if i < sell_prices.size():
				slot.pressed.connect(press_artifact.bind(i))


## usable[i] : la pilule i peut servir sur la selection actuelle.
func show_pills(pills: Array[PillDefinition], max_count: int, usable: Array[bool]) -> void:
	_pill_caption.text = tr("UI_ITEMS_PILLS") % [pills.size(), max_count]
	_clear(_pill_slots)
	for i: int in maxi(max_count, pills.size()):
		var slot := _slot(ItemSlot.Kind.PILL, _pill_slots)
		if i < pills.size():
			_fill(slot, pills[i].glyph, pills[i].name_key, pills[i].description_key)
			slot.disabled = not usable[i]
			slot.pressed.connect(pill_pressed.emit.bind(i))


## Premier appui : montre le sceau « Vendre (n) » sous l'artefact. Second appui sur le meme : le vend.
func press_artifact(index: int) -> void:
	if index < 0 or index >= _sell_prices.size():
		return
	if _seal != null:
		_seal.queue_free()
		_seal = null
	if _selling == index:
		_selling = -1
		artifact_sell_requested.emit(index)
		return
	_selling = index
	var slot: ItemSlot = _artifact_slots.get_child(index)
	_seal = Button.new()
	_seal.theme_type_variation = &"SellSeal"
	_seal.focus_mode = FOCUS_NONE
	_seal.text = tr("UI_SELL") % _sell_prices[index]
	_seal.pressed.connect(press_artifact.bind(index))
	slot.add_child(_seal)
	_seal.reset_size()
	_seal.position = Vector2((slot.size.x - _seal.size.x) / 2.0, slot.size.y)


## Clavier : appuie sur l'artefact sous la souris. Faux s'il n'y en a pas.
func press_hovered_artifact() -> bool:
	for i: int in _sell_prices.size():
		var slot: ItemSlot = _artifact_slots.get_child(i)
		if slot.get_global_rect().has_point(slot.get_global_mouse_position()):
			press_artifact(i)
			return true
	return false


## Centre du premier emplacement libre (ou un achat de la boutique va se poser), Vector2.INF si tout est pris.
func next_free_center(kind: ItemSlot.Kind) -> Vector2:
	var slots := _pill_slots if kind == ItemSlot.Kind.PILL else _artifact_slots
	for slot: ItemSlot in slots.get_children():
		if slot.is_empty():
			return slot.get_global_rect().get_center()
	return Vector2.INF


## Fait bondir et luire l'emplacement de l'artefact et renvoie son centre, d'ou part l'orbe de qi.
## Vector2.INF si l'artefact n'est pas affiche.
func artifact_hit(artifact: ArtifactDefinition) -> Vector2:
	var slot: ItemSlot = _slot_of.get(artifact)
	if slot == null:
		return Vector2.INF
	if not settings.reduce_motion:
		slot.pulse(feel.slot_pulse_scale, feel.slot_pulse_time)
	slot.glow(0.0 if settings.reduce_motion else feel.glow_time)
	return slot.get_global_rect().get_center()


func _group(caption: Label, slots: HBoxContainer) -> VBoxContainer:
	var group := VBoxContainer.new()
	group.add_child(caption)
	group.add_child(slots)
	return group


func _slot(kind: ItemSlot.Kind, parent: HBoxContainer) -> ItemSlot:
	var slot := ItemSlot.new()
	slot.kind = kind
	parent.add_child(slot)
	return slot


func _fill(slot: ItemSlot, glyph: String, name_key: String, description_key: String) -> void:
	slot.glyph = glyph
	slot.mouse_filter = MOUSE_FILTER_STOP
	slot.set_info(tr(name_key), tr(description_key))
	slot.queue_redraw()


func _clear(parent: Node) -> void:
	for child: Node in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
