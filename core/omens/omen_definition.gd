class_name OmenDefinition
extends Resource
## Presage 兆 : gagne en passant un goulot (sans le combattre). Son effet agit tout de suite, a la prochaine boutique
## ou a la prochaine recompense de goulot (OmenEffect.timing).

@export var id: StringName = &""
@export var name_key: String = ""
@export var description_key: String = ""
## Caractere dessine dans son emplacement (police des sceaux).
@export var glyph: String = ""
@export var effect: OmenEffect


func is_valid() -> bool:
	return not id.is_empty() and not name_key.is_empty() and not description_key.is_empty() and effect != null
