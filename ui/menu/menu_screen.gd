extends Control
## Menu principal : nouvelle partie, statistiques, credits.

signal start_requested
signal stats_requested


func _ready() -> void:
	%StartButton.pressed.connect(start_requested.emit)
	%StatsButton.pressed.connect(stats_requested.emit)
	%CreditsButton.pressed.connect(_show_credits)


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