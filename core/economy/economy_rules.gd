class_name EconomyRules
extends Resource
## Regles de l'economie en donnees : pierres de depart, recompense par main restante, interets.

@export var id: StringName = &""
@export var starting_stones: int = 0
@export var stones_per_hand_left: int = 0
## 1 pierre d'interet par tranche de interest_step pierres possedees.
@export var interest_step: int = 0
@export var interest_cap: int = 0


func is_valid() -> bool:
	return (not id.is_empty() and starting_stones >= 0 and stones_per_hand_left >= 0
		and interest_step > 0 and interest_cap >= 0)