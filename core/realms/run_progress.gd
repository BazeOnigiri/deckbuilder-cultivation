class_name RunProgress
extends RefCounted
## Avancee dans une run : royaume et goulot courants, objectif a atteindre. Logique pure.

var is_finished: bool = false

var _realms: Array[RealmDefinition] = []
var _realm_index: int = 0
var _bottleneck_index: int = 0


func _init(p_realms: Array[RealmDefinition]) -> void:
	assert(not p_realms.is_empty(), "une run demande au moins un royaume")
	_realms = p_realms.duplicate()
	_realms.sort_custom(func(a: RealmDefinition, b: RealmDefinition) -> bool:
		return a.order < b.order)


func current_realm() -> RealmDefinition:
	return _realms[_realm_index]


func current_bottleneck() -> BottleneckDefinition:
	return current_realm().bottlenecks[_bottleneck_index]


func current_target() -> int:
	return target_for(current_realm(), current_bottleneck())


static func target_for(realm: RealmDefinition, bottleneck: BottleneckDefinition) -> int:
	return roundi(realm.base_score * bottleneck.score_multiplier)


## Goulot du royaume courant : -1 franchi, 0 en cours, 1 a venir. Run terminee : tout est franchi.
func bottleneck_position(bottleneck_index: int) -> int:
	if is_finished or bottleneck_index < _bottleneck_index:
		return -1
	return 0 if bottleneck_index == _bottleneck_index else 1


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

func to_dict() -> Dictionary:
	return {"realm": _realm_index, "bottleneck": _bottleneck_index}


## Pour la sauvegarde. Refuse (false, rien ne change) une position hors des royaumes connus.
func restore(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	var realm: int = SaveData.int_of(data, "realm", -1)
	var bottleneck: int = SaveData.int_of(data, "bottleneck", -1)
	if realm < 0 or realm >= _realms.size():
		return false
	if bottleneck < 0 or bottleneck >= _realms[realm].bottlenecks.size():
		return false
	_realm_index = realm
	_bottleneck_index = bottleneck
	is_finished = false
	return true