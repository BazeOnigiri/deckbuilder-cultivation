class_name RunProgress
extends RefCounted
## Avancee dans une run : royaume et goulot courants, objectif a atteindre. Logique pure.

var is_finished: bool = false

var _realms: Array[RealmDefinition] = []
var _realm_index: int = 0
var _bottleneck_index: int = 0


func _init(realms: Array[RealmDefinition]) -> void:
	assert(not realms.is_empty(), "une run demande au moins un royaume")
	_realms = realms.duplicate()
	_realms.sort_custom(func(a: RealmDefinition, b: RealmDefinition) -> bool:
		return a.order < b.order)


func current_realm() -> RealmDefinition:
	return _realms[_realm_index]


func current_bottleneck() -> BottleneckDefinition:
	return current_realm().bottlenecks[_bottleneck_index]


func current_target() -> int:
	return roundi(current_realm().base_score * current_bottleneck().score_multiplier)


## Passe au goulot suivant. Renvoie false si la run est terminee (on reste alors sur le dernier goulot).
func advance() -> bool:
	if is_finished:
		return false
	_bottleneck_index += 1
	if _bottleneck_index < current_realm().bottlenecks.size():
		return true
	if _realm_index + 1 < _realms.size():
		_realm_index += 1
		_bottleneck_index = 0
		return true
	_bottleneck_index -= 1
	is_finished = true
	return false