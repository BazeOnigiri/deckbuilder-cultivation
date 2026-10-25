class_name DeckState
extends RefCounted
## Etat du paquet pendant une partie : pioche, main, defausse. Logique pure, sans scene.

signal cards_drawn(cards: Array[CardInstance])
signal cards_discarded(cards: Array[CardInstance])

var draw_pile: Array[CardInstance] = []
var hand: Array[CardInstance] = []
var discard_pile: Array[CardInstance] = []

var _rng: RandomNumberGenerator


func _init(definition: DeckDefinition, rng: RandomNumberGenerator) -> void:
	_rng = rng
	var next_uid: int = 0
	for card_data: CardData in definition.cards:
		draw_pile.append(CardInstance.new(next_uid, card_data))
		next_uid += 1
	RngUtils.shuffle(draw_pile, _rng)


func total_count() -> int:
	return draw_pile.size() + hand.size() + discard_pile.size()


## Pioche jusqu'a target_size cartes en main.
## Pioche vide : on s'arrete, pas de remelange pendant un round.
func fill_hand(target_size: int) -> Array[CardInstance]:
	var drawn: Array[CardInstance] = []
	while hand.size() < target_size and not draw_pile.is_empty():
		var card: CardInstance = draw_pile.pop_back()
		hand.append(card)
		drawn.append(card)
	if not drawn.is_empty():
		cards_drawn.emit(drawn)
	return drawn


## Vrai si toutes les cartes sont en main, sans doublon, et qu'il y en a au moins une.
func all_in_hand(cards: Array[CardInstance]) -> bool:
	if cards.is_empty():
		return false
	for card: CardInstance in cards:
		if not hand.has(card) or cards.count(card) > 1:
			return false
	return true


## Deplace des cartes de la main vers la defausse. Refuse tout (et ne change rien) si all_in_hand est faux.
func discard(cards: Array[CardInstance]) -> bool:
	if not all_in_hand(cards):
		return false
	for card: CardInstance in cards:
		hand.erase(card)
		discard_pile.append(card)
	cards_discarded.emit(cards)
	return true


## Retire definitivement des cartes de la main : elles quittent le paquet pour le reste de la run.
func destroy(cards: Array[CardInstance]) -> bool:
	if not all_in_hand(cards):
		return false
	for card: CardInstance in cards:
		hand.erase(card)
	return true


## Remet toutes les cartes dans la pioche et remelange (debut de round).
func reset() -> void:
	draw_pile.append_array(hand)
	draw_pile.append_array(discard_pile)
	hand.clear()
	discard_pile.clear()
	RngUtils.shuffle(draw_pile, _rng)

## Toutes les cartes de la run, toutes piles confondues (sauvegarde).
func all_cards() -> Array[CardInstance]:
	var cards: Array[CardInstance] = []
	cards.append_array(draw_pile)
	cards.append_array(hand)
	cards.append_array(discard_pile)
	return cards


## Paquet restaure : tout va dans la pioche, le prochain round remelange de toute facon.
static func from_cards(cards: Array[CardInstance], rng: RandomNumberGenerator) -> DeckState:
	var deck := DeckState.new(DeckDefinition.new(), rng)
	deck.draw_pile = cards.duplicate()
	return deck