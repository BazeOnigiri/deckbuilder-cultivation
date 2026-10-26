class_name ItemRow
extends HBoxContainer
## Rangee haute de l'ecran de round : emplacements d'artefacts a gauche, de pilules a droite.
## Affichage seulement : round_screen lui passe le contenu de la run, et recoit pill_pressed.

signal pill_pressed(index: int)

## Bond d'un artefact qui se declenche : meme rythme que la sequence de score.
var feel: ScoreFeel = preload("res://ui/round/score_feel.tres")
var settings: GameSettings = GameSettings.new()

var _artifact_caption := SideColumn.make_label(&"SideCaption")
var _artifact_slots := HBoxContainer.new()
var _pill_caption := SideColumn.make_label(&"SideCaption")
var _pill_slots := HBoxContainer.new()
## Emplacement de chaque artefact affiche, pour le faire bondir pendant la sequence.
var _slot_of: Dictionary[ArtifactDefinition, ItemSlot] = {}


func _ready() -> void:
	add_child(_group(_artifact_caption, _artifact_slots))
	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(spacer)
	add_child(_group(_pill_caption, _pill_slots))


func show_artifacts(artifacts: Array[ArtifactDefinition], max_count: int) -> void:
	_artifact_caption.text = tr("UI_ITEMS_ARTIFACTS") % [artifacts.size(), max_count]
	_clear(_artifact_slots)
	_slot_of.clear()
	for i: int in maxi(max_count, artifacts.size()):
		var slot := _slot(ItemSlot.Kind.ARTIFACT, _artifact_slots)
		if i < artifacts.size():
			_fill(slot, artifacts[i].glyph, artifacts[i].name_key, artifacts[i].description_key)
			_slot_of[artifacts[i]] = slot


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


## Fait bondir l'emplacement de l'artefact et renvoie ou poser sa popup (sous l'emplacement).
## Vector2.INF si l'artefact n'est pas affiche.
func artifact_hit(artifact: ArtifactDefinition) -> Vector2:
	var slot: ItemSlot = _slot_of.get(artifact)
	if slot == null:
		return Vector2.INF
	if not settings.reduce_motion:
		slot.pulse(feel.slot_pulse_scale, feel.slot_pulse_time)
	var rect := slot.get_global_rect()
	return Vector2(rect.get_center().x, rect.end.y + feel.popup_font_size)


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
	slot.tooltip_text = tr(name_key) + "\n" + tr(description_key)
	slot.queue_redraw()


func _clear(parent: Node) -> void:
	for child: Node in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
