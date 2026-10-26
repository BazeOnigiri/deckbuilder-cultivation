class_name ArtifactDefinition
extends Resource
## Un artefact ou une bete spirituelle : une liste d'effets declenches pendant le score.

@export var id: StringName = &""
@export var name_key: String = ""
@export var description_key: String = ""
## Caractere dessine dans son emplacement (police des sceaux, ui/fonts/MaShanZheng-Sceaux.ttf).
@export var glyph: String = ""
## Prix en pierres spirituelles (utilise par la boutique).
@export var price: int = 0
@export var effects: Array[ArtifactEffect] = []


func is_valid() -> bool:
	if id.is_empty() or name_key.is_empty() or description_key.is_empty() or price <= 0 or effects.is_empty():
		return false
	for effect: ArtifactEffect in effects:
		if effect == null or not effect.is_valid():
			return false
	return true