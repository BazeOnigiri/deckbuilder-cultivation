class_name RealmDefinition
extends Resource
## Un royaume de cultivation : une suite de goulots a franchir dans l'ordre.

@export var id: StringName = &""
@export var name_key: String = ""
## Position dans la run, du plus petit au plus grand.
@export var order: int = 0
@export var base_score: int = 0
@export var bottlenecks: Array[BottleneckDefinition] = []
## Royaume genere du mode sans fin : son numero remplace le %d de name_key. 0 : royaume du contenu.
var number: int = 0


## Nom affiche, traduit.
func title() -> String:
	return tr(name_key) % number if number > 0 else tr(name_key)


func is_valid() -> bool:
	if id.is_empty() or name_key.is_empty() or base_score <= 0 or bottlenecks.is_empty():
		return false
	for bottleneck: BottleneckDefinition in bottlenecks:
		if bottleneck == null or not bottleneck.is_valid():
			return false
	return true