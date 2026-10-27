extends GutTest
## Exemples des mains (Voie de cultivation) : chacun est bien reconnu comme sa propre main.


func test_chaque_exemple_reconnu_comme_sa_main() -> void:
	var hands := HandCatalog.load_definitions()
	var evaluator := HandEvaluator.new(hands)
	var max_cards: int = (load("res://content/rules/regles_base.tres") as RoundRules).max_selected_cards
	for hand: HandDefinition in hands:
		assert_eq(hand.example.size(), max_cards, "exemple de %d cartes : %s" % [max_cards, hand.id])
		var result := evaluator.evaluate(hand.example_cards())
		assert_eq(result.definition.id, hand.id, "exemple de %s" % hand.id)
