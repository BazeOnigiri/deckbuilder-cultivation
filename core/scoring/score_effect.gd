class_name ScoreEffect
extends Resource
## Modification du score, appliquee pendant sa phase. Les artefacts et pilules en fourniront.

## L'ordre de l'enum EST l'ordre d'application : additions puis multiplications.
enum Phase {ADD_QI, ADD_COMPREHENSION, MULT_COMPREHENSION}

@export var phase: Phase = Phase.ADD_QI
@export var amount: float = 0.0


func apply(context: ScoreContext) -> void:
	match phase:
		Phase.ADD_QI:
			context.qi += roundi(amount)
		Phase.ADD_COMPREHENSION:
			context.comprehension += amount
		Phase.MULT_COMPREHENSION:
			context.comprehension *= amount