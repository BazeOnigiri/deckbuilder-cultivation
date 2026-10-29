class_name DifficultyDefinition
extends Resource
## Niveau de difficulte (mise) : ses modificateurs s'ajoutent a ceux de tous les niveaux inferieurs.
## Le niveau N + 1 se debloque en gagnant une partie au niveau N (ProfileStats.difficulty_unlocked).

@export var id: StringName = &""
@export var name_key: String = ""
## Ce que ce niveau ajoute aux precedents.
@export var description_key: String = ""
## 1 : le jeu de base, sans modificateur.
@export var level: int = 1
@export var modifiers: Array[RuleModifier] = []


func is_valid() -> bool:
	return (not id.is_empty() and not name_key.is_empty() and not description_key.is_empty() and level >= 1
		and modifiers.all(func(modifier: RuleModifier) -> bool:
			return modifier != null and not modifier.property.is_empty() and modifier.amount != 0))
