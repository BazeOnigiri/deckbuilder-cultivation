class_name ElementSealConstraint
extends TribulationConstraint
## Les cartes de l'element scelle ne comptent pas.

@export var element: Element.Type = Element.Type.BOIS


func counts(card: CardInstance) -> bool:
	return card.element != element