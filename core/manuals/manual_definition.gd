class_name ManualDefinition
extends Resource
## Manuel de technique : fait monter une main d'un niveau. Nom et description viennent de la main.

@export var id: StringName = &""
@export var hand: HandDefinition
@export var price: int = 0


func is_valid() -> bool:
	return not id.is_empty() and hand != null and price > 0