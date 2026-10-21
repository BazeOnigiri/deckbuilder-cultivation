extends Control
## Menu principal.

signal start_requested


func _ready() -> void:
	%StartButton.pressed.connect(start_requested.emit)