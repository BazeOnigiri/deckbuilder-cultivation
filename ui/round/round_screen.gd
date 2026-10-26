extends Control
## Ecran de run : affiche et fait jouer la run, et la sauvegarde apres chaque action.
## Contenu, stockage et run a reprendre sont injectes par main.

signal menu_requested
## Emis avant le debut de la run : main y branche le suivi du profil.
signal run_created(run: RunState, resumed: bool)

## Injecte par main avant add_child. Vide : contenu charge par defaut (scene lancee seule, tests).
var content: GameContent
## Vide : aucune sauvegarde (tests, scene lancee seule).
var run_storage: SaveStorage
## Sauvegarde a reprendre. Vide : nouvelle run.
var resume_data: Dictionary = {}
## Injecte par main. Par defaut des reglages neufs (scene lancee seule, tests).
var settings: GameSettings = GameSettings.new()

## Debug : artefacts donnes au debut d'une nouvelle run (inspecteur). Ignores dans une build release.
@export var debug_artifacts: Array[ArtifactDefinition] = []

var _run: RunState
## null quand aucun round n'est en cours (run reprise dans la boutique).
var _round: RoundState
## La boutique ouverte entre deux goulots, null pendant un round.
var _shop: ShopState
var _rules: RoundRules
var _stage: String = ""
var _rng: RandomNumberGenerator

@onready var _info: Label = %Info
@onready var _last_hand: Label = %LastHand
@onready var _hand_view: HandView = %HandRow
@onready var _play_button: Button = %PlayButton
@onready var _discard_button: Button = %DiscardButton
@onready var _continue_button: Button = %ContinueButton
@onready var _menu_button: Button = %MenuButton
@onready var _artifacts_label: Label = %Artifacts
@onready var _shop_panel: ShopPanel = %ShopPanel
@onready var _pill_row: HBoxContainer = %PillRow


