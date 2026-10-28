class_name DiscardCostConstraint
extends TribulationConstraint
## Chaque defausse coute aussi amount mains ; on ne peut pas defausser sa derniere main.

@export var amount: int = 1


func discard_hand_cost() -> int:
	return amount
