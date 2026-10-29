extends Control
## Menu principal « 五行 Wu Xing » : rouleau suspendu des choix a gauche, lune et meditant entoure des cinq phases a droite.
## Nouvelle partie avec une run sauvegardee : un rouleau resume la run et propose de la continuer ou de recommencer.

signal start_requested
signal continue_requested
signal stats_requested
signal options_requested
## L'aide vient d'etre proposee : main s'en souvient pour ne plus la reproposer.
signal help_offered
signal quit_requested

## Les licences OFL imposent d'accompagner les polices ; export_presets.cfg les inclut dans le pck.
const FONT_LICENSES: Array[String] = ["res://ui/fonts/OFL-NotoSerif.txt", "res://ui/fonts/OFL-MaShanZheng.txt"]

## Apercu de la run sauvegardee, null si aucune. Injecte par main avant add_child.
var saved_run: RunState
## Injecte par main avant add_child. Par defaut des reglages neufs (scene lancee seule, tests).
var settings: GameSettings = GameSettings.new()
## Injecte par main avant add_child. Par defaut le contenu du jeu, charge au premier besoin (scene lancee seule, tests).
var content: GameContent
## Vrai a la toute premiere partie : Nouvelle partie propose d'abord l'aide, une seule fois.
var offer_help: bool = false


func _ready() -> void:
	%ContinueButton.visible = saved_run != null
	%ContinueButton.pressed.connect(continue_requested.emit)
	%StartButton.pressed.connect(_show_play_scroll)
	%StatsButton.pressed.connect(stats_requested.emit)
	%OptionsButton.pressed.connect(options_requested.emit)
	%HelpButton.pressed.connect(_show_help)
	%CreditsButton.pressed.connect(_show_credits)
	# Dans un navigateur, quitter n'a pas de sens : on ferme l'onglet.
	%QuitButton.visible = not OS.has_feature("web")
	%QuitButton.pressed.connect(quit_requested.emit)
	for button: InkButton in [%ContinueButton, %StartButton, %StatsButton, %OptionsButton, %HelpButton, %CreditsButton, %QuitButton]:
		button.reduce_motion = settings.reduce_motion
	%Orbit.reduce_motion = settings.reduce_motion
	%Scroll.custom_minimum_size.x = get_theme_constant(&"menu_width", &"ScrollPanel")
	%Gap.custom_minimum_size.y = get_theme_constant(&"menu_gap", &"ScrollPanel")
	%Scroll.unroll(0.0 if settings.reduce_motion else get_theme_constant(&"unroll_ms", &"ScrollPanel") / 1000.0)
	Focus.grab_first(%Scroll)


## Sans run sauvegardee, rien a confirmer : la partie commence.
func _show_play_scroll() -> void:
	if saved_run == null:
		if offer_help:
			_show_help_offer()
		else:
			start_requested.emit()
		return
	var body := VBoxContainer.new()
	body.custom_minimum_size.x = get_theme_constant(&"text_width", &"ScrollPanel")
	var progress := saved_run.progress
	body.add_child(ScrollRows.row("UI_SAVED_STAGE", tr("UI_STAGE") % [tr(progress.current_realm().name_key), tr(progress.current_bottleneck().name_key)]))
	var stone_icon: Array[Control] = [StoneIcon.new()]
	body.add_child(ScrollRows.row("UI_SAVED_STONES", str(saved_run.stones), stone_icon))
	var icons: Array[Control] = []
	for artifact: ArtifactDefinition in saved_run.artifacts:
		icons.append(_artifact_icon(artifact))
	body.add_child(ScrollRows.row("UI_SAVED_ARTIFACTS", "" if not icons.is_empty() else tr("UI_NONE"), icons))
	body.add_child(ScrollRows.row("UI_SAVED_PILLS", _names(saved_run.pills)))
	if not saved_run.legacies.is_empty():
		body.add_child(ScrollRows.row("UI_SAVED_LEGACIES", ""))
		var legacy_row := HFlowContainer.new()
		for slot: ItemSlot in RunInfo.legacy_slots(saved_run.legacies):
			legacy_row.add_child(slot)
		body.add_child(legacy_row)
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


## Premiere partie : lire l'aide d'abord, ou commencer. Proposee une seule fois.
func _show_help_offer() -> void:
	offer_help = false
	help_offered.emit()
	var body := VBoxContainer.new()
	var text := SideColumn.make_label(&"ScrollText", "UI_HELP_OFFER")
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size.x = get_theme_constant(&"text_width", &"ScrollPanel")
	body.add_child(text)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override(&"separation", get_theme_constant(&"separation", &"ScrollPanel"))
	var read := Button.new()
	read.theme_type_variation = &"SealButton"
	read.text = "UI_HELP_OPEN"
	actions.add_child(read)
	actions.add_child(_seal("UI_HELP_START", start_requested))
	body.add_child(actions)
	var overlay := ScrollOverlay.open(self, "UI_NEW_RUN", body, not settings.reduce_motion)
	overlay.hide_close()
	read.pressed.connect(func() -> void:
		overlay.close()
		_show_help())


func _show_help() -> void:
	if content == null:
		content = GameContent.load_default()
	ScrollOverlay.open(self, "UI_HELP", HelpPages.scroll(content), not settings.reduce_motion)


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
	var text := RichTextLabel.new()
	text.theme_type_variation = &"ScrollRichText"
	# Focalisable : les fleches et la manette font defiler le texte.
	text.focus_mode = FOCUS_ALL
	text.custom_minimum_size = Vector2(get_theme_constant(&"credits_width", &"ScrollPanel"),
		get_theme_constant(&"tab_height", &"ScrollPanel"))
	var parts: Array[String] = [tr("UI_CREDITS_GAME"), tr("UI_CREDITS_FONTS"), tr("UI_CREDITS_SOUNDS")]
	for path in FONT_LICENSES:
		parts.append(FileAccess.get_file_as_string(path))
	parts.append(tr("UI_CREDITS_INTRO"))
	parts.append(Engine.get_license_text())
	parts.append(ThirdPartyCredits.build(Engine.get_copyright_info(), Engine.get_license_info()))
	text.text = "\n\n".join(parts)
	ScrollOverlay.open(self, "UI_CREDITS", text, not settings.reduce_motion)
