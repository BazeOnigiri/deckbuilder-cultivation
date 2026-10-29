class_name Keys
extends RefCounted
## Actions du clavier (InputMap, definies dans project.godot) et leur nom de touche a afficher.
## Touches physiques : D, R, E, V et les chiffres sont a la meme place en AZERTY et en QWERTY.

## Actions montrees dans l'onglet Touches de la Voie de cultivation, avec leur texte.
const LISTED := [
	[&"select_card_1", "UI_KEYS_SELECT"], [&"play_hand", "UI_KEYS_PLAY"], [&"discard_hand", "UI_KEYS_DISCARD"],
	[&"deselect_cards", "UI_KEYS_DESELECT"], [&"sort_by_rank", "UI_KEYS_SORT_RANK"],
	[&"sort_by_element", "UI_KEYS_SORT_ELEMENT"], [&"show_deck", "UI_KEYS_DECK"], [&"show_path", "UI_KEYS_PATH"],
	[&"sell_artifact", "UI_KEYS_SELL"], [&"show_options", "UI_KEYS_OPTIONS"],
	[&"ui_cancel", "UI_KEYS_CLOSE"],
]
## Selection d'une carte par sa place dans la main : select_card_1, select_card_2...
const SELECT_PREFIX := "select_card_"


## Boutons de manette, noms de la disposition Xbox (la plus repandue) : identiques dans toutes les langues.
const JOY_BUTTONS := {JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "Select", JOY_BUTTON_START: "Start", JOY_BUTTON_LEFT_SHOULDER: "LB",
	JOY_BUTTON_RIGHT_SHOULDER: "RB", JOY_BUTTON_DPAD_UP: "↑", JOY_BUTTON_DPAD_DOWN: "↓",
	JOY_BUTTON_DPAD_LEFT: "←", JOY_BUTTON_DPAD_RIGHT: "→"}
const JOY_AXES := {JOY_AXIS_TRIGGER_LEFT: "LT", JOY_AXIS_TRIGGER_RIGHT: "RT"}


## Nom de la touche de l'action : bouton de manette si une manette est branchee (et que l'action en a un),
## sinon premiere touche du clavier, dans la disposition du joueur (« A » en AZERTY...).
static func name_of(action: StringName, joypad: bool = not Input.get_connected_joypads().is_empty()) -> String:
	var events: Array[InputEvent] = InputMap.action_get_events(action) if InputMap.has_action(action) else []
	if joypad:
		for event: InputEvent in events:
			var joy := joy_name(event)
			if not joy.is_empty():
				return joy
	for event: InputEvent in events:
		var key := event as InputEventKey
		if key == null:
			continue
		if key.physical_keycode == KEY_NONE:
			return OS.get_keycode_string(key.keycode)
		# Sans ecran (headless, tests) pas de disposition de clavier : la touche physique elle-meme.
		if DisplayServer.get_name() == "headless":
			return OS.get_keycode_string(key.physical_keycode)
		return OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(key.physical_keycode))
	return ""


## Nom d'un bouton ou d'une gachette de manette, vide pour un autre evenement.
static func joy_name(event: InputEvent) -> String:
	var button := event as InputEventJoypadButton
	if button != null:
		return JOY_BUTTONS.get(button.button_index, "")
	var motion := event as InputEventJoypadMotion
	if motion != null:
		return JOY_AXES.get(motion.axis, "")
	return ""


## Texte d'une aide qui cite des touches : les %s sont remplis avec les noms lus dans l'InputMap.
static func text_of(text_key: String) -> String:
	var text := TranslationServer.translate(text_key)
	match text_key:
		"UI_KEYS_SELECT":
			var last := 1
			while InputMap.has_action(SELECT_PREFIX + str(last + 1)):
				last += 1
			return text % [name_of(&"select_card_1"), name_of(StringName(SELECT_PREFIX + str(last)))]
		"UI_KEYS_DESELECT":
			return text % name_of(&"deselect_cards")
		"UI_DECK_VIEW_CLOSE":
			return text % name_of(&"ui_cancel")
	return text


## Place (0 = premiere carte) choisie par cet evenement, ou -1.
static func card_index(event: InputEvent, count: int) -> int:
	for i: int in count:
		var action := StringName(SELECT_PREFIX + str(i + 1))
		if InputMap.has_action(action) and event.is_action_pressed(action):
			return i
	return -1
