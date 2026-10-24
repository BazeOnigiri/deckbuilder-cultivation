extends GutTest

const C := preload("res://test/helpers/cards.gd")


func _deck_with_hand() -> DeckState:
	var definition := DeckDefinition.new()
	for rank: int in range(1, 6):
		definition.cards.append(CardData.create(StringName("c%d" % rank), Element.Type.BOIS, rank))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var deck := DeckState.new(definition, rng)
	deck.fill_hand(5)
	return deck


func test_changer_l_element() -> void:
	var cards := C.hand([[C.BOIS, 3], [C.EAU, 5]])
	var effect := SetElementPillEffect.new()
	effect.element = Element.Type.FEU
	effect.apply(cards, null)
	assert_eq(cards[0].element, Element.Type.FEU)
	assert_eq(cards[1].element, Element.Type.FEU)


func test_ajouter_du_rang_plafonne() -> void:
	var cards := C.hand([[C.BOIS, 3], [C.EAU, 9]])
	var effect := AddRankPillEffect.new()
	effect.apply(cards, null)
	assert_eq(cards[0].rank, 4)
	assert_eq(cards[1].rank, 9)


func test_detruire_retire_du_paquet() -> void:
	var deck := _deck_with_hand()
	var target: Array[CardInstance] = [deck.hand[0], deck.hand[1]]
	DestroyPillEffect.new().apply(target, deck)
	assert_eq(deck.total_count(), 3)
	assert_false(deck.hand.has(target[0]))
	deck.reset()
	assert_eq(deck.total_count(), 3)


func test_detruire_refuse_une_carte_hors_main() -> void:
	var deck := _deck_with_hand()
	var outsider: Array[CardInstance] = [CardInstance.new(99, CardData.create(&"x", Element.Type.FEU, 1))]
	assert_false(deck.destroy(outsider))
	assert_eq(deck.total_count(), 5)