extends GutTest
## Detecteurs avec une carte du chaos originel (tous les elements) et une carte de roc (sans rang).

const C := preload("res://test/helpers/cards.gd")


func _wild() -> EnhancementDefinition:
	var enhancement := EnhancementDefinition.new()
	enhancement.any_element = true
	return enhancement


func _rock() -> EnhancementDefinition:
	var enhancement := EnhancementDefinition.new()
	enhancement.rankless = true
	enhancement.fixed_qi = 50
	return enhancement


func _with_wild(specs: Array, wild_indexes: Array) -> Array[CardInstance]:
	var cards := C.hand(specs)
	for i: int in wild_indexes:
		cards[i].enhancement = _wild()
	return cards


func _elements(mode: ElementDetector.Mode) -> ElementDetector:
	var detector := ElementDetector.new()
	detector.mode = mode
	detector.count = 5
	return detector


func _straight(same: bool, cycle: ElementCycle = null) -> StraightDetector:
	var detector := StraightDetector.new()
	detector.length = 5
	detector.require_same_element = same
	detector.cycle = cycle
	return detector


func test_purete_avec_une_carte_du_chaos() -> void:
	var cards := _with_wild([[C.FEU, 2], [C.FEU, 5], [C.EAU, 7], [C.FEU, 9], [C.FEU, 11]], [2])
	assert_eq(_elements(ElementDetector.Mode.SAME).detect(cards).size(), 5)
	var mixed := _with_wild([[C.FEU, 2], [C.BOIS, 5], [C.EAU, 7], [C.FEU, 9], [C.FEU, 11]], [2])
	assert_true(_elements(ElementDetector.Mode.SAME).detect(mixed).is_empty(), "une autre carte fixe casse la purete")


func test_harmonie_avec_une_carte_du_chaos() -> void:
	# Quatre elements distincts + une carte du chaos (de feu, deja present) : elle prend l'element qui manque.
	var cards := _with_wild([[C.BOIS, 2], [C.FEU, 5], [C.TERRE, 7], [C.METAL, 9], [C.FEU, 11]], [4])
	assert_eq(_elements(ElementDetector.Mode.DISTINCT).detect(cards).size(), 5)
	var doubled := _with_wild([[C.BOIS, 2], [C.BOIS, 5], [C.TERRE, 7], [C.METAL, 9], [C.FEU, 11]], [4])
	assert_true(_elements(ElementDetector.Mode.DISTINCT).detect(doubled).is_empty(), "deux bois fixes : pas d'harmonie")


func test_ascension_pure_avec_une_carte_du_chaos() -> void:
	var cards := _with_wild([[C.EAU, 3], [C.EAU, 4], [C.BOIS, 5], [C.EAU, 6], [C.EAU, 7]], [2])
	assert_eq(_straight(true).detect(cards).size(), 5)


func test_cycle_avec_une_carte_du_chaos() -> void:
	var cycle: ElementCycle = load("res://content/cycles/cycle_engendrement.tres")
	# bois > feu > terre > metal > eau : la carte du chaos (eau) tient la place du feu.
	var cards := _with_wild([[C.BOIS, 3], [C.EAU, 4], [C.TERRE, 5], [C.METAL, 6], [C.EAU, 7]], [1])
	assert_eq(_straight(false, cycle).detect(cards).size(), 5)
	# En premiere position : la suite part de l'element qui precede le feu.
	var first := _with_wild([[C.METAL, 3], [C.FEU, 4], [C.TERRE, 5], [C.METAL, 6], [C.EAU, 7]], [0])
	assert_eq(_straight(false, cycle).detect(first).size(), 5)
	var broken := _with_wild([[C.BOIS, 3], [C.EAU, 4], [C.METAL, 5], [C.METAL, 6], [C.EAU, 7]], [1])
	assert_true(_straight(false, cycle).detect(broken).is_empty())
	var all_wild := _with_wild([[C.BOIS, 3], [C.BOIS, 4], [C.BOIS, 5], [C.BOIS, 6], [C.BOIS, 7]], [0, 1, 2, 3, 4])
	assert_eq(_straight(false, cycle).detect(all_wild).size(), 5)


func test_carte_de_roc_compte_sans_former_de_combinaison() -> void:
	var evaluator := HandEvaluator.new(HandCatalog.load_definitions())
	var cards := C.hand([[C.FEU, 7], [C.EAU, 7], [C.BOIS, 7]])
	cards[2].enhancement = _rock()
	var result := evaluator.evaluate(cards)
	assert_eq(result.definition.id, "main_paire", "la carte de roc n'est pas un troisieme 7")
	assert_true(result.scoring_cards.has(cards[2]), "elle compte quand meme")
	assert_eq(result.scoring_cards.size(), 3)


func test_roc_casse_une_combinaison_de_cinq() -> void:
	var evaluator := HandEvaluator.new(HandCatalog.load_definitions())
	var cards := C.hand([[C.FEU, 2], [C.FEU, 5], [C.FEU, 7], [C.FEU, 9], [C.FEU, 11]])
	cards[4].enhancement = _rock()
	assert_ne(evaluator.evaluate(cards).definition.id, "main_purete")


func test_que_des_cartes_de_roc_donnent_la_main_la_plus_faible() -> void:
	var evaluator := HandEvaluator.new(HandCatalog.load_definitions())
	var cards := C.hand([[C.FEU, 4], [C.EAU, 4]])
	for card: CardInstance in cards:
		card.enhancement = _rock()
	var result := evaluator.evaluate(cards)
	assert_eq(result.definition.id, "main_souffle")
	assert_eq(result.scoring_cards.size(), 2)


func test_conditions_et_sceaux_d_element() -> void:
	var wild := _with_wild([[C.FEU, 4]], [0])[0]
	var condition := CardElementCondition.new()
	condition.element = Element.Type.EAU
	assert_true(condition.matches(null, wild))
	var seal := ElementSealConstraint.new()
	seal.element = Element.Type.EAU
	assert_false(seal.counts(wild), "la tribulation de l'eau scelle aussi la carte du chaos")
	var rock := C.hand([[C.FEU, 12]])[0]
	rock.enhancement = _rock()
	assert_true(RankSealConstraint.new().counts(rock), "sans rang : jamais scellee par le rang")
	assert_false(CardRankCondition.new().matches(null, rock))
