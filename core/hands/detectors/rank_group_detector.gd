class_name RankGroupDetector
extends HandDetector
## Groupes de cartes de meme rang.
## [2] paire, [2, 2] double paire, [3] brelan, [3, 2] full, [4] carre, [5] cinq souverains.

@export var group_sizes: Array[int] = []


func detect(cards: Array[CardInstance]) -> Array[CardInstance]:
	var result: Array[CardInstance] = []
	if group_sizes.is_empty():
		return result
	var required: Array[int] = group_sizes.duplicate()
	required.sort()
	required.reverse()
	var groups: Array[Array] = _groups_by_rank(cards)
	if groups.size() < required.size():
		return result
	for i: int in required.size():
		if groups[i].size() < required[i]:
			return result
	for i: int in required.size():
		for j: int in required[i]:
			result.append(groups[i][j])
	return result


## Groupes tries par taille decroissante, puis par rang decroissant.
func _groups_by_rank(cards: Array[CardInstance]) -> Array[Array]:
	var by_rank: Dictionary = {}
	for card: CardInstance in cards:
		if not by_rank.has(card.rank):
			by_rank[card.rank] = []
		by_rank[card.rank].append(card)
	var groups: Array[Array] = []
	for rank: int in by_rank:
		groups.append(by_rank[rank])
	groups.sort_custom(func(a: Array, b: Array) -> bool:
		if a.size() != b.size():
			return a.size() > b.size()
		return a[0].rank > b[0].rank)
	return groups