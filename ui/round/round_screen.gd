extends Control
## Ecran de run : affiche et fait jouer la run, et la sauvegarde apres chaque action.
## Contenu, stockage et run a reprendre sont injectes par main.

signal menu_requested
## main ouvre les reglages par-dessus la run, sans la quitter.
signal options_requested
## Emis avant le debut de la run : main y branche le suivi du profil.
signal run_created(run: RunState, resumed: bool)
## Interne : la sequence de score d'un coup est terminee.
signal _score_shown

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
var _rng: RandomNumberGenerator
var _sequence: ScoreSequence
## Vrai pendant que la sequence de score montre le coup : l'affichage de ses suites attend _score_shown.
var _scoring: bool = false

@onready var _last_hand: Label = %LastHand
@onready var _hand_view: HandView = %HandRow
@onready var _play_button: Button = %PlayButton
@onready var _discard_button: Button = %DiscardButton
@onready var _continue_button: Button = %ContinueButton
@onready var _menu_button: Button = %MenuButton
@onready var _shop_panel: ShopPanel = %ShopPanel
@onready var _items: ItemRow = %ItemRow
@onready var _deck_pile: DeckPile = %DeckPile
@onready var _side: SideColumn = %SideColumn


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
	_sequence = ScoreSequence.new()
	_sequence.settings = settings
	_sequence.setup(_hand_view, $Root/Margin)
	_sequence.score_target = _side.round_qi_center
	_sequence.artifact_hit = _items.artifact_hit
	add_child(_sequence)
	_items.settings = settings
	_items.pill_pressed.connect(_on_pill_pressed)
	%SortRank.toggled.connect(_on_sort_toggled)
	%SortElement.toggled.connect(_on_sort_toggled)
	_side.settings = settings
	_side.path_requested.connect(_show_run_info)
	_side.options_requested.connect(options_requested.emit)
	_continue_button.hide()
	_menu_button.hide()
	run_created.emit(_run, resumed)
	if not resumed:
		_run.start()
	elif not RunSnapshot.resume_round(resume_data, _run):
		# Sauvegarde prise dans la boutique : on la rouvre avec ses offres d'origine.
		_shop = RunSnapshot.restore_shop(resume_data, _run, content, _rng)
		_show_stage()
		_shop_panel.open(_shop)
		_continue_button.show()
	_refresh()


## Appele apres chaque action : redessine, puis sauvegarde (comme Balatro).
func _refresh() -> void:
	_side.show_run(_run, _round)
	var cards: Array[CardInstance] = []
	if _round != null:
		cards.assign(_round.hand())
	_show_hand(cards)
	if _round != null:
		_deck_pile.show_count(_round.draw_count(), _round.deck_size())
	_on_selection_changed()
	_items.show_artifacts(_run.artifacts, content.shop_rules.max_artifacts)
	_save_run()


func _show_hand(cards: Array[CardInstance]) -> void:
	_hand_view.set_cards(_sorted(cards))
	if _round != null:
		_hand_view.mark_sealed(func(card: CardInstance) -> bool: return not _round.counts(card))


## Par rang puis element, ou par element puis rang (bouton Element). Etat de l'ecran, pas sauvegarde.
func _sorted(cards: Array[CardInstance]) -> Array[CardInstance]:
	var by_element: bool = %SortElement.button_pressed
	cards.sort_custom(func(a: CardInstance, b: CardInstance) -> bool:
		if by_element and a.element != b.element:
			return a.element < b.element
		if a.rank != b.rank:
			return a.rank < b.rank
		return a.element < b.element)
	return cards


## Retrie la main sans perdre la selection (set_cards deselectionne).
func _on_sort_toggled(on: bool) -> void:
	if not on or _round == null:
		return
	var selected := _selected()
	var cards: Array[CardInstance] = []
	cards.assign(_round.hand())
	_show_hand(cards)
	for view: CardView in _hand_view.get_children():
		if selected.has(view.card):
			view.button_pressed = true


func _selected() -> Array[CardInstance]:
	var cards: Array[CardInstance] = []
	for view: CardView in _hand_view.get_children():
		if view.button_pressed:
			cards.append(view.card)
	return cards


func _on_selection_changed() -> void:
	var count: int = _selected().size()
	var can_act: bool = (not _scoring and _round != null and _round.status == RoundState.Status.PLAYING
		and count > 0 and count <= _rules.max_selected_cards)
	_play_button.disabled = not can_act
	_discard_button.disabled = not can_act or _round.discards_left == 0
	# Pendant la sequence, la main du round est deja repiochee : la retrier montrerait les nouvelles cartes trop tot.
	%SortRank.disabled = _scoring
	%SortElement.disabled = _scoring
	var preview: HandResult = _round.preview(_selected()) if _round != null and not _scoring else null
	_side.show_preview(preview, _run.hand_levels.level_of(preview.definition.id) if preview != null else 1)
	_refresh_pills()


## Les pilules utilisables dependent de la selection : emplacements refaits a chaque changement.
func _refresh_pills() -> void:
	var selected := _selected()
	var usable: Array[bool] = []
	for i: int in _run.pills.size():
		usable.append(not _scoring and _run.can_use_pill(i, selected))
	_items.show_pills(_run.pills, content.shop_rules.max_pills, usable)


func _on_pill_pressed(index: int) -> void:
	_run.use_pill(index, _selected())
	_refresh()


func _on_round_started(round_state: RoundState) -> void:
	_round = round_state
	# Nom du goulot fige au debut du round : progress avance des la victoire.
	_show_stage()
	_last_hand.text = ""


func _show_stage() -> void:
	_side.show_stage(_run.progress.current_realm(), _run.progress.current_bottleneck())


func _on_play_pressed() -> void:
	var cards := _selected()
	# Avant play() : ses signaux (main jouee, round gagne, fin de run) attendent la fin de la sequence.
	_scoring = true
	var context := _round.play(cards)
	if context == null:
		_scoring = false
		return
	# Sauvegarde tout de suite : quitter pendant la sequence ne doit pas permettre de rejouer le coup.
	_save_run()
	_hand_view.play_out(cards)
	_on_selection_changed()
	await _sequence.play(context, _round.target_score)
	_hand_view.clear_played()
	_scoring = false
	_score_shown.emit()
	_refresh()


## Rend la main tout de suite, ou a la fin de la sequence de score si elle est en cours.
func _after_score() -> void:
	if _scoring:
		await _score_shown


func _on_discard_pressed() -> void:
	_round.discard(_selected())
	_refresh()


func _on_continue_pressed() -> void:
	_shop_panel.hide()
	_continue_button.hide()
	_shop = null
	_run.next_round()
	_refresh()


func _on_round_won(reward: RoundReward) -> void:
	# Boutique creee tout de suite (meme tirage, et sauvegardee avec le coup), affichee apres la sequence.
	_shop = content.new_shop(_run, _rng)
	await _after_score()
	_last_hand.text = tr("UI_ROUND_WON")
	_last_hand.text += "\n" + tr("UI_REWARD") % [reward.total(), reward.base, reward.hands, reward.interest]
	_shop_panel.open(_shop)
	_continue_button.show()


func _on_run_finished(won: bool) -> void:
	# Run terminee : plus rien a reprendre. _save_run() ne reecrira pas, can_capture est faux.
	if run_storage != null:
		run_storage.delete()
	await _after_score()
	_last_hand.text = (_last_hand.text + "\n" + tr("UI_RUN_WON" if won else "UI_RUN_LOST")).strip_edges()
	_menu_button.show()


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