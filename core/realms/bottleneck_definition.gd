class_name BottleneckDefinition
extends Resource
## Un goulot d'etranglement : son objectif vaut base_score du royaume x score_multiplier.

@export var id: StringName = &""
@export var name_key: String = ""
@export var score_multiplier: float = 0.0


func is_valid() -> bool:
	return not id.is_empty() and not name_key.is_empty() and score_multiplier > 0.0