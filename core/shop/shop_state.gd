class_name ShopState
extends RefCounted
## Boutique entre deux goulots : offres tirees au hasard (RNG injectee), achat et relance. Logique pure.

var offers: Array[ArtifactDefinition] = []
var reroll_cost: int

var _run: RunState
var _catalog: Array[ArtifactDefinition]
var _rules: ShopRules
var _rng: RandomNumberGenerator


func _init(run: RunState, catalog: Array[ArtifactDefinition], rules: ShopRules, rng: RandomNumberGenerator) -> void:
	_run = run
	_catalog = catalog
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


func can_reroll() -> bool:
	return _run.stones >= reroll_cost


func reroll() -> bool:
	if not can_reroll():
		return false
	_run.stones -= reroll_cost
	reroll_cost += _rules.reroll_cost_step
	_roll_offers()
	return true


## Jamais un artefact deja possede, jamais deux fois le meme. Compare par id, pas par instance.
func _roll_offers() -> void:
	var owned: Dictionary = {}
	for artifact: ArtifactDefinition in _run.artifacts:
		owned[artifact.id] = true
	var pool: Array[ArtifactDefinition] = []
	for artifact: ArtifactDefinition in _catalog:
		if not owned.has(artifact.id):
			pool.append(artifact)
	RngUtils.shuffle(pool, _rng)
	offers.assign(pool.slice(0, _rules.offer_count))