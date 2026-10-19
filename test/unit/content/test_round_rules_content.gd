extends GutTest

const RULES_PATH := "res://content/rules/regles_base.tres"
const STARTER_DECK_PATH := "res://content/decks/paquet_depart.tres"


func test_regles_base_valides() -> void:
	var rules: RoundRules = load(RULES_PATH)
	assert_not_null(rules)
	assert_true(rules.is_valid())


func test_paquet_assez_grand_pour_une_main() -> void:
	var rules: RoundRules = load(RULES_PATH)
	var deck: DeckDefinition = load(STARTER_DECK_PATH)
	assert_gte(deck.cards.size(), rules.hand_size)