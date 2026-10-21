extends GutTest

const REALMS_DIR := "res://content/realms"
const BOTTLENECKS_DIR := "res://content/bottlenecks"

var _realms: Array[RealmDefinition]


func before_all() -> void:
	_realms = RealmCatalog.load_definitions(REALMS_DIR)


func _tres_count(dir_path: String) -> int:
	var count: int = 0
	for file_name: String in DirAccess.get_files_at(dir_path):
		if file_name.ends_with(".tres"):
			count += 1
	return count


func test_chaque_fichier_donne_un_royaume() -> void:
	assert_gt(_realms.size(), 0)
	assert_eq(_realms.size(), _tres_count(REALMS_DIR))


func test_tous_les_royaumes_valides() -> void:
	for realm: RealmDefinition in _realms:
		assert_true(realm.is_valid(), "royaume invalide : %s" % realm.resource_path)


func test_ids_et_ordres_uniques() -> void:
	var ids: Dictionary = {}
	var orders: Dictionary = {}
	for realm: RealmDefinition in _realms:
		assert_false(ids.has(realm.id), "id en double : %s" % realm.id)
		assert_false(orders.has(realm.order), "ordre en double : %s" % realm.id)
		ids[realm.id] = true
		orders[realm.order] = true


func test_tous_les_goulots_valides() -> void:
	var bottlenecks := ContentLoader.load_all(BOTTLENECKS_DIR)
	assert_eq(bottlenecks.size(), _tres_count(BOTTLENECKS_DIR))
	for res: Resource in bottlenecks:
		var bottleneck := res as BottleneckDefinition
		assert_not_null(bottleneck, "pas un goulot : %s" % res.resource_path)
		if bottleneck != null:
			assert_true(bottleneck.is_valid(), "goulot invalide : %s" % res.resource_path)


## La difficulte ne doit jamais baisser d'un goulot au suivant.
func test_objectifs_strictement_croissants() -> void:
	var progress := RunProgress.new(_realms)
	var previous: int = progress.current_target()
	while progress.advance():
		assert_gt(progress.current_target(), previous, "objectif non croissant : %s" % progress.current_realm().id)
		previous = progress.current_target()