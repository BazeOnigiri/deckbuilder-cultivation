class_name Keys
extends RefCounted
## Actions du clavier (InputMap, definies dans project.godot) et leur nom de touche a afficher.
## Touches physiques : D, R, E, V et les chiffres sont a la meme place en AZERTY et en QWERTY.

## Actions montrees dans l'onglet Touches de la Voie de cultivation, avec leur texte.
const LISTED := [
	[&"select_card_1", "UI_KEYS_SELECT"], [&"play_hand", "UI_KEYS_PLAY"], [&"discard_hand", "UI_KEYS_DISCARD"],
	[&"deselect_cards", "UI_KEYS_DESELECT"], [&"sort_by_rank", "UI_KEYS_SORT_RANK"],
	[&"sort_by_element", "UI_KEYS_SORT_ELEMENT"], [&"show_deck", "UI_KEYS_DECK"], [&"show_path", "UI_KEYS_PATH"],
	[&"sell_artifact", "UI_KEYS_SELL"],
	[&"ui_cancel", "UI_KEYS_CLOSE"],
]
## Selection d'une carte par sa place dans la main : select_card_1, select_card_2...
const SELECT_PREFIX := "select_card_"


## Nom de la premiere touche de l'action, dans la disposition du clavier du joueur (« A » en AZERTY...).
static func name_of(action: StringName) -> String:
	for event: InputEvent in InputMap.action_get_events(action) if InputMap.has_action(action) else []:
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
