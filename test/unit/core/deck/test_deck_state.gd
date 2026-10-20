extends GutTest

const STARTER_DECK_PATH := "res://content/decks/paquet_depart.tres"
const HAND_SIZE := 8

var _definition: DeckDefinition


func before_each() -> void:
	_definition = load(STARTER_DECK_PATH)


func _make_deck(seed_value: int) -> DeckState:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return DeckState.new(_definition, rng)


func _ids(cards: Array[CardInstance]) -> Array:
	var ids: Array = []
	for card: CardInstance in cards:
		ids.append(card.data.id)
	return ids


func test_nouveau_paquet_tout_dans_la_pioche() -> void:
	var deck := _make_deck(1)
	assert_eq(deck.draw_pile.size(), _definition.cards.size())
	assert_eq(deck.hand.size(), 0)
	assert_eq(deck.discard_pile.size(), 0)


func test_uids_uniques() -> void:
	var deck := _make_deck(1)
	var uids: Dictionary = {}
	for card: CardInstance in deck.draw_pile:
		uids[card.uid] = true
	assert_eq(uids.size(), deck.draw_pile.size())


func test_meme_seed_meme_pioche() -> void:
	assert_eq(_ids(_make_deck(42).draw_pile), _ids(_make_deck(42).draw_pile))


func test_seeds_differentes_pioches_differentes() -> void:
	assert_ne(_ids(_make_deck(1).draw_pile), _ids(_make_deck(2).draw_pile))


func test_fill_hand_pioche_jusqu_a_la_taille() -> void:
	var deck := _make_deck(1)
	var drawn := deck.fill_hand(HAND_SIZE)
	assert_eq(drawn.size(), HAND_SIZE)
	assert_eq(deck.hand.size(), HAND_SIZE)
	assert_eq(deck.total_count(), _definition.cards.size())


func test_fill_hand_main_pleine_ne_pioche_rien() -> void:
	var deck := _make_deck(1)
	deck.fill_hand(HAND_SIZE)
	assert_eq(deck.fill_hand(HAND_SIZE).size(), 0)


func test_fill_hand_pioche_vide_prend_le_reste() -> void:
	var deck := _make_deck(1)
	deck.fill_hand(_definition.cards.size() + 10)
	assert_eq(deck.hand.size(), _definition.cards.size())
	assert_true(deck.draw_pile.is_empty())


func test_discard_deplace_vers_defausse() -> void:
	var deck := _make_deck(1)
	deck.fill_hand(HAND_SIZE)
	var to_discard: Array[CardInstance] = [deck.hand[0], deck.hand[1], deck.hand[2]]
	assert_true(deck.discard(to_discard))
	assert_eq(deck.hand.size(), HAND_SIZE - 3)
	assert_eq(deck.discard_pile.size(), 3)
	assert_eq(deck.total_count(), _definition.cards.size())


func test_discard_puis_fill_hand_complete_la_main() -> void:
	var deck := _make_deck(1)
	deck.fill_hand(HAND_SIZE)
	var to_discard: Array[CardInstance] = [deck.hand[0], deck.hand[1]]
	deck.discard(to_discard)
	deck.fill_hand(HAND_SIZE)
	assert_eq(deck.hand.size(), HAND_SIZE)
	assert_eq(deck.total_count(), _definition.cards.size())


func test_discard_refuse_carte_hors_main() -> void:
	var deck := _make_deck(1)
	deck.fill_hand(HAND_SIZE)
	var to_discard: Array[CardInstance] = [deck.hand[0], deck.draw_pile[0]]
	assert_false(deck.discard(to_discard))
	assert_eq(deck.hand.size(), HAND_SIZE)
	assert_eq(deck.discard_pile.size(), 0)


func test_discard_refuse_doublon() -> void:
	var deck := _make_deck(1)
	deck.fill_hand(HAND_SIZE)
	var to_discard: Array[CardInstance] = [deck.hand[0], deck.hand[0]]
	assert_false(deck.discard(to_discard))
	assert_eq(deck.discard_pile.size(), 0)


func test_discard_vide_refuse() -> void:
	var deck := _make_deck(1)
	var to_discard: Array[CardInstance] = []
	assert_false(deck.discard(to_discard))


func test_reset_remet_tout_dans_la_pioche() -> void:
	var deck := _make_deck(1)
	deck.fill_hand(HAND_SIZE)
	var to_discard: Array[CardInstance] = [deck.hand[0]]
	deck.discard(to_discard)
	deck.reset()
	assert_eq(deck.draw_pile.size(), _definition.cards.size())
	assert_true(deck.hand.is_empty())
	assert_true(deck.discard_pile.is_empty())


func test_signaux_emis() -> void:
	var deck := _make_deck(1)
	watch_signals(deck)
	deck.fill_hand(HAND_SIZE)
	assert_signal_emitted(deck, "cards_drawn")
	var to_discard: Array[CardInstance] = [deck.hand[0]]
	deck.discard(to_discard)
	assert_signal_emitted(deck, "cards_discarded")