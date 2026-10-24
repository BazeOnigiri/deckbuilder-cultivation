class_name ShopState
extends RefCounted
## Boutique entre deux goulots : offres tirees au hasard (RNG injectee), achat et relance. Logique pure.

var offers: Array[ArtifactDefinition] = []
var manual_offers: Array[ManualDefinition] = []
var reroll_cost: int

var _run: RunState
var _catalog: Array[ArtifactDefinition]
var _manuals: Array[ManualDefinition]
var _rules: ShopRules
var _rng: RandomNumberGenerator


func _init(run: RunState, catalog: Array[ArtifactDefinition], manuals: Array[ManualDefinition], rules: ShopRules, rng: RandomNumberGenerator) -> void:
	_run = run
	_catalog = catalog
	_manuals = manuals
	_rules = rules
	_rng = rng
	reroll_cost = rules.reroll_base_cost
	_roll_offers()


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