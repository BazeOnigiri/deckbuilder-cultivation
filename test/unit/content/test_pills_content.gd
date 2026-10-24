extends GutTest

const PILLS_DIR := "res://content/pills"

var _pills: Array[PillDefinition]


func before_all() -> void:
	_pills = PillCatalog.load_definitions(PILLS_DIR)


func test_chaque_fichier_donne_une_pilule() -> void:
	var count: int = 0
	for file_name: String in DirAccess.get_files_at(PILLS_DIR):
		if file_name.ends_with(".tres"):
			count += 1
	assert_gt(_pills.size(), 0)
	assert_eq(_pills.size(), count)


func test_toutes_les_pilules_valides() -> void:
	for pill: PillDefinition in _pills:
		assert_true(pill.is_valid(), "pilule invalide : %s" % pill.resource_path)


func test_ids_uniques() -> void:
	var ids: Dictionary = {}
	for pill: PillDefinition in _pills:
		assert_false(ids.has(pill.id), "id en double : %s" % pill.id)
		ids[pill.id] = true