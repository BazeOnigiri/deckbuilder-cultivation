class_name CardElementCondition
extends ArtifactCondition
## Vraie pour une carte de l'element donne. Toujours fausse sans carte (declencheur HAND_PLAYED).

@export var element: Element.Type = Element.Type.BOIS


func matches(_result: HandResult, card: CardInstance) -> bool:
	return card != null and card.element == element