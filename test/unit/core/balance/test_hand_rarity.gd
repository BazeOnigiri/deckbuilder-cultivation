extends GutTest
## Rarete exacte : toutes les combinaisons du paquet sont comptees.


## Paquet de 2 rangs x 5 elements : 45 tirages de 2 cartes, dont 2 x C(5, 2) = 20 paires.
func test_rarete_exacte_sur_un_petit_paquet() -> void:
	var deck := DeckDefinition.new()
	for element: int in Element.Type.values():
		for rank: int in [1, 2]:
			deck.cards.append(CardData.create(StringName("c%d_%d" % [element, rank]), element as Element.Type, rank))
	var pair := HandDefinition.new()
	pair.id = "paire"
	var detector := RankGroupDetector.new()
	detector.group_sizes = [2]
	pair.detector = detector
	var high := HandDefinition.new()
	high.id = "souffle"
	high.detector = HighCardDetector.new()
	var hands: Array[HandDefinition] = [pair, high]
	var rarities := HandRarity.exact(deck, hands, 2)
	assert_almost_eq(rarities["paire"], 20.0 / 45.0, 1e-9)
	assert_almost_eq(rarities["souffle"], 1.0, 1e-9)
