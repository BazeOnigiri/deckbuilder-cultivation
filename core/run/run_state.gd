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
## Crans des artefacts qui grandissent, par id (sauvegardes). Partages avec chaque round.
var artifact_stacks: Dictionary = {}
var hand_levels := HandLevels.new()
var pills: Array[PillDefinition] = []
var stats := RunStats.new()
## Heritages achetes : leurs modificateurs changent les regles de base pour le reste de la run.
var legacies: Array[LegacyDefinition] = []
## Heritage propose en boutique pendant ce royaume (null : achete ou aucun), et le royaume ou il a ete tire.
var legacy_offer: LegacyDefinition
var legacy_offer_realm: int = 0

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

## Regles du round avec les heritages : le round, la boutique et l'economie lisent celles-ci, jamais les heritages.
func round_rules() -> RoundRules:
	return _with_legacies(_rules) as RoundRules


func economy() -> EconomyRules:
	return _with_legacies(_economy) as EconomyRules


func shop_rules(base: ShopRules) -> ShopRules:
	return _with_legacies(base) as ShopRules


## Copie des regles de base, chaque modificateur de chaque heritage applique dans l'ordre d'achat.
func _with_legacies(base: Resource) -> Resource:
	if legacies.is_empty():
		return base
	var rules := base.duplicate()
	for legacy: LegacyDefinition in legacies:
		for modifier: RuleModifier in legacy.modifiers:
			modifier.apply_to(rules)
	return rules


## Prix de vente d'un artefact : la part sell_fraction de son prix, arrondie en dessous.
func sell_price(artifact: ArtifactDefinition) -> int:
	return floori(artifact.price * economy().sell_fraction)


## Vend l'artefact a cet index : rend ses pierres et libere l'emplacement, des la main suivante. Faux si
## l'index n'existe pas.
func sell_artifact(index: int) -> bool:
	if index < 0 or index >= artifacts.size():
		return false
	stones += sell_price(artifacts[index])
	artifact_stacks.erase(artifacts[index].id)
	artifacts.remove_at(index)
	return true


## Ajoute une carte au paquet de la run (sceau de disciples), avec un uid neuf, dans la pioche : le melange du
## prochain round la place.
func add_card(data: CardData, ranks: RankRules) -> CardInstance:
	var uid := 0
	for card: CardInstance in _deck.all_cards():
		uid = maxi(uid, card.uid + 1)
	var card := CardInstance.new(uid, data, ranks)
	_deck.draw_pile.append(card)
	return card


## Main que formeraient ces cartes (pilule d'illumination). null si aucune.
func evaluate(cards: Array[CardInstance]) -> HandResult:
	return _evaluator.evaluate(cards)


## Une pilule s'utilise pendant un round, sur des cartes de la main, en nombre autorise par la pilule.
func can_use_pill(index: int, selected: Array[CardInstance]) -> bool:
	if status != Status.IN_ROUND or index < 0 or index >= pills.size():
		return false
	var pill: PillDefinition = pills[index]
	return (selected.size() >= pill.min_cards and selected.size() <= pill.max_cards
		and _deck.all_in_hand(selected))


func use_pill(index: int, selected: Array[CardInstance]) -> bool:
	if not can_use_pill(index, selected):
		return false
	pills[index].effect.apply(selected, _deck, self)
	pills.remove_at(index)
	current_round.ensure_playable()
	return true

## Toutes les cartes de la run (sauvegarde).
func cards() -> Array[CardInstance]:
	return _deck.all_cards()

## Piles du paquet par uid (sauvegarde).
func piles() -> Dictionary:
	return _deck.pile_uids()


## Reprise d'un round sauvegarde : les piles sont deja restaurees, donc pas de start() (il remelangerait).
func resume_round(score: int, hands_left: int, discards_left: int) -> void:
	_create_round()
	current_round.score = maxi(0, score)
	current_round.hands_left = maxi(1, hands_left)
	current_round.discards_left = maxi(0, discards_left)
	round_started.emit(current_round)
	current_round.ensure_playable()

func _start_round() -> void:
	_create_round()
	# Emis avant start() : l'UI se branche sur le round avant la premiere pioche.
	round_started.emit(current_round)
	current_round.start()


func _create_round() -> void:
	status = Status.IN_ROUND
	var constraint: TribulationConstraint = progress.current_bottleneck().constraint
	if constraint == null:
		constraint = TribulationConstraint.new()
	current_round = RoundState.new(_deck, round_rules(), _evaluator, progress.current_target(), artifacts, hand_levels, constraint,
		artifact_stacks)
	current_round.finished.connect(_on_round_finished)
	current_round.hand_played.connect(_on_hand_played)
	current_round.discarded.connect(_on_discarded)


func _on_round_finished(won: bool) -> void:
	if not won:
		status = Status.LOST
		finished.emit(false)
		return
	# Recompense calculee avant advance() : elle depend du goulot qui vient d'etre franchi.
	var reward := RoundReward.compute(economy(), progress.current_bottleneck().reward, current_round.hands_left, stones)
	reward.artifacts = ArtifactResolver.after_round_won(artifacts, artifact_stacks, current_round.hands_left,
		current_round.discards_left)
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


func _on_discarded(gained: int) -> void:
	stats.discards_used += 1
	stones += gained
	stats.stones_earned += gained