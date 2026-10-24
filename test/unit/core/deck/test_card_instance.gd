extends GutTest


func _data() -> CardData:
	return CardData.create(&"carte_feu_5", Element.Type.FEU, 5)


func test_copie_element_et_rang_de_la_definition() -> void:
	var card := CardInstance.new(0, _data())
	assert_eq(card.element, Element.Type.FEU)
	assert_eq(card.rank, 5)


## Une pilule modifie la carte en jeu, jamais la definition partagee par toutes les parties.
func test_modifier_l_instance_ne_touche_pas_la_definition() -> void:
	var data := _data()
	var card := CardInstance.new(0, data)
	card.rank = 9
	card.element = Element.Type.EAU
	assert_eq(data.rank, 5)
	assert_eq(data.element, Element.Type.FEU)
	assert_eq(CardInstance.new(1, data).rank, 5)