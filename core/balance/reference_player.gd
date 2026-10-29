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
## Contrainte de tribulation appliquee comme RoundState.play (mains, taille de main, cartes jouees, cartes qui
## comptent, Qi des cartes, cout d'une defausse). Neutre par defaut.
var constraint: TribulationConstraint = TribulationConstraint.new()
## Defausse naive : quand sa meilleure main a une priorite au plus egale, il defausse ses cartes qui ne comptent
## pas (les plus basses d'abord) au lieu de jouer. 0 : jamais.
var discard_priority: int = 0


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
	var hand_size := constraint.hand_size(_rules.hand_size)
	var max_selected := constraint.max_selected_cards(_rules.max_selected_cards)
	for i: int in rounds:
		rng.seed = first_seed + i
		var deck := DeckState.new(_deck, rng)
		var total := 0
		var hands_left := constraint.hands_per_round(_rules.hands_per_round)
		var discards_left := constraint.discards_per_round(_rules.discards_per_round)
		while hands_left > 0:
			deck.fill_hand(hand_size)
			if deck.hand.is_empty():
				break
			var best := best_play(deck.hand, artifacts, levels, stacks)
			if (best.hand.definition.priority <= discard_priority and discards_left > 0
					and hands_left > constraint.discard_hand_cost() and not deck.draw_pile.is_empty()):
				var junk := _junk(deck.hand, best.hand.scoring_cards, max_selected)
				if not junk.is_empty():
					deck.discard(junk)
					discards_left -= 1
					hands_left -= constraint.discard_hand_cost()
					continue
			total += best.total()
			var hand_id: String = best.hand.definition.id
			hand_counts[hand_id] = hand_counts.get(hand_id, 0) + 1
			deck.discard(last_played)
			hands_left -= 1
		scores.append(total)
	return scores


## Cartes a defausser : celles qui ne comptent pas, les plus basses d'abord, au plus max_selected.
func _junk(hand: Array[CardInstance], kept: Array[CardInstance], max_selected: int) -> Array[CardInstance]:
	var junk: Array[CardInstance] = hand.filter(func(card: CardInstance) -> bool: return not kept.has(card))
	junk.sort_custom(func(a: CardInstance, b: CardInstance) -> bool: return a.rank < b.rank)
	return junk.slice(0, max_selected)


## Meilleur coup parmi les cartes en main (score le plus haut). Les cartes jouees vont dans last_played.
## stacks : crans fixes des artefacts qui grandissent (ils ne grandissent pas pendant la mesure).
func best_play(hand: Array[CardInstance], artifacts: Array[ArtifactDefinition] = [],
		levels: HandLevels = HandLevels.new(), stacks: Dictionary = {}) -> ScoreContext:
	var best: ScoreContext = null
	var size := mini(constraint.max_selected_cards(_rules.max_selected_cards), hand.size())
	for combination: PackedInt32Array in _combinations_of(hand.size(), size):
		var cards: Array[CardInstance] = []
		for index: int in combination:
			cards.append(hand[index])
		var result := _evaluator.evaluate(cards)
		result.scoring_cards = result.scoring_cards.filter(constraint.counts)
		var held: Array[CardInstance] = hand.filter(func(card: CardInstance) -> bool: return not cards.has(card))
		var context := ScoringPipeline.score_triggered(result, ArtifactResolver.triggered_for(artifacts, result, held, stacks),
			levels.level_of(result.definition.id), constraint.card_qi_scale())
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
