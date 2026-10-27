class_name HandRarity
extends RefCounted
## Rarete exacte des mains : part des tirages de size cartes du paquet ou le detecteur de la main trouve sa
## combinaison. Tous les tirages sont enumeres, sans hasard : 8 259 888 pour 5 cartes parmi 65.
## Une tache par premiere carte, repartie sur les coeurs (WorkerThreadPool) : les detecteurs ne font que lire.
## Logique pure : sert a tools/equilibrage.gd et aux tests.

var _cards: Array[CardInstance] = []
var _hands: Array[HandDefinition]
var _size: int
## Coups par main, une ligne par premiere carte : chaque tache n'ecrit que sa ligne.
var _hits: Array[PackedInt64Array] = []
var _draws := PackedInt64Array()


## Rarete de chaque main, par id : nombre de tirages qui la contiennent / nombre de tirages.
static func exact(deck: DeckDefinition, hands: Array[HandDefinition], size: int) -> Dictionary:
	var rarity := HandRarity.new()
	rarity._hands = hands
	rarity._size = size
	for i: int in deck.cards.size():
		rarity._cards.append(CardInstance.new(i, deck.cards[i], deck.ranks))
	var firsts := maxi(0, deck.cards.size() - size + 1)
	rarity._hits.resize(firsts)
	rarity._draws.resize(firsts)
	var task := WorkerThreadPool.add_group_task(rarity._count_from, firsts)
	WorkerThreadPool.wait_for_group_task_completion(task)
	var total := 0
	var hits := PackedInt64Array()
	hits.resize(hands.size())
	for first: int in firsts:
		total += rarity._draws[first]
		for h: int in hands.size():
			hits[h] += rarity._hits[first][h]
	var rarities := {}
	for h: int in hands.size():
		rarities[hands[h].id] = hits[h] / float(maxi(1, total))
	return rarities


## Tous les tirages dont la plus petite carte est first.
func _count_from(first: int) -> void:
	var hits := PackedInt64Array()
	hits.resize(_hands.size())
	var draws := 0
	var indexes := PackedInt32Array(range(first, first + _size))
	var drawn: Array[CardInstance] = []
	drawn.resize(_size)
	while true:
		for i: int in _size:
			drawn[i] = _cards[indexes[i]]
		for h: int in _hands.size():
			if not _hands[h].detector.detect(drawn).is_empty():
				hits[h] += 1
		draws += 1
		if not _next(indexes, _cards.size()):
			break
	_hits[first] = hits
	_draws[first] = draws


## Combinaison suivante dans l'ordre lexicographique, la premiere carte fixee. Faux apres la derniere.
static func _next(indexes: PackedInt32Array, count: int) -> bool:
	var size := indexes.size()
	var i := size - 1
	while i >= 1 and indexes[i] == count - size + i:
		i -= 1
	if i < 1:
		return false
	indexes[i] += 1
	for j: int in range(i + 1, size):
		indexes[j] = indexes[j - 1] + 1
	return true
