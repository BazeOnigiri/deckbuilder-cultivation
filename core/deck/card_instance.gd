class_name CardInstance
extends RefCounted
## Une carte dans une partie. Copie l'element et le rang de sa CardData immuable :
## pilules et effets modifient cette copie, jamais la definition partagee.

var uid: int
var data: CardData
var element: Element.Type
var rank: int


func _init(p_uid: int, p_data: CardData) -> void:
	uid = p_uid
	data = p_data
	element = p_data.element
	rank = p_data.rank


## Vrai si une pilule ou un effet a change l'element ou le rang depuis la definition.
func is_altered() -> bool:
	return element != data.element or rank != data.rank