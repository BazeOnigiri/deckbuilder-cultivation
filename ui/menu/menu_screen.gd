extends Control
## Menu principal « 五行 Wu Xing » : rouleau suspendu des choix a gauche, lune et meditant entoure des cinq phases a droite.
## Nouvelle partie avec une run sauvegardee : un rouleau resume la run et propose de la continuer ou de recommencer.

signal start_requested
signal continue_requested
signal stats_requested
signal options_requested

## Apercu de la run sauvegardee, null si aucune. Injecte par main avant add_child.
var saved_run: RunState
## Injecte par main avant add_child. Par defaut des reglages neufs (scene lancee seule, tests).
var settings: GameSettings = GameSettings.new()


func _ready() -> void:
	%ContinueButton.visible = saved_run != null
	%ContinueButton.pressed.connect(continue_requested.emit)
	%StartButton.pressed.connect(_show_play_scroll)
	%StatsButton.pressed.connect(stats_requested.emit)
	%OptionsButton.pressed.connect(options_requested.emit)
	%CreditsButton.pressed.connect(_show_credits)
	for button: InkButton in [%ContinueButton, %StartButton, %StatsButton, %OptionsButton, %CreditsButton]:
		button.reduce_motion = settings.reduce_motion
	%Orbit.reduce_motion = settings.reduce_motion
	%Scroll.unroll(0.0 if settings.reduce_motion else get_theme_constant(&"unroll_ms", &"ScrollPanel") / 1000.0)


## Sans run sauvegardee, rien a confirmer : la partie commence.
func _show_play_scroll() -> void:
	if saved_run == null:
		start_requested.emit()
		return
	var body := VBoxContainer.new()
	var progress := saved_run.progress
	body.add_child(_row("UI_SAVED_STAGE", tr("UI_STAGE") % [tr(progress.current_realm().name_key), tr(progress.current_bottleneck().name_key)]))
	var stones := _row("UI_SAVED_STONES", str(saved_run.stones))
	stones.add_child(StoneIcon.new())
	body.add_child(stones)
	var artifacts := _row("UI_SAVED_ARTIFACTS", "" if not saved_run.artifacts.is_empty() else tr("UI_NONE"))
	for artifact: ArtifactDefinition in saved_run.artifacts:
		artifacts.add_child(_artifact_icon(artifact))
	body.add_child(artifacts)
	body.add_child(_row("UI_SAVED_PILLS", _names(saved_run.pills)))
	var warning := SideColumn.make_label(&"ScrollCaption", "UI_NEW_RUN_WARNING")
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning.custom_minimum_size.x = get_theme_constant(&"text_width", &"ScrollPanel")
	body.add_child(warning)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override(&"separation", get_theme_constant(&"separation", &"ScrollPanel"))
	actions.add_child(_seal("UI_CONTINUE", continue_requested))
	actions.add_child(_seal("UI_ABANDON_RESTART", start_requested))
	body.add_child(actions)
	# Deux choix explicites : pas de sceau Fermer en plus (Echap et le clic a cote ferment toujours).
	ScrollOverlay.open(self, "UI_NEW_RUN", body, not settings.reduce_motion).hide_close()


func _row(name_key: String, value: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var name_label := SideColumn.make_label(&"ScrollCaption", name_key)
	name_label.custom_minimum_size.x = get_theme_constant(&"label_width", &"ScrollPanel")
	row.add_child(name_label)
	var value_label := SideColumn.make_label(&"ScrollText")
	value_label.text = value
	row.add_child(value_label)
	return row


## Dessin de l'artefact a l'encre, son nom en infobulle.
func _artifact_icon(artifact: ArtifactDefinition) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = artifact.icon
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2.ONE * get_theme_constant(&"icon_size", &"ScrollPanel")
	icon.modulate = get_theme_color(&"font_color", &"ScrollText")
	icon.tooltip_text = tr(artifact.name_key)
	return icon


func _seal(text_key: String, pressed: Signal) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"SealButton"
	button.text = text_key
	button.pressed.connect(pressed.emit)
	return button


func _names(list: Array) -> String:
	var names: Array[String] = []
	for item: Resource in list:
		names.append(tr(item.name_key))
	return ", ".join(names) if not names.is_empty() else tr("UI_NONE")


## La licence MIT de Godot exige que son texte accompagne le jeu publie.
func _show_credits() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = tr("UI_CREDITS")
	var text := RichTextLabel.new()
	text.custom_minimum_size = Vector2(600, 400)
	text.text = tr("UI_CREDITS_INTRO") + "\n\n" + Engine.get_license_text()
	dialog.add_child(text)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()
