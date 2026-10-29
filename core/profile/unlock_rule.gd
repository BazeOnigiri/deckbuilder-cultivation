class_name UnlockRule
extends Resource
## Verrou d'un contenu (artefact, pilule, heritage, sceau) : verrouille au depart, ouvert quand la condition est
## remplie, pour toujours. Un contenu sans regle est ouvert d'emblee (content/unlocks/).

@export var content_id: StringName = &""
@export var condition: UnlockCondition


func is_valid() -> bool:
	return not content_id.is_empty() and condition != null and condition.is_valid()
