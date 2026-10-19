extends GutTest

const C := preload("res://test/helpers/cards.gd")


func _definition(id: String, priority: int, detector: HandDetector) -> HandDefinition:
	var definition := HandDefinition.new()
	definition.id = id
	definition.name_key = id
	definition.priority = priority
	definition.base_comprehension = 1
	definition.detector = detector
	return definition


func _pair_detector() -> RankGroupDetector:
	var detector := RankGroupDetector.new()
	detector.group_sizes = [2]
	return detector


func test_prend_la_main_la_plus_prioritaire() -> void:
	var definitions: Array[HandDefinition] = [
		_definition("souffle", 10, HighCardDetector.new()),
		_definition("paire", 20, _pair_detector()),
	]
	var evaluator := HandEvaluator.new(definitions)
	var result := evaluator.evaluate(C.hand([[C.BOIS, 4], [C.FEU, 4], [C.EAU, 9]]))
	assert_eq(result.definition.id, "paire")
	assert_eq(result.scoring_cards.size(), 2)


func test_ordre_de_la_liste_sans_importance() -> void:
	var definitions: Array[HandDefinition] = [
		_definition("paire", 20, _pair_detector()),
		_definition("souffle", 10, HighCardDetector.new()),
	]
	var evaluator := HandEvaluator.new(definitions)
	var result := evaluator.evaluate(C.hand([[C.BOIS, 2], [C.FEU, 7]]))
	assert_eq(result.definition.id, "souffle")


func test_main_vide_renvoie_null() -> void:
	var definitions: Array[HandDefinition] = [_definition("souffle", 10, HighCardDetector.new())]
	var evaluator := HandEvaluator.new(definitions)
	assert_null(evaluator.evaluate(C.hand([])))