class_name NewRunPanel
extends VBoxContainer
## Contenu du rouleau « Nouvelle partie » : graine, difficulte (niveaux ouverts du profil), tribulations fixes,
## puis Commencer, Partie du jour ou Defis. Emet la RunSetup choisie ; la logique est dans RunSetup.

signal start_requested(setup: RunSetup)

## Injectes avant add_child.
var content: GameContent
var profile: ProfileStats = ProfileStats.new()
var settings: GameSettings = GameSettings.new()
## Ou poser le rouleau des defis (l'ecran plein), par-dessus celui-ci.
var overlay_parent: Node

var seed_input := LineEdit.new()
var difficulty := OptionButton.new()
var classic := CheckButton.new()
var _description := SideColumn.make_label(&"ScrollCaption")
## Graines tirees au hasard : l'affichage peut utiliser la RNG globale, la run est ensuite semee par la graine.
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	var width: float = get_theme_constant(&"text_width", &"ScrollPanel")
	custom_minimum_size.x = width
	add_theme_constant_override(&"separation", get_theme_constant(&"separation", &"ScrollPanel"))
	seed_input.placeholder_text = "UI_SETUP_SEED_HINT"
	seed_input.max_length = RunSetup.CODE_LENGTH * 4
	seed_input.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(_line("UI_SETUP_SEED", seed_input))
	difficulty.theme_type_variation = &"ScrollOption"
	for level: DifficultyDefinition in content.difficulties:
		if level.level <= profile.difficulty_unlocked:
			difficulty.add_item(tr(level.name_key), level.level)
	difficulty.select(difficulty.item_count - 1)
	difficulty.item_selected.connect(func(_index: int) -> void: _describe())
	add_child(_line("UI_SETUP_DIFFICULTY", difficulty))
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.custom_minimum_size.x = width
	add_child(_description)
	_describe()
	classic.theme_type_variation = &"ScrollCheck"
	classic.text = "UI_SETUP_CLASSIC"
	add_child(classic)
	var actions := HFlowContainer.new()
	actions.alignment = FlowContainer.ALIGNMENT_CENTER
	actions.add_child(_seal("UI_SETUP_START", _start))
	actions.add_child(_seal("UI_SETUP_DAILY", _start_daily))
	actions.add_child(_seal("UI_SETUP_CHALLENGES", _show_challenges))
	add_child(actions)


func chosen_level() -> int:
	return difficulty.get_selected_id() if difficulty.item_count > 0 else 1


func _describe() -> void:
	var level := content.difficulty_of(chosen_level())
	_description.text = tr(level.description_key) if level != null else ""


func _start() -> void:
	start_requested.emit(RunSetup.custom(seed_input.text, chosen_level(), not classic.button_pressed,
		RunSetup.random_code(_rng)))


func _start_daily() -> void:
	start_requested.emit(RunSetup.for_daily(int(Time.get_unix_time_from_system())))


## Rouleau des defis par-dessus : nom, description, sceau Gagne pour ceux deja reussis.
func _show_challenges() -> void:
	var list := VBoxContainer.new()
	list.custom_minimum_size.x = get_theme_constant(&"text_width", &"ScrollPanel")
	for challenge: ChallengeDefinition in content.challenges:
		var button := Button.new()
		button.theme_type_variation = &"SealButton"
		button.text = challenge.name_key
		button.pressed.connect(func() -> void:
			start_requested.emit(RunSetup.for_challenge(challenge, RunSetup.random_code(_rng))))
		var extra: Array[Control] = [button]
		var won := profile.challenges_won.has(String(challenge.id))
		list.add_child(ScrollRows.row("UI_CHALLENGE_WON" if won else "", "", extra))
		var text := SideColumn.make_label(&"ScrollCaption", challenge.description_key)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.custom_minimum_size.x = list.custom_minimum_size.x
		list.add_child(text)
	ScrollOverlay.open(overlay_parent, "UI_CHALLENGES", list, not settings.reduce_motion)


func _line(label_key: String, control: Control) -> HBoxContainer:
	var line := HBoxContainer.new()
	var label := SideColumn.make_label(&"ScrollText", label_key)
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	line.add_child(label)
	line.add_child(control)
	return line


func _seal(text_key: String, action: Callable) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"SealButton"
	button.text = text_key
	button.pressed.connect(action)
	return button
