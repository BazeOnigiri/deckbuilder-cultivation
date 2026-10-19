class_name StraightDetector
extends HandDetector
## Rangs consecutifs (Ascension). Options : meme element (Ascension pure),
## ou elements qui suivent un cycle (Cycle d'engendrement).

@export var length: int = 0
@export var require_same_element: bool = false
## Si defini : triees par rang, chaque carte a l'element qui suit celui de la precedente.
@export var cycle: ElementCycle


func detect(cards: Array[CardInstance]) -> Array[CardInstance]:
	var empty: Array[CardInstance] = []
	if length <= 0 or cards.size() != length:
		return empty
	var ordered: Array[CardInstance] = cards.duplicate()
	ordered.sort_custom(func(a: CardInstance, b: CardInstance) -> bool:
		return a.data.rank < b.data.rank)
	for i: int in range(1, ordered.size()):
		var prev: CardInstance = ordered[i - 1]
		var cur: CardInstance = ordered[i]
		if cur.data.rank != prev.data.rank + 1:
			return empty
		if require_same_element and cur.data.element != prev.data.element:
			return empty
		if cycle != null and cur.data.element != cycle.next_of(prev.data.element):
			return empty
	return ordered