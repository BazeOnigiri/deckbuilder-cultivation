extends GutTest
## La main garde ses vues d'une action a l'autre et place les cartes ; reduce_motion les pose sans animation.

const Cards := preload("res://test/helpers/cards.gd")
const WIDTH := 1000.0


func _hand(reduce_motion: bool) -> HandView:
	var hand := HandView.new()
	hand.settings = GameSettings.new()
	hand.settings.reduce_motion = reduce_motion
	add_child_autofree(hand)
	hand.size = Vector2(WIDTH, hand.custom_minimum_size.y)
	return hand


func _centers(hand: HandView) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for view: CardView in hand.get_children():
		result.append(view.position + CardView.CARD_SIZE / 2)
	return result


func test_vues_gardees_retirees_et_ordonnees() -> void:
	var hand := _hand(false)
	var cards := Cards.hand([[Cards.FEU, 1], [Cards.EAU, 2], [Cards.BOIS, 3]])
	hand.set_cards(cards)
	var kept: CardView = hand.get_child(2)
	hand.set_cards([cards[2], cards[0]] as Array[CardInstance])
	assert_eq(hand.get_child_count(), 2)
	assert_same(hand.get_child(0), kept, "meme vue, deplacee en tete")
	assert_eq((hand.get_child(1) as CardView).card, cards[0])


func test_cartes_gardees_deselectionnees() -> void:
	var hand := _hand(false)
	var cards := Cards.hand([[Cards.FEU, 1], [Cards.EAU, 2]])
	hand.set_cards(cards)
	(hand.get_child(0) as CardView).button_pressed = true
	hand.set_cards(cards)
	assert_false((hand.get_child(0) as CardView).button_pressed)


func test_reduire_les_animations_pose_les_cartes_a_leur_place() -> void:
	var hand := _hand(true)
	hand.set_cards(Cards.hand([[Cards.FEU, 1], [Cards.EAU, 2], [Cards.BOIS, 3]]))
	hand._process(1.0 / 60.0)
	var centers := _centers(hand)
	var slots := HandLayout.slots(3, WIDTH, CardView.CARD_SIZE.x, hand.feel)
	for i: int in 3:
		assert_almost_eq(centers[i].x, WIDTH / 2 + slots[i].x, 0.01, "carte %d" % i)
	assert_almost_eq(centers[0].x + centers[2].x, WIDTH, 0.01, "eventail centre")


func test_carte_selectionnee_monte() -> void:
	var hand := _hand(true)
	hand.set_cards(Cards.hand([[Cards.FEU, 1], [Cards.EAU, 2], [Cards.BOIS, 3]]))
	(hand.get_child(1) as CardView).button_pressed = true
	hand._process(1.0 / 60.0)
	var lift: float = hand.get_theme_constant(&"lift", &"CardButton")
	var slots := HandLayout.slots(3, WIDTH, CardView.CARD_SIZE.x, hand.feel)
	var resting: float = hand.size.y - CardView.CARD_SIZE.y / 2 - hand.feel.arc_height + slots[1].y
	assert_almost_eq(_centers(hand)[1].y, resting - lift, 0.01)


func test_carte_piochee_arrive_de_loin() -> void:
	var hand := _hand(false)
	hand.set_cards(Cards.hand([[Cards.FEU, 1]]))
	hand._process(1.0 / 60.0)
	assert_gt(_centers(hand)[0].x, WIDTH / 2 + 100.0, "encore en chemin depuis la pioche")
