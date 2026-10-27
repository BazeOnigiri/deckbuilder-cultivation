class_name CardSpring
extends RefCounted
## Ressort amorti : la valeur suit sa cible avec un leger rebond.
## Vector3 pour regrouper ce qui bouge ensemble, ex : (x, y, angle) ou (inclinaison x, inclinaison y, echelle).

## Pas fixe : un ressort avance par grands pas diverge.
const MAX_STEP := 1.0 / 120.0
## Apres une longue pause (onglet en arriere-plan), on ne rattrape pas tout d'un coup.
const MAX_DELTA := 0.25

var value: Vector3
var velocity: Vector3 = Vector3.ZERO


func _init(start: Vector3) -> void:
	value = start


func step(target: Vector3, delta: float, stiffness: float, damping: float) -> void:
	var remaining: float = minf(delta, MAX_DELTA)
	while remaining > 0.0:
		var dt: float = minf(remaining, MAX_STEP)
		velocity += ((target - value) * stiffness - velocity * damping) * dt
		value += velocity * dt
		remaining -= dt


func snap(target: Vector3) -> void:
	value = target
	velocity = Vector3.ZERO
