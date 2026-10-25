extends GutTest


func test_economie_de_base_valide() -> void:
	var rules: EconomyRules = load("res://content/rules/economie_base.tres")
	assert_not_null(rules)
	assert_true(rules.is_valid())