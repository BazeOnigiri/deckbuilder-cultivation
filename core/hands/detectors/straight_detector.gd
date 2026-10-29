class_name StraightDetector
extends HandDetector
## Rangs consecutifs (Ascension). Options : meme element (Ascension pure),
## ou elements qui suivent un cycle (Cycle d'engendrement).

@export var length: int = 0
@export var require_same_element: bool = false
## Si defini : triees par rang, chaque carte a l'element qui suit celui de la precedente.
@export var cycle: ElementCycle
## Si defini : une carte de ce rang peut aussi se placer sous le 1 (le Souverain, comme l'As). Pas de boucle.
@export var low_rank: int = 0


func detect(cards: Array[CardInstance]) -> Array[CardInstance]:
	var empty: Array[CardInstance] = []
	if length <= 0 or cards.size() != length:
		return empty
	var found := _detect(cards, false)
	if found.is_empty() and low_rank > 0:
		found = _detect(cards, true)
	return found


func _detect(cards: Array[CardInstance], low: bool) -> Array[CardInstance]:
	var empty: Array[CardInstance] = []
	var value := func(card: CardInstance) -> int: return 0 if low and card.rank == low_rank else card.rank
	var ordered: Array[CardInstance] = cards.duplicate()
	ordered.sort_custom(func(a: CardInstance, b: CardInstance) -> bool: return value.call(a) < value.call(b))
	for i: int in range(1, ordered.size()):
		var prev: CardInstance = ordered[i - 1]
		var cur: CardInstance = ordered[i]
		if value.call(cur) != value.call(prev) + 1:
			return empty
	if require_same_element and not _same_element(ordered):
		return empty
	if cycle != null and not _follows_cycle(ordered):
		return empty
	return ordered


## Les cartes qui comptent pour tous les elements s'accordent a n'importe quel element.
static func _same_element(ordered: Array[CardInstance]) -> bool:
	var elements: Dictionary = {}
	for card: CardInstance in ordered:
		if not card.is_wild():
			elements[card.element] = true
	return elements.size() <= 1


## La premiere carte fixe donne la place de toute la suite dans le cycle ; les autres cartes fixes doivent la suivre.
func _follows_cycle(ordered: Array[CardInstance]) -> bool:
	var anchor: int = -1
	for i: int in ordered.size():
		if not ordered[i].is_wild():
			anchor = i
			break
	if anchor == -1:
		return true
	var start: int = cycle.order.find(ordered[anchor].element) - anchor
	for i: int in ordered.size():
		if not ordered[i].is_wild() and ordered[i].element != cycle.order[posmod(start + i, cycle.order.size())]:
			return false
	return true
