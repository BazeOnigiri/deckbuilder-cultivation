class_name KeyBindings
extends RefCounted
## Touches du clavier choisies par le joueur, par-dessus celles de project.godot.
## bindings : {nom d'action (String) : touche physique (int)}. Une action absente garde ses touches par defaut.
## Seules les touches du clavier changent : les boutons de manette et la souris restent ceux de project.godot.

## Actions de jeu dont la touche se change dans les options.
const ACTIONS: Array[StringName] = [&"play_hand", &"discard_hand", &"deselect_cards", &"sort_by_rank",
	&"sort_by_element", &"show_deck", &"show_path", &"sell_artifact", &"show_options"]
## Touches fixes : naviguer, valider, fermer, et choisir une carte par sa place. Une action de jeu ne peut pas les prendre.
const RESERVED: Array[StringName] = [&"ui_accept", &"ui_cancel", &"ui_up", &"ui_down", &"ui_left", &"ui_right"]
const RESERVED_PREFIX := "select_card_"


## Touches de l'action : celle choisie par le joueur, sinon celles de project.godot.
static func keys_of(action: StringName, bindings: Dictionary) -> Array[int]:
	if bindings.has(String(action)):
		return [int(bindings[String(action)])]
	var keys: Array[int] = []
	for event: InputEvent in _defaults(action):
		var key := event as InputEventKey
		if key != null:
			keys.append(key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode)
	return keys


## Action qui utilise deja cette touche (de jeu ou reservee), &"" si aucune.
static func owner_of(keycode: int, bindings: Dictionary) -> StringName:
	for action: StringName in ACTIONS:
		if keys_of(action, bindings).has(keycode):
			return action
	for action: StringName in InputMap.get_actions():
		if (RESERVED.has(action) or String(action).begins_with(RESERVED_PREFIX)) and keys_of(action, {}).has(keycode):
			return action
	return &""


## Donne la touche a l'action. Touche d'une autre action de jeu : les deux echangent leurs touches.
## Touche reservee : refus, rien ne change. N'applique pas : appeler apply() ensuite.
static func rebind(bindings: Dictionary, action: StringName, keycode: int) -> bool:
	if not ACTIONS.has(action) or keycode == KEY_NONE:
		return false
	var other := owner_of(keycode, bindings)
	if other == action:
		return true
	if other != &"" and not ACTIONS.has(other):
		return false
	if other != &"":
		# Chaque action de jeu a une touche par defaut (teste) : l'autre recoit la premiere.
		bindings[String(other)] = keys_of(action, bindings)[0]
	bindings[String(action)] = keycode
	return true


## Remet dans l'InputMap les touches de project.godot, remplacees par celles du joueur la ou il en a choisi.
static func apply(bindings: Dictionary) -> void:
	for action: StringName in ACTIONS:
		if not InputMap.has_action(action):
			continue
		var chosen := bindings.has(String(action))
		InputMap.action_erase_events(action)
		for event: InputEvent in _defaults(action):
			if not (chosen and event is InputEventKey):
				InputMap.action_add_event(action, event)
		if chosen:
			var key := InputEventKey.new()
			key.physical_keycode = int(bindings[String(action)]) as Key
			key.device = -1
			InputMap.action_add_event(action, key)


## Le fichier vient du disque du joueur : seules les actions connues avec une touche valable sont gardees.
static func sanitized(data: Variant) -> Dictionary:
	var bindings := {}
	if not data is Dictionary:
		return bindings
	for action: Variant in data:
		var keycode: Variant = data[action]
		if action is String and ACTIONS.has(StringName(action)) and (keycode is int or keycode is float) and int(keycode) > 0:
			bindings[action] = int(keycode)
	return bindings


static func _defaults(action: StringName) -> Array:
	var setting: Variant = ProjectSettings.get_setting("input/" + action, {})
	return setting.get("events", []) if setting is Dictionary else []
