class_name ReducedHandSizeConstraint
extends TribulationConstraint
## Main plus petite pour ce goulot (au moins une carte).

@export var amount: int = 1


func hand_size(base: int) -> int:
	return maxi(1, base - amount)