class_name ShopState
extends RefCounted
## Boutique entre deux goulots : offres tirees au hasard (RNG injectee), achat et relance. Logique pure.
## Chaque emplacement tire un type (ShopRules.kind_weights), puis un objet de ce type : les trois listes d'offres
## n'ont pas de taille fixe. Les sceaux-tresor (pack_offers) sont tires une fois par visite, la relance ne les
## change pas ; un sceau achete s'ouvre (opening) jusqu'a ce que ses choix soient pris ou passes.

var offers: Array[ArtifactDefinition] = []
var manual_offers: Array[ManualDefinition] = []
var pill_offers: Array[PillDefinition] = []
var pack_offers: Array[PackDefinition] = []
## Sceau ouvert, en attente des choix du joueur. null si aucun.
var opening: PackOpening
var reroll_cost: int

var _run: RunState
var _catalog: Array[ArtifactDefinition]
var _manuals: Array[ManualDefinition]
var _pills: Array[PillDefinition]
var _packs: Array[PackDefinition]
var _legacies: Array[LegacyDefinition]
## Regles de la boutique sans heritages : _rules est recalcule apres l'achat d'un heritage.
var _base_rules: ShopRules
## Paquet de depart : les cartes qu'un sceau de disciples peut ajouter, et leurs rangs.
var _deck: DeckDefinition
var _rules: ShopRules
var _rng: RandomNumberGenerator


func _init(run: RunState, catalog: Array[ArtifactDefinition], manuals: Array[ManualDefinition], pills: Array[PillDefinition], packs: Array[PackDefinition], legacies: Array[LegacyDefinition], deck: DeckDefinition, rules: ShopRules, rng: RandomNumberGenerator, saved: Dictionary = {}) -> void:
	_run = run
	_catalog = catalog
	_manuals = manuals
	_pills = pills
	_packs = packs
	_legacies = legacies
	_deck = deck
	_base_rules = rules
	_rules = run.shop_rules(rules)
	_rng = rng
	reroll_cost = _rules.reroll_base_cost
	# Boutique sauvegardee : on reprend ses offres sans tirer, la RNG ne bouge pas.
	if saved.is_empty():
		_roll_offers()
		var pack_pool: Array[PackDefinition] = _packs.duplicate()
		RngUtils.shuffle(pack_pool, _rng)
		pack_offers.assign(pack_pool.slice(0, _rules.pack_count))
		# Nouveau royaume : un nouvel heritage, qui reste propose jusqu'a son achat ou la fin du royaume.
		if not _legacies.is_empty() and _run.legacy_offer_realm != _run.progress.realm_number():
			_roll_legacy()
	else:
		_restore(saved)


func can_buy(index: int) -> bool:
	return (index >= 0 and index < offers.size()
		and _run.artifacts.size() < _rules.max_artifacts
		and _run.stones >= offers[index].price)


func buy(index: int) -> bool:
	if not can_buy(index):
		return false
	var artifact: ArtifactDefinition = offers[index]
	_run.stones -= artifact.price
	_run.artifacts.append(artifact)
	offers.remove_at(index)
	return true


## Un manuel n'occupe pas d'emplacement d'artefact.
func can_buy_manual(index: int) -> bool:
	return index >= 0 and index < manual_offers.size() and _run.stones >= manual_offers[index].price


func buy_manual(index: int) -> bool:
	if not can_buy_manual(index):
		return false
	var manual: ManualDefinition = manual_offers[index]
	_run.stones -= manual.price
	_run.hand_levels.level_up(manual.hand.id)
	manual_offers.remove_at(index)
	return true

func can_buy_pill(index: int) -> bool:
	return (index >= 0 and index < pill_offers.size()
		and _run.pills.size() < _rules.max_pills
		and _run.stones >= pill_offers[index].price)


func buy_pill(index: int) -> bool:
	if not can_buy_pill(index):
		return false
	var pill: PillDefinition = pill_offers[index]
	_run.stones -= pill.price
	_run.pills.append(pill)
	pill_offers.remove_at(index)
	return true

## Heritage propose pendant ce royaume, null si aucun.
func legacy_offer() -> LegacyDefinition:
	return _run.legacy_offer


func can_buy_legacy() -> bool:
	return _run.legacy_offer != null and _run.stones >= _run.legacy_offer.price


## L'heritage agit tout de suite, y compris sur cette boutique (emplacements, relance).
func buy_legacy() -> bool:
	if not can_buy_legacy():
		return false
	_run.stones -= _run.legacy_offer.price
	_run.legacies.append(_run.legacy_offer)
	_run.legacy_offer = null
	var old_base := _rules.reroll_base_cost
	_rules = _run.shop_rules(_base_rules)
	# La relance en cours suit le changement de base, sinon l'heritage ne jouerait qu'a la prochaine boutique.
	reroll_cost = maxi(0, reroll_cost + _rules.reroll_base_cost - old_base)
	return true


