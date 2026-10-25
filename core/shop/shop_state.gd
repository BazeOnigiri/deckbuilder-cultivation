class_name ShopState
extends RefCounted
## Boutique entre deux goulots : offres tirees au hasard (RNG injectee), achat et relance. Logique pure.

var offers: Array[ArtifactDefinition] = []
var manual_offers: Array[ManualDefinition] = []
var pill_offers: Array[PillDefinition] = []
var reroll_cost: int

var _run: RunState
var _catalog: Array[ArtifactDefinition]
var _manuals: Array[ManualDefinition]
var _pills: Array[PillDefinition]
var _rules: ShopRules
var _rng: RandomNumberGenerator


func _init(run: RunState, catalog: Array[ArtifactDefinition], manuals: Array[ManualDefinition], pills: Array[PillDefinition], rules: ShopRules, rng: RandomNumberGenerator, saved: Dictionary = {}) -> void:
	_run = run
	_catalog = catalog
	_manuals = manuals
	_pills = pills
	_rules = rules
	_rng = rng
	reroll_cost = rules.reroll_base_cost
		# Boutique sauvegardee : on reprend ses offres sans tirer, la RNG ne bouge pas.
	if saved.is_empty():
		_roll_offers()
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

func can_reroll() -> bool:
	return _run.stones >= reroll_cost


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
	var pool: Array[ArtifactDefinition] = []
	for artifact: ArtifactDefinition in _catalog:
		if not owned.has(artifact.id):
			pool.append(artifact)
	RngUtils.shuffle(pool, _rng)
	offers.assign(pool.slice(0, _rules.offer_count))
	# Manuels : rachetables d'une visite a l'autre, mais distincts dans une meme visite.
	var manual_pool: Array[ManualDefinition] = _manuals.duplicate()
	RngUtils.shuffle(manual_pool, _rng)
	manual_offers.assign(manual_pool.slice(0, _rules.manual_offer_count))
	# Pilules : comme les manuels, rachetables d'une visite a l'autre.
	var pill_pool: Array[PillDefinition] = _pills.duplicate()
	RngUtils.shuffle(pill_pool, _rng)
	pill_offers.assign(pill_pool.slice(0, _rules.pill_offer_count))

func to_dict() -> Dictionary:
	return {
		"artifacts": _ids(offers),
		"manuals": _ids(manual_offers),
		"pills": _ids(pill_offers),
		"reroll_cost": reroll_cost,
	}


func _restore(saved: Dictionary) -> void:
	reroll_cost = maxi(_rules.reroll_base_cost, SaveData.int_of(saved, "reroll_cost", _rules.reroll_base_cost))
	offers.assign(_pick(_catalog, saved.get("artifacts")))
	manual_offers.assign(_pick(_manuals, saved.get("manuals")))
	pill_offers.assign(_pick(_pills, saved.get("pills")))


static func _ids(list: Array) -> Array[String]:
	var ids: Array[String] = []
	for item: Resource in list:
		ids.append(String(item.id))
	return ids


## Contenus du catalogue dont l'id est dans la liste sauvegardee, dans l'ordre sauvegarde.
static func _pick(list: Array, saved_ids: Variant) -> Array:
	var result: Array = []
	for id: String in SaveData.string_list(saved_ids):
		for item: Resource in list:
			if String(item.id) == id:
				result.append(item)
				break
	return result