extends GutTest
## Tests de la donnée paquet_depart.tres : vérifie le contenu, pas le code.

const DECK_PATH: String = "res://content/decks/paquet_depart.tres"
const CARDS_DIR: String = "res://content/cards/"
const NOMBRE_CARTES: int = 70
const RANG_MIN: int = 1
const RANG_MAX: int = 14

var _deck: DeckDefinition


func before_each() -> void:
	_deck = ResourceLoader.load(DECK_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as DeckDefinition


func test_paquet_charge_avec_le_bon_id() -> void:
	assert_not_null(_deck, "paquet_depart.tres doit exister et être un DeckDefinition")
	assert_eq(_deck.id, &"paquet_depart")


func test_paquet_est_valide() -> void:
	assert_true(_deck.is_valid())


func test_paquet_contient_70_cartes() -> void:
	assert_eq(_deck.cards.size(), NOMBRE_CARTES)


func test_chaque_element_a_chaque_rang_exactement_une_fois() -> void:
	var attendu: Array[int] = []
	for rank: int in range(RANG_MIN, RANG_MAX + 1):
		attendu.append(rank)

	for value: int in Element.Type.values():
		var rangs: Array[int] = []
		for card: CardData in _deck.cards:
			if card.element == value:
				rangs.append(card.rank)
		rangs.sort()
		assert_eq(rangs, attendu, "rangs de l'élément %s" % Element.to_id(value as Element.Type))


func test_ids_suivent_la_convention() -> void:
	for card: CardData in _deck.cards:
		var attendu: StringName = StringName("carte_%s_%d" % [Element.to_id(card.element), card.rank])
		assert_eq(card.id, attendu)


func test_chaque_carte_a_son_propre_fichier() -> void:
	for card: CardData in _deck.cards:
		# Une sous-ressource intégrée a un chemin du type "paquet.tres::CardData_xxx".
		assert_true(card.resource_path.begins_with(CARDS_DIR) and not card.resource_path.contains("::"),
			"%s doit être un fichier de %s" % [card.id, CARDS_DIR])


## Comme Balatro : chiffres (1 a 10) = leur rang, figures (11 a 13) = 10, Souverain (14) = 11.
func test_qi_des_rangs() -> void:
	assert_not_null(_deck.ranks, "le paquet reference ses rangs")
	assert_true(_deck.ranks.is_valid())
	assert_eq(_deck.ranks.max_rank, RANG_MAX)
	for rank: int in range(1, 11):
		assert_eq(_deck.ranks.qi_of(rank), rank)
	for rank: int in [11, 12, 13]:
		assert_eq(_deck.ranks.qi_of(rank), 10)
	assert_eq(_deck.ranks.qi_of(14), 11)


func test_pilule_de_raffinement_monte_jusqu_au_souverain() -> void:
	var pill: PillDefinition = load("res://content/pills/pilule_raffinement.tres")
	assert_eq(pill.effect.max_rank, RANG_MAX)
