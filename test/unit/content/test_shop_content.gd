extends GutTest


func test_boutique_de_base_valide() -> void:
	var rules: ShopRules = load("res://content/rules/boutique_base.tres")
	assert_not_null(rules)
	assert_true(rules.is_valid())


## Sinon la boutique afficherait moins d'offres que prevu des la premiere visite.
func test_assez_d_artefacts_pour_remplir_la_boutique() -> void:
	var rules: ShopRules = load("res://content/rules/boutique_base.tres")
	assert_gte(ArtifactCatalog.load_definitions().size(), rules.offer_count)