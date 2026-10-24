class_name ReducedHandsConstraint
extends TribulationConstraint
## Moins de mains pour ce goulot (au moins une).

@export var amount: int = 1


func hands_per_round(base: int) -> int:
	return maxi(1, base - amount)