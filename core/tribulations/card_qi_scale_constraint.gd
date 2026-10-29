class_name CardQiScaleConstraint
extends TribulationConstraint
## Les cartes qui comptent n'apportent que cette part de leur Qi (arrondie au plus proche).

@export_range(0.0, 1.0) var scale: float = 0.5


func card_qi_scale() -> float:
	return scale
