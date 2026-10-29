class_name EventRules
extends Resource
## Regles des rencontres en donnees : chance qu'une rencontre suive la boutique (au plus une par royaume).

@export var id: StringName = &""
@export_range(0.0, 1.0) var chance: float = 0.0


func is_valid() -> bool:
	return not id.is_empty() and chance >= 0.0 and chance <= 1.0
