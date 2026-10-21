extends Control
## Ecran de round jouable. Racine de composition : cree la logique, l'injecte, et l'affiche.

const DECK_PATH := "res://content/decks/paquet_depart.tres"
const RULES_PATH := "res://content/rules/regles_base.tres"

var _round: RoundState
var _rules: RoundRules
var _progress: RunProgress

@onready var _info: Label = %Info
@onready var _last_hand: Label = %LastHand
@onready var _hand_row: HBoxContainer = %HandRow
@onready var _play_button: Button = %PlayButton
@onready var _discard_button: Button = %DiscardButton
@onready var _restart_button: Button = %RestartButton
@onready var _credits_button: Button = %CreditsButton

func _ready() -> void:
	_rules = load(RULES_PATH)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var deck := DeckState.new(load(DECK_PATH), rng)
	_progress = RunProgress.new(RealmCatalog.load_definitions())
	_round = RoundState.new(deck, _rules, HandEvaluator.new(HandCatalog.load_definitions()), _progress.current_target())
	_round.hand_played.connect(_on_hand_played)
	_round.finished.connect(_on_finished)
	_play_button.pressed.connect(_on_play_pressed)
	_discard_button.pressed.connect(_on_discard_pressed)
	_restart_button.pressed.connect(func() -> void: get_tree().reload_current_scene())
	_credits_button.pressed.connect(_show_credits)
	_restart_button.hide()
	_round.start()
	_refresh()


func _refresh() -> void:
	var stage: String = tr("UI_STAGE") % [tr(_progress.current_realm().name_key), tr(_progress.current_bottleneck().name_key)]
	_info.text = stage + "\n" + tr("UI_ROUND_INFO") % [_round.score, _round.target_score, _round.hands_left, _round.discards_left]
	for child: Node in _hand_row.get_children():
		# remove_child tout de suite : queue_free seul laisse l'enfant compte jusqu'a la frame suivante.
		_hand_row.remove_child(child)
		child.queue_free()
	var cards: Array[CardInstance] = _round.hand().duplicate()
	cards.sort_custom(func(a: CardInstance, b: CardInstance) -> bool: return a.data.rank < b.data.rank)
	for card: CardInstance in cards:
		var view := CardView.new()
		view.card = card
		view.toggled.connect(_on_selection_changed.unbind(1))
		_hand_row.add_child(view)
	_on_selection_changed()


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


func _on_play_pressed() -> void:
	_round.play(_selected())
	_refresh()


func _on_discard_pressed() -> void:
	_round.discard(_selected())
	_refresh()


func _on_hand_played(result: HandResult, score: ScoreContext) -> void:
	_last_hand.text = tr("UI_LAST_HAND") % [tr(result.definition.name_key), score.qi, score.comprehension, score.total()]


func _on_finished(won: bool) -> void:
	_last_hand.text += "\n" + tr("UI_ROUND_WON" if won else "UI_ROUND_LOST")
	_restart_button.show()

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