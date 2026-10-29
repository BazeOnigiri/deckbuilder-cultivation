class_name Focus
extends RefCounted
## Navigation au clavier et a la manette avec le focus natif des Controls (ui_up, ui_down, ui_left, ui_right).
## Chaque ecran et chaque rouleau pose son focus initial ; un rouleau ouvert garde le focus pour lui.

## Vrai si la derniere entree venait du clavier ou de la manette : le focus pose par le jeu se voit.
## A la souris ou au doigt, il est pose cache (pas de lueur sur une carte que le joueur n'a pas visee).
static var shown: bool = false


## Appele par main pour chaque entree.
static func note_input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		shown = shown or event.is_pressed()
	elif event is InputEventMouseButton or event is InputEventScreenTouch:
		shown = false


## Premier Control visible qui prend le focus sous root (root compris), null si aucun.
static func first_in(root: Node) -> Control:
	var control := root as Control
	if control != null:
		if not control.is_visible_in_tree():
			return null
		# Avec la surcharge : un voile par-dessus (Focus.trap) coupe le focus de tout ce qui est dessous.
		if control.get_focus_mode_with_override() != Control.FOCUS_NONE:
			return control
	for child: Node in root.get_children(true):
		var found := first_in(child)
		if found != null:
			return found
	return null


## Donne le focus au premier Control focalisable sous root. Faux s'il n'y en a pas.
static func grab_first(root: Node) -> bool:
	var target := first_in(root)
	if target == null:
		return false
	target.grab_focus(not shown)
	return true


## Vrai si le focus est sur un Control encore affiche.
static func is_held(viewport: Viewport) -> bool:
	var owner := viewport.gui_get_focus_owner()
	return owner != null and owner.is_visible_in_tree()


## Rouleau ou voile par-dessus l'ecran : ses freres ne prennent plus le focus tant qu'il est ouvert,
## et le focus revient a sa fermeture la ou il etait.
static func trap(overlay: Control) -> void:
	var before := overlay.get_viewport().gui_get_focus_owner()
	# Sinon valider agirait encore sur le Control derriere le voile.
	if before != null and not overlay.is_ancestor_of(before):
		before.release_focus()
	# References faibles : l'ecran dessous peut etre libere avant le rouleau (retour au menu).
	var saved: Array = []
	for node: Node in overlay.get_parent().get_children():
		var sibling := node as Control
		if sibling != null and sibling != overlay:
			saved.append([weakref(sibling), sibling.focus_behavior_recursive])
			sibling.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	var previous: WeakRef = weakref(before) if before != null else null
	overlay.tree_exiting.connect(func() -> void:
		for entry: Array in saved:
			var sibling := (entry[0] as WeakRef).get_ref() as Control
			if sibling != null:
				sibling.focus_behavior_recursive = entry[1]
		var focus := previous.get_ref() as Control if previous != null else null
		if focus != null and focus.is_visible_in_tree():
			focus.grab_focus(not shown), CONNECT_ONE_SHOT)
