# res://core/cards/element_cycle.gd
class_name ElementCycle
extends Resource
## Un cycle ordonné d'éléments : chaque élément engendre le suivant,
## le dernier engendre le premier. Un nouveau cycle = un nouveau .tres, sans code.

@export var order: Array[Element.Type] = []


## Vrai si chaque élément apparaît exactement une fois.
func is_valid() -> bool:
	if order.size() != Element.Type.size():
		return false
	for value: int in Element.Type.values():
		if not order.has(value):
			return false
	return true


## L'élément engendré par `element`.
## Précondition : le cycle est valide et contient `element`.
func next_of(element: Element.Type) -> Element.Type:
	var index: int = order.find(element)
	assert(index != -1, "ElementCycle.next_of : élément absent du cycle")
	return order[(index + 1) % order.size()]


## Vrai si `to` est l'élément engendré par `from`.
func follows(from: Element.Type, to: Element.Type) -> bool:
	return order.has(from) and next_of(from) == to