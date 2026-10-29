class_name RoundState
extends RefCounted
## Un round : atteindre target_score avec un nombre limite de mains et de defausses. Logique pure.

signal hand_played(result: HandResult, score: ScoreContext)
signal finished(won: bool)
## stones : pierres gagnees par les artefacts sur cette defausse.
signal discarded(stones: int)

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
var _max_selected: int
## Crans des artefacts qui grandissent, partages avec la run (meme dictionnaire).
var _stacks: Dictionary


func _init(deck: DeckState, rules: RoundRules, evaluator: HandEvaluator, p_target_score: int, artifacts: Array[ArtifactDefinition], levels: HandLevels, constraint: TribulationConstraint, stacks: Dictionary = {}) -> void:
	_deck = deck
	_stacks = stacks
	_rules = rules
	_evaluator = evaluator
	_artifacts = artifacts
	_levels = levels
	_constraint = constraint
	target_score = p_target_score
	hands_left = constraint.hands_per_round(rules.hands_per_round)
	discards_left = constraint.discards_per_round(rules.discards_per_round)
	_hand_size = constraint.hand_size(rules.hand_size)
	_max_selected = constraint.max_selected_cards(rules.max_selected_cards)


## A appeler apres avoir connecte les signaux : remelange et pioche la premiere main.
func start() -> void:
	_deck.reset()
	_refill()


func hand() -> Array[CardInstance]:
	return _deck.hand


## Cartes encore dans la pioche (compteur de la pioche a l'ecran).
func draw_count() -> int:
	return _deck.draw_pile.size()


func deck_size() -> int:
	return _deck.total_count()


## Toutes les cartes de la run, toutes piles confondues (vue du paquet).
func deck_cards() -> Array[CardInstance]:
	return _deck.all_cards()


func in_draw_pile(card: CardInstance) -> bool:
	return _deck.draw_pile.has(card)


## Cartes jouees ou defaussees en une fois, contrainte de la tribulation comprise.
func max_selected() -> int:
	return _max_selected


## Faux si la defausse est refusee : plus de defausse, ou la tribulation la fait payer d'une main qu'on n'a pas.
func can_discard() -> bool:
	return status == Status.PLAYING and discards_left > 0 and hands_left > _constraint.discard_hand_cost()


## Faux si la tribulation scelle cette carte : jouee, elle ne compte pas.
func counts(card: CardInstance) -> bool:
	return _constraint.counts(card)


## Main que formeraient ces cartes, sans rien jouer (apercu de la selection). null si la selection est refusee.
func preview(cards: Array[CardInstance]) -> HandResult:
	if not _valid_selection(cards):
		return null
	return _evaluator.evaluate(cards)


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
		if counts(card):
			counted.append(card)
	result.scoring_cards = counted
	# Les cartes jouees sont deja defaussees : la main ne contient plus que les cartes gardees.
	var effects := ArtifactResolver.triggered_for(_artifacts, result, _deck.hand, _stacks)
	var context := ScoringPipeline.score_triggered(result, effects, _levels.level_of(result.definition.id),
		_constraint.card_qi_scale())
	score += context.total()
	ArtifactResolver.after_hand(_artifacts, _stacks, result, _deck.hand)
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
	if not can_discard() or not _valid_selection(cards):
		return false
	if not _deck.discard(cards):
		return false
	discards_left -= 1
	hands_left -= _constraint.discard_hand_cost()
	discarded.emit(ArtifactResolver.after_discard(_artifacts, _stacks, cards))
	_refill()
	return true

## A appeler quand la main change hors d'un coup (pilule de destruction) :
## main vide = repioche, et sans rien a piocher le round est perdu.
func ensure_playable() -> void:
	if status == Status.PLAYING and _deck.hand.is_empty():
		_refill()

func _valid_selection(cards: Array[CardInstance]) -> bool:
	return not cards.is_empty() and cards.size() <= _max_selected


func _refill() -> void:
	_deck.fill_hand(_hand_size)
	# Pioche et main vides : plus aucun coup possible.
	if _deck.hand.is_empty():
		_finish(Status.LOST)


func _finish(new_status: Status) -> void:
	status = new_status
	finished.emit(new_status == Status.WON)