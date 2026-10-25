class_name BottleneckDefinition
extends Resource
## Un goulot d'etranglement : son objectif vaut base_score du royaume x score_multiplier.

@export var id: StringName = &""
@export var name_key: String = ""
@export var score_multiplier: float = 0.0
## Pierres spirituelles de base gagnees en le franchissant.
@export var reward: int = 0
## Vide = aucune contrainte. Les tribulations en ont une.
@export var constraint: TribulationConstraint


func is_valid() -> bool:
	if id.is_empty() or name_key.is_empty() or score_multiplier <= 0.0 or reward < 0:
		return false
	return constraint == null or not constraint.description_key.is_empty()