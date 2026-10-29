class_name RunProgress
extends RefCounted
## Avancee dans une run : royaume et goulot courants, objectif a atteindre. Logique pure.
## Tient aussi les tribulations tirees de la run et les royaumes generes du mode sans fin.

## Cle du nom d'un royaume genere (%d : son numero).
const ENDLESS_NAME_KEY := "REALM_ENDLESS"

var is_finished: bool = false
## Mode sans fin : croissance de l'objectif d'un royaume genere au suivant (BalanceModel.realm_growth) et chiffres
## gardes. Poses par GameContent depuis content/rules/equilibrage.tres.
var endless_growth: float = 1.0
var significant_digits: int = 2

var _realms: Array[RealmDefinition] = []
## Royaumes du contenu, tries, avant tirage : la restauration repart d'eux.
var _base: Array[RealmDefinition] = []
var _realm_index: int = 0
var _bottleneck_index: int = 0


func _init(p_realms: Array[RealmDefinition]) -> void:
	assert(not p_realms.is_empty(), "une run demande au moins un royaume")
	_base = p_realms.duplicate()
	_base.sort_custom(func(a: RealmDefinition, b: RealmDefinition) -> bool:
		return a.order < b.order)
	_realms = _base.duplicate()


func current_realm() -> RealmDefinition:
	return _realms[_realm_index]


func current_bottleneck() -> BottleneckDefinition:
	return current_realm().bottlenecks[_bottleneck_index]


func current_target() -> int:
	return target_for(current_realm(), current_bottleneck())


## Numeros affiches, a partir de 1.
func realm_number() -> int:
	return _realm_index + 1


func realm_count() -> int:
	return _realms.size()


func bottleneck_number() -> int:
	return _bottleneck_index + 1


func realms() -> Array[RealmDefinition]:
	return _realms.duplicate()


## Royaumes generes depuis la victoire au dernier royaume du contenu.
func endless_count() -> int:
	return _realms.size() - _base.size()


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


## Tire la tribulation de chaque royaume dans pool, sans remise tant que le pool suffit. Pool vide : rien ne change.
func draw_tribulations(pool: Array[BottleneckDefinition], rng: RandomNumberGenerator) -> void:
	if pool.is_empty():
		return
	var bag: Array[BottleneckDefinition] = []
	for i: int in _realms.size():
		if bag.is_empty():
			bag = pool.duplicate()
			RngUtils.shuffle(bag, rng)
		_realms[i] = with_tribulation(_realms[i], bag.pop_back())


## Tribulation (goulot a contrainte) de chaque royaume, dans l'ordre ; null pour un royaume qui n'en a pas.
func tribulations() -> Array[BottleneckDefinition]:
	var result: Array[BottleneckDefinition] = []
	for realm: RealmDefinition in _realms:
		result.append(tribulation_of(realm))
	return result


static func tribulation_of(realm: RealmDefinition) -> BottleneckDefinition:
	for bottleneck: BottleneckDefinition in realm.bottlenecks:
		if bottleneck.constraint != null:
			return bottleneck
	return null


## Copie du royaume dont les goulots a contrainte deviennent cette tribulation. null : copie inchangee.
static func with_tribulation(realm: RealmDefinition, tribulation: BottleneckDefinition) -> RealmDefinition:
	var copy: RealmDefinition = realm.duplicate()
	copy.number = realm.number
	if tribulation == null:
		return copy
	var bottlenecks: Array[BottleneckDefinition] = []
	for bottleneck: BottleneckDefinition in realm.bottlenecks:
		bottlenecks.append(tribulation if bottleneck.constraint != null else bottleneck)
	copy.bottlenecks = bottlenecks
	return copy


## Mode sans fin : genere le royaume suivant le dernier, sa tribulation tiree dans pool (autre que la precedente
## si possible), et s'y place.
func add_endless_realm(pool: Array[BottleneckDefinition], rng: RandomNumberGenerator) -> void:
	var previous: RealmDefinition = _realms[-1]
	var choices := pool.filter(func(tribulation: BottleneckDefinition) -> bool:
		return tribulation != tribulation_of(previous))
	if choices.is_empty():
		choices = pool
	var tribulation: BottleneckDefinition = null if choices.is_empty() else choices[rng.randi_range(0, choices.size() - 1)]
	_append_endless(tribulation)
	_realm_index = _realms.size() - 1
	_bottleneck_index = 0
	is_finished = false


func _append_endless(tribulation: BottleneckDefinition) -> void:
	_realms.append(endless_realm(_realms[-1], endless_count() + 1, tribulation, endless_growth, significant_digits))


## Royaume genere numero number : les goulots du precedent, la tribulation donnee, l'objectif de base du precedent
## fois growth (meme formule que l'equilibrage), arrondi a digits chiffres.
static func endless_realm(previous: RealmDefinition, number: int, tribulation: BottleneckDefinition, growth: float,
		digits: int) -> RealmDefinition:
	var realm := with_tribulation(previous, tribulation)
	realm.id = StringName("royaume_sans_fin_%d" % number)
	realm.name_key = ENDLESS_NAME_KEY
	realm.number = number
	realm.order = previous.order + 1
	realm.base_score = roundi(BalanceModel.round_to_digits(previous.base_score * growth, digits))
	return realm


func to_dict() -> Dictionary:
	var ids: Array[String] = []
	for tribulation: BottleneckDefinition in tribulations():
		ids.append("" if tribulation == null else String(tribulation.id))
	return {"realm": _realm_index, "bottleneck": _bottleneck_index, "tribulations": ids, "endless": endless_count()}


## Pour la sauvegarde. pool : les tribulations du contenu, retrouvees par id (id inconnu ou absent : celle du
## contenu). Refuse (false, rien ne change) une position hors des royaumes connus.
func restore(data: Variant, pool: Array[BottleneckDefinition] = []) -> bool:
	if not data is Dictionary:
		return false
	var ids := SaveData.string_list(data.get("tribulations"))
	var rebuilt: Array[RealmDefinition] = []
	for i: int in _base.size():
		var tribulation := _find(pool, ids[i]) if i < ids.size() else null
		rebuilt.append(_base[i] if tribulation == null else with_tribulation(_base[i], tribulation))
	var previous_realms := _realms
	_realms = rebuilt
	for n: int in maxi(0, SaveData.int_of(data, "endless")):
		var index := _base.size() + n
		_append_endless(_find(pool, ids[index]) if index < ids.size() else null)
	var realm: int = SaveData.int_of(data, "realm", -1)
	var bottleneck: int = SaveData.int_of(data, "bottleneck", -1)
	if realm < 0 or realm >= _realms.size() or bottleneck < 0 or bottleneck >= _realms[realm].bottlenecks.size():
		_realms = previous_realms
		return false
	_realm_index = realm
	_bottleneck_index = bottleneck
	is_finished = false
	return true


static func _find(pool: Array[BottleneckDefinition], id: String) -> BottleneckDefinition:
	for tribulation: BottleneckDefinition in pool:
		if String(tribulation.id) == id:
			return tribulation
	return null
