class_name AchievementDefinition
extends Resource
## Un succes (content/achievements/) : obtenu une fois, garde dans le profil.

@export var id: StringName = &""
@export var name_key: String = ""
@export var description_key: String = ""
## Caractere dessine sur le sceau du succes (police des sceaux).
@export var glyph: String = ""
@export var condition: UnlockCondition


func is_valid() -> bool:
	return (not id.is_empty() and not name_key.is_empty() and not description_key.is_empty()
		and not glyph.is_empty() and condition != null and condition.is_valid())
