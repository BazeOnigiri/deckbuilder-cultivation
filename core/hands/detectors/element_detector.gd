class_name ElementDetector
extends HandDetector
## SAME : toutes les cartes du meme element (Purete).
## DISTINCT : tous les elements differents (Harmonie).

enum Mode {SAME, DISTINCT}

@export var mode: Mode = Mode.SAME
@export var count: int = 0


func detect(cards: Array[CardInstance]) -> Array[CardInstance]:
	var empty: Array[CardInstance] = []
	if count <= 0 or cards.size() != count:
		return empty
	var elements: Dictionary = {}
	for card: CardInstance in cards:
		elements[card.data.element] = true
	var matches: bool = elements.size() == 1 if mode == Mode.SAME else elements.size() == count
	if not matches:
		return empty
	return cards.duplicate()