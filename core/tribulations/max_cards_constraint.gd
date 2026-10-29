class_name MaxCardsConstraint
extends TribulationConstraint
## On ne joue ni ne defausse plus de amount cartes a la fois (au moins une).

@export var amount: int = 4


func max_selected_cards(base: int) -> int:
	return clampi(amount, 1, base)
