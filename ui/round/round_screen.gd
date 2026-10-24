extends Control
## Ecran de run. Racine de composition : cree la logique, l'injecte, et l'affiche.

signal menu_requested

const DECK_PATH := "res://content/decks/paquet_depart.tres"
const RULES_PATH := "res://content/rules/regles_base.tres"
const ECONOMY_PATH := "res://content/rules/economie_base.tres"
const SHOP_RULES_PATH := "res://content/rules/boutique_base.tres"

var _run: RunState
var _round: RoundState
var _rules: RoundRules
var _stage: String = ""
var _rng: RandomNumberGenerator
var _shop_rules: ShopRules
var _artifact_catalog: Array[ArtifactDefinition]
var _manual_catalog: Array[ManualDefinition]
var _pill_catalog: Array[PillDefinition]

## Debug : artefacts donnes au debut de la run (inspecteur de la scene). Ignores dans une build release.
@export var debug_artifacts: Array[ArtifactDefinition] = []

@onready var _info: Label = %Info
@onready var _last_hand: Label = %LastHand
@onready var _hand_row: HBoxContainer = %HandRow
@onready var _play_button: Button = %PlayButton
@onready var _discard_button: Button = %DiscardButton
@onready var _continue_button: Button = %ContinueButton
@onready var _menu_button: Button = %MenuButton
@onready var _credits_button: Button = %CreditsButton
@onready var _artifacts_label: Label = %Artifacts
@onready var _shop_panel: ShopPanel = %ShopPanel
@onready var _pill_row: HBoxContainer = %PillRow


func _ready() -> void:
	_rules = load(RULES_PATH)
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	_shop_rules = load(SHOP_RULES_PATH)
	_artifact_catalog = ArtifactCatalog.load_definitions()
	_manual_catalog = ManualCatalog.load_definitions()
	_pill_catalog = PillCatalog.load_definitions()
	var deck := DeckState.new(load(DECK_PATH), _rng)
	var evaluator := HandEvaluator.new(HandCatalog.load_definitions())
	_run = RunState.new(deck, _rules, evaluator, RunProgress.new(RealmCatalog.load_definitions()), load(ECONOMY_PATH))
	if OS.is_debug_build():
		_run.artifacts.append_array(debug_artifacts)
	_run.round_started.connect(_on_round_started)
	_run.round_won.connect(_on_round_won)
	_run.finished.connect(_on_run_finished)
	_play_button.pressed.connect(_on_play_pressed)
	_discard_button.pressed.connect(_on_discard_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	_menu_button.pressed.connect(menu_requested.emit)
	_credits_button.pressed.connect(_show_credits)
	_shop_panel.changed.connect(_refresh)
	_continue_button.hide()
	_menu_button.hide()
	_run.start()
	_refresh()


func _refresh() -> void:
	_info.text = _stage + "    " + tr("UI_STONES") % _run.stones + "\n" + tr("UI_ROUND_INFO") % [_round.score, _round.target_score, _round.hands_left, _round.discards_left]
	for child: Node in _hand_row.get_children():
		# remove_child tout de suite : queue_free seul laisse l'enfant compte jusqu'a la frame suivante.
		_hand_row.remove_child(child)
		child.queue_free()
	var cards: Array[CardInstance] = _round.hand().duplicate()
	cards.sort_custom(func(a: CardInstance, b: CardInstance) -> bool: return a.rank < b.rank)
	for card: CardInstance in cards:
		var view := CardView.new()
		view.card = card
		view.toggled.connect(_on_selection_changed.unbind(1))
		_hand_row.add_child(view)
	_on_selection_changed()
	var names: Array[String] = []
	var descriptions: Array[String] = []
	for artifact: ArtifactDefinition in _run.artifacts:
		names.append(tr(artifact.name_key))
		descriptions.append(tr(artifact.name_key) + " : " + tr(artifact.description_key))
	_artifacts_label.text = tr("UI_ARTIFACTS") % (", ".join(names) if not names.is_empty() else tr("UI_NONE"))
	_artifacts_label.tooltip_text = "\n".join(descriptions)


func _selected() -> Array[CardInstance]:
	var cards: Array[CardInstance] = []
	for view: CardView in _hand_row.get_children():
		if view.button_pressed:
			cards.append(view.card)
	return cards


func _on_selection_changed() -> void:
	var count: int = _selected().size()
	var can_act: bool = (_round.status == RoundState.Status.PLAYING
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
	var progress := _run.progress
	_stage = tr("UI_STAGE") % [tr(progress.current_realm().name_key), tr(progress.current_bottleneck().name_key)]
	var constraint: TribulationConstraint = progress.current_bottleneck().constraint
	if constraint != null:
		_stage += "\n" + tr(constraint.description_key)
	_last_hand.text = ""


func _on_play_pressed() -> void:
	_round.play(_selected())
	_refresh()


func _on_discard_pressed() -> void:
	_round.discard(_selected())
	_refresh()


func _on_continue_pressed() -> void:
	_shop_panel.hide()
	_continue_button.hide()
	_run.next_round()
	_refresh()


func _on_hand_played(result: HandResult, score: ScoreContext) -> void:
	var level: int = _run.hand_levels.level_of(result.definition.id)
	_last_hand.text = tr("UI_LAST_HAND") % [tr(result.definition.name_key), level, score.qi, score.comprehension, score.total()]


func _on_round_won(reward: RoundReward) -> void:
	_last_hand.text += "\n" + tr("UI_ROUND_WON")
	_last_hand.text += "\n" + tr("UI_REWARD") % [reward.total(), reward.base, reward.hands, reward.interest]
	_shop_panel.open(ShopState.new(_run, _artifact_catalog, _manual_catalog, _pill_catalog, _shop_rules, _rng))
	_continue_button.show()


func _on_run_finished(won: bool) -> void:
	_last_hand.text += "\n" + tr("UI_RUN_WON" if won else "UI_RUN_LOST")
	_menu_button.show()


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