## Un heritage pas encore possede dont le prerequis l'est, au hasard. Aucun : rien n'est propose.
func _roll_legacy() -> void:
	var owned: Dictionary = {}
	for legacy: LegacyDefinition in _run.legacies:
		owned[legacy.id] = true
	var pool: Array[LegacyDefinition] = []
	for legacy: LegacyDefinition in _legacies:
		if not owned.has(legacy.id) and (legacy.requires.is_empty() or owned.has(legacy.requires)):
			pool.append(legacy)
	_run.legacy_offer = null if pool.is_empty() else pool[_rng.randi_range(0, pool.size() - 1)]
	_run.legacy_offer_realm = _run.progress.realm_number()


## Un seul sceau ouvert a la fois.
func can_buy_pack(index: int) -> bool:
	return (opening == null and index >= 0 and index < pack_offers.size()
		and _run.stones >= pack_offers[index].price)


## Achete et ouvre le sceau : ses choix sont tires tout de suite.
func buy_pack(index: int) -> bool:
	if not can_buy_pack(index):
		return false
	var pack: PackDefinition = pack_offers[index]
	_run.stones -= pack.price
	pack_offers.remove_at(index)
	open_pack(pack)
	return true


## Ouvre le sceau : ses choix sont tires tout de suite. Le prix se paie avant (achat), ou jamais (menu debug).
func open_pack(pack: PackDefinition) -> void:
	opening = PackOpening.new(pack, _pack_choices(pack))


## Un choix se prend s'il a une place : emplacement d'artefact ou de pilule libre (manuels et cartes : toujours).
func can_take(index: int) -> bool:
	if opening == null or index < 0 or index >= opening.choices.size():
		return false
	match opening.pack.kind:
		PackDefinition.Kind.ARTIFACT:
			return _run.artifacts.size() < _rules.max_artifacts
		PackDefinition.Kind.PILL:
			return _run.pills.size() < _rules.max_pills
	return true


## Garde ce choix (gratuit : le sceau est deja paye). Le sceau se ferme quand on a pris tout ce qu'il donne.
func take(index: int) -> bool:
	if not can_take(index):
		return false
	var choice: Resource = opening.choices[index]
	match opening.pack.kind:
		PackDefinition.Kind.ARTIFACT:
			_run.artifacts.append(choice)
		PackDefinition.Kind.MANUAL:
			_run.hand_levels.level_up((choice as ManualDefinition).hand.id)
		PackDefinition.Kind.PILL:
			_run.pills.append(choice)
		PackDefinition.Kind.CARD:
			_run.add_card(choice as CardData, _deck.ranks)
	opening.choices.remove_at(index)
	opening.picks_left -= 1
	if opening.is_done():
		opening = null
	return true


## Rangs du paquet, pour afficher les cartes d'un sceau de disciples.
func card_ranks() -> RankRules:
	return _deck.ranks


## Ferme le sceau sans prendre le reste.
func skip() -> void:
	opening = null


## Pas de relance pendant un sceau ouvert : elle changerait les artefacts possedes sous ses choix.
func can_reroll() -> bool:
	return opening == null and _run.stones >= reroll_cost


func reroll() -> bool:
	if not can_reroll():
		return false
	_run.stones -= reroll_cost
	reroll_cost += _rules.reroll_cost_step
	_roll_offers()
	return true


func _roll_offers() -> void:
	# Artefacts : jamais un deja possede, jamais deux fois le meme. Compare par id, pas par instance.
	var owned: Dictionary = {}
	for artifact: ArtifactDefinition in _run.artifacts:
		owned[artifact.id] = true
	if opening != null and opening.pack.kind == PackDefinition.Kind.ARTIFACT:
		for choice: Resource in opening.choices:
			owned[(choice as ArtifactDefinition).id] = true
	var pool: Array[ArtifactDefinition] = []
	for artifact: ArtifactDefinition in _catalog:
		if not owned.has(artifact.id):
			pool.append(artifact)
	# Manuels et pilules : rachetables d'une visite a l'autre, mais distincts dans une meme visite.
	var manual_pool: Array[ManualDefinition] = _manuals.duplicate()
	RngUtils.shuffle(manual_pool, _rng)
	var pill_pool: Array[PillDefinition] = _pills.duplicate()
	RngUtils.shuffle(pill_pool, _rng)
	var counts := _draw_kinds([pool.size(), manual_pool.size(), pill_pool.size()])
	offers.assign(_draw_artifacts(pool, counts[ShopRules.OfferKind.ARTIFACT]))
	manual_offers.assign(manual_pool.slice(0, counts[ShopRules.OfferKind.MANUAL]))
	pill_offers.assign(pill_pool.slice(0, counts[ShopRules.OfferKind.PILL]))


