extends Control
## Ecran des reglages du joueur.

signal back_requested
## Emis a chaque changement : main sauvegarde et applique.
signal settings_changed

## Injecte par main avant l'ajout a l'arbre. Par defaut des reglages neufs (scene lancee seule, tests).
var settings: GameSettings = GameSettings.new()


func _ready() -> void:
	# Avant de brancher le signal : afficher la valeur ne doit pas compter comme un changement.
	%ReduceMotion.button_pressed = settings.reduce_motion
	%ReduceMotion.toggled.connect(_on_reduce_motion_toggled)
	%BackButton.pressed.connect(back_requested.emit)


func _on_reduce_motion_toggled(on: bool) -> void:
	settings.reduce_motion = on
	settings_changed.emit()
