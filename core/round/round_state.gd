class_name RoundState
extends RefCounted
## Un round : atteindre target_score avec un nombre limite de mains et de defausses. Logique pure.

signal hand_played(result: HandResult, score: ScoreContext)
signal finished(won: bool)
signal discarded

enum Status {PLAYING, WON, LOST}

var status: Status = Status.PLAYING
var score: int = 0
var target_score: int
var hands_left: int
var discards_left: int

var _deck: DeckState
var _rules: RoundRules
var _evaluator: HandEvaluator
var _artifacts: Array[ArtifactDefinition]
var _levels: HandLevels
var _constraint: TribulationConstraint
var _hand_size: int


func _init(deck: DeckState, rules: RoundRules, evaluator: HandEvaluator, p_target_score: int, artifacts: Array[ArtifactDefinition], levels: HandLevels, constraint: TribulationConstraint) -> void:
	_deck = deck
	_rules = rules
	_evaluator = evaluator
	_artifacts = artifacts
	_levels = levels
	_constraint = constraint
	target_score = p_target_score
	hands_left = constraint.hands_per_round(rules.hands_per_round)
	discards_left = constraint.discards_per_round(rules.discards_per_round)
	_hand_size = constraint.hand_size(rules.hand_size)


## A appeler apres avoir connecte les signaux : remelange et pioche la premiere main.
func start() -> void:
	_deck.reset()
	_refill()


func hand() -> Array[CardInstance]:
	return _deck.hand


## Renvoie le score du coup, ou null si le coup est refuse (rien ne change alors).
func play(cards: Array[CardInstance]) -> ScoreContext:
	if status != Status.PLAYING or hands_left <= 0 or not _valid_selection(cards):
		return null
	# Evaluer avant de deplacer les cartes : un refus ne doit rien modifier.
	var result: HandResult = _evaluator.evaluate(cards)
	if result == null or not _deck.discard(cards):
		return null
	# Filtrer avant les artefacts : une carte qui ne compte pas ne declenche pas non plus CARD_SCORED.
	var counted: Array[CardInstance] = []
	for card: CardInstance in result.scoring_cards:
		if _constraint.counts(card):
			counted.append(card)
	result.scoring_cards = counted
	var effects := ArtifactResolver.triggered_for(_artifacts, result)
	var context := ScoringPipeline.score_triggered(result, effects, _levels.level_of(result.definition.id))
	score += context.total()
	hands_left -= 1
	hand_played.emit(result, context)
	if score >= target_score:
		_finish(Status.WON)
	elif hands_left == 0:
		_finish(Status.LOST)
	else:
		_refill()
	return context


func discard(cards: Array[CardInstance]) -> bool:
	if status != Status.PLAYING or discards_left <= 0 or not _valid_selection(cards):
		return false
	if not _deck.discard(cards):
		return false
	discards_left -= 1
	discarded.emit()
	_refill()
	return true

## A appeler quand la main change hors d'un coup (pilule de destruction) :
## main vide = repioche, et sans rien a piocher le round est perdu.
func ensure_playable() -> void:
	if status == Status.PLAYING and _deck.hand.is_empty():
		_refill()

func _valid_selection(cards: Array[CardInstance]) -> bool:
	return not cards.is_empty() and cards.size() <= _rules.max_selected_cards


func _refill() -> void:
	_deck.fill_hand(_hand_size)
	# Pioche et main vides : plus aucun coup possible.
	if _deck.hand.is_empty():
		_finish(Status.LOST)


func _finish(new_status: Status) -> void:
	status = new_status
	finished.emit(new_status == Status.WON)