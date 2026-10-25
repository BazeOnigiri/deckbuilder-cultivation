class_name RunState
extends RefCounted
## Une run : enchaine les goulots des royaumes jusqu'a la victoire ou la defaite. Logique pure.

signal round_started(round_state: RoundState)
signal round_won(reward: RoundReward)
signal finished(won: bool)

## BETWEEN_ROUNDS : goulot franchi, en attente du suivant (la boutique s'inserera ici).
enum Status {IN_ROUND, BETWEEN_ROUNDS, WON, LOST}

var status: Status = Status.IN_ROUND
var progress: RunProgress
var current_round: RoundState
var stones: int = 0
## Partage avec chaque round : un artefact ajoute agit des la main suivante.
var artifacts: Array[ArtifactDefinition] = []
var hand_levels := HandLevels.new()
var pills: Array[PillDefinition] = []
var stats := RunStats.new()

var _deck: DeckState
var _rules: RoundRules
var _evaluator: HandEvaluator
var _economy: EconomyRules


func _init(deck: DeckState, rules: RoundRules, evaluator: HandEvaluator, p_progress: RunProgress, economy: EconomyRules) -> void:
	_deck = deck
	_rules = rules
	_evaluator = evaluator
	progress = p_progress
	_economy = economy
	stones = economy.starting_stones


func start() -> void:
	_start_round()


## Lance le goulot suivant. Refuse si on n'est pas entre deux goulots.
func next_round() -> bool:
	if status != Status.BETWEEN_ROUNDS:
		return false
	_start_round()
	return true

## Une pilule s'utilise pendant un round, sur des cartes de la main, en nombre autorise par la pilule.
func can_use_pill(index: int, cards: Array[CardInstance]) -> bool:
	if status != Status.IN_ROUND or index < 0 or index >= pills.size():
		return false
	var pill: PillDefinition = pills[index]
	return (cards.size() >= pill.min_cards and cards.size() <= pill.max_cards
		and _deck.all_in_hand(cards))


func use_pill(index: int, cards: Array[CardInstance]) -> bool:
	if not can_use_pill(index, cards):
		return false
	pills[index].effect.apply(cards, _deck)
	pills.remove_at(index)
	current_round.ensure_playable()
	return true

## Toutes les cartes de la run (sauvegarde).
func cards() -> Array[CardInstance]:
	return _deck.all_cards()

func _start_round() -> void:
	status = Status.IN_ROUND
	var constraint: TribulationConstraint = progress.current_bottleneck().constraint
	if constraint == null:
		constraint = TribulationConstraint.new()
	current_round = RoundState.new(_deck, _rules, _evaluator, progress.current_target(), artifacts, hand_levels, constraint)
	current_round.finished.connect(_on_round_finished)
	current_round.hand_played.connect(_on_hand_played)
	current_round.discarded.connect(_on_discarded)
	# Emis avant start() : l'UI se branche sur le round avant la premiere pioche.
	round_started.emit(current_round)
	current_round.start()


func _on_round_finished(won: bool) -> void:
	if not won:
		status = Status.LOST
		finished.emit(false)
		return
	# Recompense calculee avant advance() : elle depend du goulot qui vient d'etre franchi.
	var reward := RoundReward.compute(_economy, progress.current_bottleneck().reward, current_round.hands_left, stones)
	stones += reward.total()
	stats.stones_earned += reward.total()
	stats.bottlenecks_cleared += 1
	if progress.advance():
		status = Status.BETWEEN_ROUNDS
		round_won.emit(reward)
	else:
		status = Status.WON
		finished.emit(true)

func _on_hand_played(result: HandResult, score: ScoreContext) -> void:
	stats.record_hand(result.definition.id, score.total())


func _on_discarded() -> void:
	stats.discards_used += 1