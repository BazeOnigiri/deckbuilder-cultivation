class_name HandRarity
extends RefCounted
## Rarete exacte des mains : part des tirages de size cartes du paquet ou le detecteur de la main trouve sa
## combinaison. Tous les tirages comptent, sans hasard.
## Symetrie : faire tourner les cinq elements (bois -> feu -> ... -> bois) ne change ni les rangs, ni « meme
## element », ni « elements differents », ni le cycle. Si le paquet a chaque rang dans chaque element, on ne compte
## que les tirages ou un Bois est parmi les cartes du plus petit rang, avec un poids : 5 fois moins de tirages.
## Taches reparties sur les coeurs (WorkerThreadPool) : les detecteurs ne font que lire.
## Logique pure : sert a tools/equilibrage.gd et aux tests.

## Poids entiers : un tirage compte 5 / k (k = elements du plus petit rang), multiplie par 60, multiple de 1 a 5.
const WEIGHT_SCALE := 60

var _hands: Array[HandDefinition]
var _size: int
## Une tache : [cartes fixees, cartes ou choisir le reste, rang du plus petit (-1 : sans symetrie, poids 1)].
var _tasks: Array = []
## Coups ponderes par main et tirages ponderes, une ligne par tache : chaque tache n'ecrit que sa ligne.
var _hits: Array[PackedInt64Array] = []
var _draws := PackedInt64Array()


## Rarete de chaque main, par id. use_rotation faux : tous les tirages, un par un (reference des tests).
static func exact(deck: DeckDefinition, hands: Array[HandDefinition], size: int, use_rotation: bool = true) -> Dictionary:
	var rarity := HandRarity.new()
	rarity._hands = hands
	rarity._size = size
	var cards: Array[CardInstance] = []
	for i: int in deck.cards.size():
		cards.append(CardInstance.new(i, deck.cards[i], deck.ranks))
	if use_rotation and _rotation_closed(cards):
		rarity._plan_rotation(cards)
	else:
		rarity._plan_all(cards)
	rarity._hits.resize(rarity._tasks.size())
	rarity._draws.resize(rarity._tasks.size())
	var task := WorkerThreadPool.add_group_task(rarity._run_task, rarity._tasks.size())
	WorkerThreadPool.wait_for_group_task_completion(task)
	var total := 0
	var hits := PackedInt64Array()
	hits.resize(hands.size())
	for t: int in rarity._tasks.size():
		total += rarity._draws[t]
		for h: int in hands.size():
			hits[h] += rarity._hits[t][h]
	var rarities := {}
	for h: int in hands.size():
		rarities[hands[h].id] = hits[h] / float(maxi(1, total))
	return rarities


## Vrai si chaque rang du paquet existe une fois, et une seule, dans chacun des elements.
static func _rotation_closed(cards: Array[CardInstance]) -> bool:
	var seen := {}
	var ranks := {}
	for card: CardInstance in cards:
		var key := Vector2i(card.element, card.rank)
		if seen.has(key):
			return false
		seen[key] = true
		ranks[card.rank] = true
	return seen.size() == ranks.size() * Element.Type.size()


## Sans symetrie : une tache par paire de premieres cartes, le reste choisi apres elles.
func _plan_all(cards: Array[CardInstance]) -> void:
	if _size < 2:
		_tasks.append([[], cards, -1])
		return
	for i: int in cards.size():
		for j: int in range(i + 1, cards.size()):
			_tasks.append([[cards[i], cards[j]], cards.slice(j + 1), -1])


## Avec symetrie : la premiere carte est un Bois de rang m, les autres ont un rang >= m (sauf ce Bois).
func _plan_rotation(cards: Array[CardInstance]) -> void:
	for first: CardInstance in cards:
		if first.element != Element.Type.BOIS:
			continue
		var pool: Array[CardInstance] = []
		pool.assign(cards.filter(func(card: CardInstance) -> bool:
			return card != first and card.rank >= first.rank))
		if _size < 2:
			_tasks.append([[first], pool, first.rank])
			continue
		for j: int in pool.size():
			_tasks.append([[first, pool[j]], pool.slice(j + 1), first.rank])


func _run_task(t: int) -> void:
	var fixed: Array = _tasks[t][0]
	var pool: Array = _tasks[t][1]
	var lowest: int = _tasks[t][2]
	var hits := PackedInt64Array()
	hits.resize(_hands.size())
	var draws := 0
	var free := _size - fixed.size()
	if free <= pool.size():
		var indexes := PackedInt32Array(range(free))
		var drawn: Array[CardInstance] = []
		drawn.assign(fixed)
		drawn.resize(_size)
		while true:
			for i: int in free:
				drawn[fixed.size() + i] = pool[indexes[i]]
			var weight := 1 if lowest < 0 else _weight(drawn, lowest)
			for h: int in _hands.size():
				if not _hands[h].detector.detect(drawn).is_empty():
					hits[h] += weight
			draws += weight
			if not _next(indexes, pool.size()):
				break
	_hits[t] = hits
	_draws[t] = draws


## 5 / k a l'echelle WEIGHT_SCALE : k tirages de l'orbite (les rotations du tirage) ont un Bois au plus petit rang.
static func _weight(drawn: Array[CardInstance], lowest: int) -> int:
	var elements := 0
	for card: CardInstance in drawn:
		if card.rank == lowest:
			elements += 1
	return WEIGHT_SCALE * Element.Type.size() / elements


## Combinaison suivante dans l'ordre lexicographique. Faux apres la derniere (ou s'il n'y a rien a choisir).
static func _next(indexes: PackedInt32Array, count: int) -> bool:
	var size := indexes.size()
	var i := size - 1
	while i >= 0 and indexes[i] == count - size + i:
		i -= 1
	if i < 0:
		return false
	indexes[i] += 1
	for j: int in range(i + 1, size):
		indexes[j] = indexes[j - 1] + 1
	return true
