class_name RoundRules
extends Resource
## Regles d'un round en donnees. Les valeurs vivent dans content/rules/, jamais dans le code.

@export var id: String = ""
@export var hand_size: int = 0


func is_valid() -> bool:
	return not id.is_empty() and hand_size > 0