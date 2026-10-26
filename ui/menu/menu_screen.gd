extends Control
## Menu principal : continuer, nouvelle partie, statistiques, options, credits.

signal start_requested
signal continue_requested
signal stats_requested
signal options_requested

## Apercu de la run sauvegardee, null si aucune. Injecte par main avant add_child.
var saved_run: RunState


func _ready() -> void:
	%ContinueButton.visible = saved_run != null
	%ContinueButton.pressed.connect(continue_requested.emit)
	%StartButton.pressed.connect(_show_play_dialog)
	%StatsButton.pressed.connect(stats_requested.emit)
	%OptionsButton.pressed.connect(options_requested.emit)
	%CreditsButton.pressed.connect(_show_credits)


func _show_play_dialog() -> void:
	var dialog := PlayDialog.new()
	dialog.setup(saved_run)
	dialog.new_run_requested.connect(start_requested.emit)
	dialog.continue_requested.connect(continue_requested.emit)
	add_child(dialog)
	dialog.popup_centered(PlayDialog.SIZE)


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