## Choix d'un sceau : distincts, et pour les artefacts ni possedes ni deja en vente, tires selon leur rarete.
func _pack_choices(pack: PackDefinition) -> Array[Resource]:
	var pool: Array = []
	match pack.kind:
		PackDefinition.Kind.ARTIFACT:
			var taken: Dictionary = {}
			for artifact: ArtifactDefinition in _run.artifacts + offers:
				taken[artifact.id] = true
			var artifacts: Array[ArtifactDefinition] = []
			for artifact: ArtifactDefinition in _catalog:
				if not taken.has(artifact.id):
					artifacts.append(artifact)
			pool = _draw_artifacts(artifacts, pack.choices)
		PackDefinition.Kind.MANUAL:
			pool = _manuals.duplicate()
		PackDefinition.Kind.PILL:
			pool = _pills.duplicate()
		PackDefinition.Kind.CARD:
			pool = _deck.cards.duplicate()
	if pack.kind != PackDefinition.Kind.ARTIFACT:
		RngUtils.shuffle(pool, _rng)
	var choices: Array[Resource] = []
	choices.assign(pool.slice(0, pack.choices))
	return choices


## Nombre d'offres de chaque type : un type tire par emplacement, parmi ceux qui ont encore un objet a proposer.
func _draw_kinds(available: Array[int]) -> Array[int]:
	var counts: Array[int] = [0, 0, 0]
	for slot: int in _rules.offer_count:
		var weights := _rules.kind_weights.duplicate()
		for kind: int in weights.size():
			if counts[kind] >= available[kind]:
				weights[kind] = 0.0
		if not Array(weights).any(func(weight: float) -> bool: return weight > 0.0):
			break
		counts[_rng.rand_weighted(weights)] += 1
	return counts

## count artefacts distincts : une rarete tiree selon rarity_weights (parmi celles qui en ont encore), puis un
## artefact de cette rarete au hasard.
func _draw_artifacts(pool: Array[ArtifactDefinition], count: int) -> Array[ArtifactDefinition]:
	RngUtils.shuffle(pool, _rng)
	if _rules.rarity_weights.is_empty():
		return pool.slice(0, count)
	var drawn: Array[ArtifactDefinition] = []
	while drawn.size() < count and not pool.is_empty():
		var weights := PackedFloat32Array()
		weights.resize(_rules.rarity_weights.size())
		for artifact: ArtifactDefinition in pool:
			var available := mini(artifact.rarity, weights.size() - 1)
			weights[available] = _rules.rarity_weights[available]
		var tier := _rng.rand_weighted(weights)
		# Le melange a deja mis les artefacts dans un ordre au hasard : le premier de la rarete tiree.
		for i: int in pool.size():
			if mini(pool[i].rarity, weights.size() - 1) == tier:
				drawn.append(pool[i])
				pool.remove_at(i)
				break
	return drawn


func to_dict() -> Dictionary:
	return {
		"artifacts": SaveData.ids(offers),
		"manuals": SaveData.ids(manual_offers),
		"pills": SaveData.ids(pill_offers),
		"packs": SaveData.ids(pack_offers),
		"opening": {} if opening == null else {"pack": String(opening.pack.id), "choices": SaveData.ids(opening.choices),
			"picks_left": opening.picks_left},
		"reroll_cost": reroll_cost,
	}


func _restore(saved: Dictionary) -> void:
	reroll_cost = maxi(_rules.reroll_base_cost, SaveData.int_of(saved, "reroll_cost", _rules.reroll_base_cost))
	offers.assign(_pick(_catalog, saved.get("artifacts")))
	manual_offers.assign(_pick(_manuals, saved.get("manuals")))
	pill_offers.assign(_pick(_pills, saved.get("pills")))
	pack_offers.assign(_pick(_packs, saved.get("packs")))
	# Sceau ouvert au moment de la sauvegarde : rouvert avec les memes choix.
	var saved_opening: Variant = saved.get("opening")
	if saved_opening is Dictionary and not saved_opening.is_empty():
		var found := _pick(_packs, [saved_opening.get("pack", "")])
		if not found.is_empty():
			var pack: PackDefinition = found[0]
			var lists := {PackDefinition.Kind.ARTIFACT: _catalog, PackDefinition.Kind.MANUAL: _manuals,
				PackDefinition.Kind.PILL: _pills, PackDefinition.Kind.CARD: _deck.cards}
			var choices: Array[Resource] = []
			choices.assign(_pick(lists[pack.kind], saved_opening.get("choices")))
			opening = PackOpening.new(pack, choices)
			opening.picks_left = clampi(SaveData.int_of(saved_opening, "picks_left", pack.picks), 1, pack.picks)
			if opening.is_done():
				opening = null


## Contenus du catalogue dont l'id est dans la liste sauvegardee, dans l'ordre sauvegarde.
static func _pick(list: Array, saved_ids: Variant) -> Array:
	var result: Array = []
	for id: String in SaveData.string_list(saved_ids):
		for item: Resource in list:
			if String(item.id) == id:
				result.append(item)
				break
	return result
