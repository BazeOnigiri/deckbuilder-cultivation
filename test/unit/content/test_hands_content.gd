extends GutTest

const C := preload("res://test/helpers/cards.gd")
const HANDS_DIR := "res://content/hands"

var _definitions: Array[HandDefinition]


func before_all() -> void:
	_definitions = HandCatalog.load_definitions(HANDS_DIR)


func test_catalogue_non_vide() -> void:
	assert_gt(_definitions.size(), 0)


## Un .tres casse est ignore par ContentLoader : ce test le rend visible.
func test_chaque_fichier_donne_une_main() -> void:
	var file_count: int = 0
	for file_name: String in DirAccess.get_files_at(HANDS_DIR):
		if file_name.ends_with(".tres"):
			file_count += 1
	assert_eq(_definitions.size(), file_count)


func test_toutes_les_mains_valides() -> void:
	for definition: HandDefinition in _definitions:
		assert_true(definition.is_valid(), "main invalide : %s" % definition.resource_path)


func test_ids_uniques() -> void:
	var ids: Dictionary = {}
	for definition: HandDefinition in _definitions:
		assert_false(ids.has(definition.id), "id en double : %s" % definition.id)
		ids[definition.id] = true


func test_priorites_uniques() -> void:
	var priorities: Dictionary = {}
	for definition: HandDefinition in _definitions:
		assert_false(priorities.has(definition.priority), "priorite en double : %s" % definition.id)
		priorities[definition.priority] = true


## Chaque exemple doit etre reconnu comme la main attendue (verifie aussi les priorites).
func test_exemples_reconnus() -> void:
	var examples: Array = [
		["main_souffle", [[C.FEU, 9]]],
		["main_souffle", [[C.BOIS, 1], [C.FEU, 3], [C.TERRE, 5], [C.METAL, 7], [C.BOIS, 9]]],
		["main_paire", [[C.BOIS, 4], [C.FEU, 4], [C.TERRE, 7], [C.METAL, 9], [C.BOIS, 1]]],
		["main_double_paire", [[C.BOIS, 4], [C.FEU, 4], [C.TERRE, 7], [C.METAL, 7], [C.BOIS, 1]]],
		["main_harmonie", [[C.BOIS, 1], [C.FEU, 3], [C.TERRE, 5], [C.METAL, 7], [C.EAU, 9]]],
		["main_brelan", [[C.BOIS, 6], [C.FEU, 6], [C.TERRE, 6], [C.METAL, 2], [C.BOIS, 9]]],
		["main_ascension", [[C.BOIS, 3], [C.BOIS, 4], [C.FEU, 5], [C.EAU, 6], [C.TERRE, 7]]],
		["main_full", [[C.BOIS, 8], [C.FEU, 8], [C.TERRE, 8], [C.METAL, 2], [C.EAU, 2]]],
		["main_purete", [[C.EAU, 1], [C.EAU, 3], [C.EAU, 5], [C.EAU, 7], [C.EAU, 9]]],
		["main_carre", [[C.BOIS, 5], [C.FEU, 5], [C.TERRE, 5], [C.METAL, 5], [C.EAU, 9]]],
		["main_ascension_pure", [[C.FEU, 2], [C.FEU, 3], [C.FEU, 4], [C.FEU, 5], [C.FEU, 6]]],
		["main_cycle_engendrement", [[C.EAU, 7], [C.BOIS, 3], [C.METAL, 6], [C.FEU, 4], [C.TERRE, 5]]],
		["main_cinq_souverains", [[C.BOIS, 7], [C.FEU, 7], [C.TERRE, 7], [C.METAL, 7], [C.EAU, 7]]],
	]
	var evaluator := HandEvaluator.new(_definitions)
	for example: Array in examples:
		var result := evaluator.evaluate(C.hand(example[1]))
		assert_not_null(result, "aucune main pour %s" % example[0])
		if result != null:
			assert_eq(result.definition.id, example[0])