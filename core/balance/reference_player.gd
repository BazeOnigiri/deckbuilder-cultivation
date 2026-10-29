class_name ReferencePlayer
extends RefCounted
## Joueur de reference de l'equilibrage : a chaque main, il joue la meilleure combinaison de cartes
## (max_selected_cards parmi sa main), sans defausse. Logique pure : sert a tools/equilibrage.gd et aux tests.
## Les rounds sont tires avec une graine par round : avec ou sans objet, les memes rounds sont joues
## (nombres aleatoires communs), donc la difference mesuree vient de l'objet et pas du hasard.

var _deck: DeckDefinition
var _rules: RoundRules
var _evaluator: HandEvaluator
var _combinations: Dictionary = {}
## Cartes du dernier best_play : le round les defausse avant de repiocher.
var last_played: Array[CardInstance] = []


func _init(deck: DeckDefinition, rules: RoundRules, hands: Array[HandDefinition]) -> void:
	_deck = deck
	_rules = rules
	_evaluator = HandEvaluator.new(hands)


## Score de chaque round, rounds tires avec les graines first_seed, first_seed + 1...
## hand_counts (optionnel) recoit le nombre de fois que chaque main a ete jouee, par id.
func round_scores(rounds: int, first_seed: int, artifacts: Array[ArtifactDefinition] = [],
		levels: HandLevels = HandLevels.new(), hand_counts: Dictionary = {}, stacks: Dictionary = {}) -> PackedFloat32Array:
	var scores := PackedFloat32Array()
	var rng := RandomNumberGenerator.new()
	for i: int in rounds:
		rng.seed = first_seed + i
		var deck := DeckState.new(_deck, rng)
		var total := 0
		for hand: int in _rules.hands_per_round:
			deck.fill_hand(_rules.hand_size)
			if deck.hand.is_empty():
				break
			var best := best_play(deck.hand, artifacts, levels, stacks)
			total += best.total()
			var hand_id: String = best.hand.definition.id
			hand_counts[hand_id] = hand_counts.get(hand_id, 0) + 1
			deck.discard(last_played)
		scores.append(total)
	return scores


## Meilleur coup parmi les cartes en main (score le plus haut). Les cartes jouees vont dans last_played.
## stacks : crans fixes des artefacts qui grandissent (ils ne grandissent pas pendant la mesure).
func best_play(hand: Array[CardInstance], artifacts: Array[ArtifactDefinition] = [],
		levels: HandLevels = HandLevels.new(), stacks: Dictionary = {}) -> ScoreContext:
	var best: ScoreContext = null
	for combination: PackedInt32Array in _combinations_of(hand.size(), mini(_rules.max_selected_cards, hand.size())):
		var cards: Array[CardInstance] = []
		for index: int in combination:
			cards.append(hand[index])
		var result := _evaluator.evaluate(cards)
		var held: Array[CardInstance] = hand.filter(func(card: CardInstance) -> bool: return not cards.has(card))
		var context := ScoringPipeline.score_triggered(result, ArtifactResolver.triggered_for(artifacts, result, held, stacks),
			levels.level_of(result.definition.id))
		if best == null or context.total() > best.total():
			best = context
			last_played = cards
	return best


## Toutes les facons de choisir k indices parmi n, en cache.
func _combinations_of(n: int, k: int) -> Array[PackedInt32Array]:
	var key := Vector2i(n, k)
	if not _combinations.has(key):
		var result: Array[PackedInt32Array] = []
		_combine(n, k, 0, PackedInt32Array(), result)
		_combinations[key] = result
	return _combinations[key]


func _combine(n: int, k: int, start: int, current: PackedInt32Array, result: Array[PackedInt32Array]) -> void:
	if current.size() == k:
		result.append(current.duplicate())
		return
	for i: int in range(start, n - (k - current.size()) + 1):
		current.append(i)
		_combine(n, k, i + 1, current, result)
		current.remove_at(current.size() - 1)
