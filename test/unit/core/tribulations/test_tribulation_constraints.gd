extends GutTest

const C := preload("res://test/helpers/cards.gd")


func test_contrainte_neutre_ne_change_rien() -> void:
	var neutral := TribulationConstraint.new()
	assert_eq(neutral.hands_per_round(4), 4)
	assert_eq(neutral.discards_per_round(3), 3)
	assert_eq(neutral.hand_size(8), 8)
	assert_true(neutral.counts(C.hand([[C.FEU, 5]])[0]))


func test_sceau_d_element() -> void:
	var seal := ElementSealConstraint.new()
	seal.element = Element.Type.FEU
	var cards := C.hand([[C.FEU, 5], [C.EAU, 5]])
	assert_false(seal.counts(cards[0]))
	assert_true(seal.counts(cards[1]))


func test_moins_de_mains_jamais_sous_un() -> void:
	var constraint := ReducedHandsConstraint.new()
	constraint.amount = 1
	assert_eq(constraint.hands_per_round(4), 3)
	constraint.amount = 10
	assert_eq(constraint.hands_per_round(4), 1)


func test_main_reduite_jamais_sous_un() -> void:
	var constraint := ReducedHandSizeConstraint.new()
	constraint.amount = 2
	assert_eq(constraint.hand_size(8), 6)
	constraint.amount = 20
	assert_eq(constraint.hand_size(8), 1)