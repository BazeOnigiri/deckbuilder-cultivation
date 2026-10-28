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
	var ranks := RankRules.new()
	ranks.max_rank = 9
	var cards := C.hand([[C.BOIS, 3], [C.EAU, 9]])
	for card: CardInstance in cards:
		card.ranks = ranks
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

func test_retirer_du_rang_s_arrete_a_1() -> void:
	var cards := C.hand([[C.BOIS, 1], [C.EAU, 5]])
	var effect := AddRankPillEffect.new()
	effect.amount = -1
	effect.apply(cards, null)
	assert_eq(cards[0].rank, 1)
	assert_eq(cards[1].rank, 4)


func test_roue_suit_le_cycle_d_engendrement() -> void:
	var cards := C.hand([[C.BOIS, 3], [C.EAU, 5]])
	var effect := CycleElementPillEffect.new()
	effect.cycle = load("res://content/cycles/cycle_engendrement.tres")
	effect.apply(cards, null)
	assert_eq(cards[0].element, Element.Type.FEU)
	assert_eq(cards[1].element, Element.Type.BOIS)


func test_fusion_garde_la_plus_haute_et_detruit_l_autre() -> void:
	var deck := _deck_with_hand()
	var ranks := RankRules.new()
	ranks.max_rank = 7
	for card: CardInstance in deck.hand:
		card.ranks = ranks
	var low: CardInstance = deck.hand.filter(func(card: CardInstance) -> bool: return card.rank == 2)[0]
	var high: CardInstance = deck.hand.filter(func(card: CardInstance) -> bool: return card.rank == 4)[0]
	var target: Array[CardInstance] = [low, high]
	FusePillEffect.new().apply(target, deck)
	assert_eq(high.rank, 6)
	assert_false(deck.hand.has(low))
	assert_eq(deck.total_count(), 4)


func test_fusion_plafonnee_au_rang_max() -> void:
	var deck := _deck_with_hand()
	var ranks := RankRules.new()
	ranks.max_rank = 7
	for card: CardInstance in deck.hand:
		card.ranks = ranks
	var target: Array[CardInstance] = []
	target.assign(deck.hand.filter(func(card: CardInstance) -> bool: return card.rank >= 4))
	FusePillEffect.new().apply(target, deck)
	assert_eq(target.filter(func(card: CardInstance) -> bool: return card.rank == 7).size(), 1)
