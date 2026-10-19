extends GutTest
## Tests de DeckDefinition.is_valid sur des paquets construits dans le test.


func test_deck_vide_est_invalide() -> void:
	assert_false(DeckDefinition.new().is_valid())


func test_deck_avec_carte_nulle_est_invalide() -> void:
	var deck: DeckDefinition = _creer_deck([_carte(&"a"), null])
	assert_false(deck.is_valid())


func test_deck_avec_carte_sans_id_est_invalide() -> void:
	var deck: DeckDefinition = _creer_deck([_carte(&"a"), _carte(&"")])
	assert_false(deck.is_valid())


func test_deck_avec_ids_en_double_est_invalide() -> void:
	var deck: DeckDefinition = _creer_deck([_carte(&"a"), _carte(&"a", Element.Type.FEU, 2)])
	assert_false(deck.is_valid())


func test_deck_de_deux_cartes_distinctes_est_valide() -> void:
	var deck: DeckDefinition = _creer_deck([_carte(&"a"), _carte(&"b", Element.Type.FEU, 2)])
	assert_true(deck.is_valid())


func test_create_remplit_tous_les_champs() -> void:
	var card: CardData = CardData.create(&"carte_eau_9", Element.Type.EAU, 9)
	assert_eq(card.id, &"carte_eau_9")
	assert_eq(card.element, Element.Type.EAU)
	assert_eq(card.rank, 9)


# --- Utilitaires ---

func _carte(id: StringName, element: Element.Type = Element.Type.BOIS, rank: int = 1) -> CardData:
	return CardData.create(id, element, rank)


func _creer_deck(cartes: Array) -> DeckDefinition:
	var deck: DeckDefinition = DeckDefinition.new()
	deck.cards.assign(cartes)
	return deck