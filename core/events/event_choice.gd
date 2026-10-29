class_name EventChoice
extends Resource
## Un choix de rencontre : cout optionnel, puis une issue tiree selon les poids (une seule : issue certaine).

@export var label_key: String = ""
## null : gratuit.
@export var cost: EventCost
@export var outcomes: Array[EventOutcome] = []


func is_valid() -> bool:
	return (not label_key.is_empty() and (cost == null or cost.is_valid()) and not outcomes.is_empty()
		and outcomes.all(func(outcome: EventOutcome) -> bool: return outcome != null and outcome.is_valid()))


## Cle de la raison qui rend le choix indisponible, "" s'il est possible : cout impayable, ou effet d'une des issues
## qui ne pourrait pas agir (on ne laisse pas le hasard tomber sur une issue vide).
func blocked_reason(run: RunState) -> String:
	if cost != null and not cost.blocked_reason(run).is_empty():
		return cost.blocked_reason(run)
	for outcome: EventOutcome in outcomes:
		for effect: EventEffect in outcome.effects:
			if not effect.blocked_reason(run).is_empty():
				return effect.blocked_reason(run)
	return ""


## Index de l'issue tiree. Une issue certaine ne tire rien : la RNG ne bouge pas.
func roll(rng: RandomNumberGenerator) -> int:
	if outcomes.size() == 1:
		return 0
	var weights := PackedFloat32Array()
	for outcome: EventOutcome in outcomes:
		weights.append(outcome.weight)
	return rng.rand_weighted(weights)


## Chance de cette issue, en pourcentage arrondi.
func percent_of(index: int) -> int:
	var total := 0.0
	for outcome: EventOutcome in outcomes:
		total += outcome.weight
	return roundi(outcomes[index].weight * 100.0 / total)
