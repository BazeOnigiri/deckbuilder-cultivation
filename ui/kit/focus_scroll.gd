class_name FocusScroll
extends ScrollContainer
## Zone defilante qui prend le focus : haut et bas la font defiler au clavier et a la manette. En haut ou en bas
## de la zone, l'entree n'est pas prise et le focus passe au Control voisin (ex. les signets).
## Pas du defilement dans le Theme (FocusNav/constants/scroll_step).


func _init() -> void:
	focus_mode = Control.FOCUS_ALL
	theme_type_variation = &"ScrollFocus"


func _gui_input(event: InputEvent) -> void:
	var direction := 0
	if event.is_action_pressed(&"ui_down", true):
		direction = 1
	elif event.is_action_pressed(&"ui_up", true):
		direction = -1
	if direction == 0:
		return
	var before := scroll_vertical
	scroll_vertical += direction * get_theme_constant(&"scroll_step", &"FocusNav")
	if scroll_vertical != before:
		accept_event()
