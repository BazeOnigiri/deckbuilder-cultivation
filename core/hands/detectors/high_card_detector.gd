class_name HighCardDetector
extends HandDetector
## Carte la plus haute (Souffle). Correspond des qu'il y a au moins une carte.


func detect(cards: Array[CardInstance]) -> Array[CardInstance]:
	var result: Array[CardInstance] = []
	if cards.is_empty():
		return result
	var best: CardInstance = cards[0]
	for card: CardInstance in cards:
		if card.data.rank > best.data.rank:
			best = card
	result.append(best)
	return result