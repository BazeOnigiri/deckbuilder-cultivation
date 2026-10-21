class_name ShopRules
extends Resource
## Regles de la boutique en donnees.

@export var id: StringName = &""
@export var offer_count: int = 0
@export var reroll_base_cost: int = 0
## Le cout de relance augmente de ce montant a chaque relance, et repart de la base a chaque visite.
@export var reroll_cost_step: int = 0
@export var max_artifacts: int = 0


func is_valid() -> bool:
	return (not id.is_empty() and offer_count > 0 and reroll_base_cost >= 0
		and reroll_cost_step >= 0 and max_artifacts > 0)