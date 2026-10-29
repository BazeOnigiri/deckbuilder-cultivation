class_name ElementDetector
extends HandDetector
## SAME : toutes les cartes du meme element (Purete).
## DISTINCT : tous les elements differents (Harmonie).
## Une carte qui compte pour tous les elements prend celui qui manque.

enum Mode {SAME, DISTINCT}

@export var mode: Mode = Mode.SAME
@export var count: int = 0


func detect(cards: Array[CardInstance]) -> Array[CardInstance]:
	var empty: Array[CardInstance] = []
	if count <= 0 or cards.size() != count:
		return empty
	var elements: Dictionary = {}
	var fixed: int = 0
	for card: CardInstance in cards:
		if not card.is_wild():
			elements[card.element] = true
			fixed += 1
	var matches: bool = (elements.size() <= 1 if mode == Mode.SAME
		else elements.size() == fixed and count <= Element.Type.size())
	if not matches:
		return empty
	return cards.duplicate()