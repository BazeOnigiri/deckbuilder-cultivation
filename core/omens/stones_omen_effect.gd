class_name StonesOmenEffect
extends OmenEffect
## amount pierres tout de suite.

@export var amount: int = 0


func apply_now(run: RunState, _rng: RandomNumberGenerator) -> void:
	run.stones += amount
	run.stats.stones_earned += amount
