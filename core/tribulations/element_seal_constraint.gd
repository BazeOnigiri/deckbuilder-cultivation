class_name ElementSealConstraint
extends TribulationConstraint
## Les cartes de l'element scelle ne comptent pas, ni celles qui comptent pour tous les elements.

@export var element: Element.Type = Element.Type.BOIS


func counts(card: CardInstance) -> bool:
	return not card.has_element(element)