extends GutTest

const C := preload("res://test/helpers/cards.gd")
const CYCLE_PATH := "res://content/cycles/cycle_engendrement.tres"


func _ranks(cards: Array[CardInstance]) -> Array:
	var ranks: Array = []
	for card: CardInstance in cards:
		ranks.append(card.rank)
	return ranks


func _rank_group(sizes: Array[int]) -> RankGroupDetector:
	var detector := RankGroupDetector.new()
	detector.group_sizes = sizes
	return detector


# --- Carte haute ---

func test_high_card_prend_la_plus_haute() -> void:
	var cards := C.hand([[C.BOIS, 2], [C.FEU, 9], [C.EAU, 5]])
	assert_eq(_ranks(HighCardDetector.new().detect(cards)), [9])


func test_high_card_main_vide() -> void:
	var cards := C.hand([])
	assert_true(HighCardDetector.new().detect(cards).is_empty())


# --- Groupes de rangs ---

func test_paire_renvoie_les_deux_cartes() -> void:
	var cards := C.hand([[C.BOIS, 4], [C.FEU, 4], [C.EAU, 7]])
	assert_eq(_ranks(_rank_group([2]).detect(cards)), [4, 4])


func test_paire_absente() -> void:
	var cards := C.hand([[C.BOIS, 4], [C.FEU, 5], [C.EAU, 7]])
	assert_true(_rank_group([2]).detect(cards).is_empty())


func test_paire_prend_la_plus_haute() -> void:
	var cards := C.hand([[C.BOIS, 3], [C.FEU, 3], [C.EAU, 8], [C.METAL, 8]])
	assert_eq(_ranks(_rank_group([2]).detect(cards)), [8, 8])


func test_double_paire() -> void:
	var cards := C.hand([[C.BOIS, 3], [C.FEU, 3], [C.EAU, 8], [C.METAL, 8], [C.TERRE, 1]])
	assert_eq(_ranks(_rank_group([2, 2]).detect(cards)), [8, 8, 3, 3])


func test_full() -> void:
	var cards := C.hand([[C.BOIS, 2], [C.FEU, 2], [C.EAU, 6], [C.METAL, 6], [C.TERRE, 6]])
	assert_eq(_ranks(_rank_group([3, 2]).detect(cards)), [6, 6, 6, 2, 2])


func test_full_refuse_brelan_seul() -> void:
	var cards := C.hand([[C.BOIS, 2], [C.FEU, 5], [C.EAU, 6], [C.METAL, 6], [C.TERRE, 6]])
	assert_true(_rank_group([3, 2]).detect(cards).is_empty())


func test_groupes_vides_ne_correspondent_jamais() -> void:
	var cards := C.hand([[C.BOIS, 2], [C.FEU, 2]])
	assert_true(_rank_group([]).detect(cards).is_empty())


# --- Suites ---

func test_ascension_desordre_accepte() -> void:
	var detector := StraightDetector.new()
	detector.length = 5
	var cards := C.hand([[C.BOIS, 6], [C.FEU, 3], [C.EAU, 5], [C.METAL, 7], [C.TERRE, 4]])
	assert_eq(_ranks(detector.detect(cards)), [3, 4, 5, 6, 7])


func test_ascension_trou_refuse() -> void:
	var detector := StraightDetector.new()
	detector.length = 5
	var cards := C.hand([[C.BOIS, 1], [C.FEU, 2], [C.EAU, 3], [C.METAL, 4], [C.TERRE, 6]])
	assert_true(detector.detect(cards).is_empty())


func test_ascension_mauvaise_taille_refuse() -> void:
	var detector := StraightDetector.new()
	detector.length = 5
	var cards := C.hand([[C.BOIS, 1], [C.FEU, 2], [C.EAU, 3], [C.METAL, 4]])
	assert_true(detector.detect(cards).is_empty())


func test_ascension_pure_exige_meme_element() -> void:
	var detector := StraightDetector.new()
	detector.length = 5
	detector.require_same_element = true
	var pure := C.hand([[C.FEU, 2], [C.FEU, 3], [C.FEU, 4], [C.FEU, 5], [C.FEU, 6]])
	var mixte := C.hand([[C.FEU, 2], [C.FEU, 3], [C.FEU, 4], [C.FEU, 5], [C.EAU, 6]])
	assert_eq(detector.detect(pure).size(), 5)
	assert_true(detector.detect(mixte).is_empty())


func test_cycle_suit_l_ordre_des_elements() -> void:
	var detector := StraightDetector.new()
	detector.length = 5
	detector.cycle = load(CYCLE_PATH)
	var cycle := C.hand([[C.BOIS, 3], [C.FEU, 4], [C.TERRE, 5], [C.METAL, 6], [C.EAU, 7]])
	var casse := C.hand([[C.FEU, 3], [C.BOIS, 4], [C.TERRE, 5], [C.METAL, 6], [C.EAU, 7]])
	assert_eq(detector.detect(cycle).size(), 5)
	assert_true(detector.detect(casse).is_empty())


func test_cycle_boucle_eau_vers_bois() -> void:
	var detector := StraightDetector.new()
	detector.length = 5
	detector.cycle = load(CYCLE_PATH)
	var cards := C.hand([[C.METAL, 1], [C.EAU, 2], [C.BOIS, 3], [C.FEU, 4], [C.TERRE, 5]])
	assert_eq(detector.detect(cards).size(), 5)


# --- Elements ---

func test_purete() -> void:
	var detector := ElementDetector.new()
	detector.mode = ElementDetector.Mode.SAME
	detector.count = 5
	var pure := C.hand([[C.EAU, 1], [C.EAU, 3], [C.EAU, 5], [C.EAU, 7], [C.EAU, 9]])
	var mixte := C.hand([[C.EAU, 1], [C.EAU, 3], [C.EAU, 5], [C.EAU, 7], [C.FEU, 9]])
	assert_eq(detector.detect(pure).size(), 5)
	assert_true(detector.detect(mixte).is_empty())


func test_harmonie() -> void:
	var detector := ElementDetector.new()
	detector.mode = ElementDetector.Mode.DISTINCT
	detector.count = 5
	var ok := C.hand([[C.BOIS, 1], [C.FEU, 3], [C.TERRE, 5], [C.METAL, 7], [C.EAU, 9]])
	var ko := C.hand([[C.BOIS, 1], [C.FEU, 3], [C.TERRE, 5], [C.METAL, 7], [C.BOIS, 9]])
	assert_eq(detector.detect(ok).size(), 5)
	assert_true(detector.detect(ko).is_empty())


func test_element_mauvaise_taille_refuse() -> void:
	var detector := ElementDetector.new()
	detector.mode = ElementDetector.Mode.SAME
	detector.count = 5
	var cards := C.hand([[C.EAU, 1], [C.EAU, 3]])
	assert_true(detector.detect(cards).is_empty())