func _ready() -> void:
	if content == null:
		content = GameContent.load_default()
	_rules = content.round_rules
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	if not resume_data.is_empty():
		_run = RunSnapshot.restore(resume_data, content, _rng)
	var resumed: bool = _run != null
	if not resumed:
		_run = content.new_run(_rng)
		if OS.is_debug_build():
			_run.artifacts.append_array(debug_artifacts)
	_run.round_started.connect(_on_round_started)
	_run.round_won.connect(_on_round_won)
	_run.finished.connect(_on_run_finished)
	_play_button.pressed.connect(_on_play_pressed)
	_discard_button.pressed.connect(_on_discard_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	_menu_button.pressed.connect(menu_requested.emit)
	_shop_panel.changed.connect(_refresh)
	_hand_view.settings = settings
	_hand_view.selection_changed.connect(_on_selection_changed)
	%InfoButton.pressed.connect(_show_run_info)
	_continue_button.hide()
	_menu_button.hide()
	run_created.emit(_run, resumed)
	if not resumed:
		_run.start()
	elif not RunSnapshot.resume_round(resume_data, _run):
		# Sauvegarde prise dans la boutique : on la rouvre avec ses offres d'origine.
		_shop = RunSnapshot.restore_shop(resume_data, _run, content, _rng)
		_stage = _stage_text()
		_shop_panel.open(_shop)
		_continue_button.show()
	_refresh()


## Appele apres chaque action : redessine, puis sauvegarde (comme Balatro).
func _refresh() -> void:
	var round_info: String = ""
	if _round != null:
		round_info = "\n" + tr("UI_ROUND_INFO") % [_round.score, _round.target_score, _round.hands_left, _round.discards_left]
	_info.text = _stage + "    " + tr("UI_STONES") % _run.stones + round_info
	var cards: Array[CardInstance] = []
	if _round != null:
		cards.assign(_round.hand())
	cards.sort_custom(func(a: CardInstance, b: CardInstance) -> bool: return a.rank < b.rank)
	_hand_view.set_cards(cards)
	_on_selection_changed()
	var names: Array[String] = []
	var descriptions: Array[String] = []
	for artifact: ArtifactDefinition in _run.artifacts:
		names.append(tr(artifact.name_key))
		descriptions.append(tr(artifact.name_key) + " : " + tr(artifact.description_key))
	_artifacts_label.text = tr("UI_ARTIFACTS") % (", ".join(names) if not names.is_empty() else tr("UI_NONE"))
	_artifacts_label.tooltip_text = "\n".join(descriptions)
	_save_run()


func _selected() -> Array[CardInstance]:
	var cards: Array[CardInstance] = []
	for view: CardView in _hand_view.get_children():
		if view.button_pressed:
			cards.append(view.card)
	return cards


func _on_selection_changed() -> void:
	var count: int = _selected().size()
	var can_act: bool = (_round != null and _round.status == RoundState.Status.PLAYING
		and count > 0 and count <= _rules.max_selected_cards)
	_play_button.disabled = not can_act
	_discard_button.disabled = not can_act or _round.discards_left == 0
	_refresh_pills()


## Les boutons de pilules dependent de la selection : reconstruits a chaque changement.
func _refresh_pills() -> void:
	for child: Node in _pill_row.get_children():
		_pill_row.remove_child(child)
		child.queue_free()
	var selected := _selected()
	for i: int in _run.pills.size():
		var pill: PillDefinition = _run.pills[i]
		var button := Button.new()
		button.text = tr("UI_USE_PILL") % tr(pill.name_key)
		button.tooltip_text = tr(pill.description_key)
		button.disabled = not _run.can_use_pill(i, selected)
		button.pressed.connect(_on_pill_pressed.bind(i))
		_pill_row.add_child(button)


func _on_pill_pressed(index: int) -> void:
	_run.use_pill(index, _selected())
	_refresh()


func _on_round_started(round_state: RoundState) -> void:
	_round = round_state
	_round.hand_played.connect(_on_hand_played)
	# Nom du goulot fige au debut du round : progress avance des la victoire.
	_stage = _stage_text()
	_last_hand.text = ""


func _stage_text() -> String:
	var progress := _run.progress
	var text: String = tr("UI_STAGE") % [tr(progress.current_realm().name_key), tr(progress.current_bottleneck().name_key)]
	var constraint: TribulationConstraint = progress.current_bottleneck().constraint
	if constraint != null:
		text += "\n" + tr(constraint.description_key)
	return text


func _on_play_pressed() -> void:
	_round.play(_selected())
	_refresh()


func _on_discard_pressed() -> void:
	_round.discard(_selected())
	_refresh()


func _on_continue_pressed() -> void:
	_shop_panel.hide()
	_continue_button.hide()
	_shop = null
	_run.next_round()
	_refresh()


func _on_hand_played(result: HandResult, score: ScoreContext) -> void:
	var level: int = _run.hand_levels.level_of(result.definition.id)
	_last_hand.text = tr("UI_LAST_HAND") % [tr(result.definition.name_key), level, score.qi, score.comprehension, score.total()]


func _on_round_won(reward: RoundReward) -> void:
	_last_hand.text += "\n" + tr("UI_ROUND_WON")
	_last_hand.text += "\n" + tr("UI_REWARD") % [reward.total(), reward.base, reward.hands, reward.interest]
	_shop = content.new_shop(_run, _rng)
	_shop_panel.open(_shop)
	_continue_button.show()


func _on_run_finished(won: bool) -> void:
	_last_hand.text += "\n" + tr("UI_RUN_WON" if won else "UI_RUN_LOST")
	_menu_button.show()
	# Run terminee : plus rien a reprendre. _save_run() ne reecrira pas, can_capture est faux.
	if run_storage != null:
		run_storage.delete()


func _save_run() -> void:
	if run_storage == null or not RunSnapshot.can_capture(_run):
		return
	if _run.status == RunState.Status.BETWEEN_ROUNDS and _shop == null:
		return
	if not run_storage.save(RunSnapshot.capture(_run, _shop, _rng)):
		push_warning("Run non sauvegardee : %s" % run_storage.last_error)


func _show_run_info() -> void:
	var dialog := RunInfoDialog.new()
	dialog.setup(_run, content.hands)
	add_child(dialog)
	dialog.popup_centered(RunInfoDialog.SIZE)