extends GutTest


func _artifact(id: String, price: int) -> ArtifactDefinition:
	var artifact := ArtifactDefinition.new()
	artifact.id = StringName(id)
	artifact.price = price
	return artifact


func _catalog(count: int, price: int = 5) -> Array[ArtifactDefinition]:
	var catalog: Array[ArtifactDefinition] = []
	for i: int in count:
		catalog.append(_artifact("a%d" % i, price))
	return catalog


func _rules(offer_count: int = 2, max_artifacts: int = 5) -> ShopRules:
	var rules := ShopRules.new()
	rules.id = &"test"
	rules.offer_count = offer_count
	rules.reroll_base_cost = 5
	rules.reroll_cost_step = 1
	rules.max_artifacts = max_artifacts
	return rules


## Seules les pierres et les artefacts de la run servent a la boutique.
func _run(stones: int) -> RunState:
	var economy := EconomyRules.new()
	economy.starting_stones = stones
	return RunState.new(null, null, null, null, economy)


func _rng(seed_value: int = 1) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _ids(artifacts: Array[ArtifactDefinition]) -> Array:
	var ids: Array = []
	for artifact: ArtifactDefinition in artifacts:
		ids.append(artifact.id)
	return ids


func test_offres_distinctes_au_bon_nombre() -> void:
	var shop := ShopState.new(_run(10), _catalog(5), _rules(), _rng())
	assert_eq(shop.offers.size(), 2)
	assert_ne(shop.offers[0].id, shop.offers[1].id)


func test_jamais_un_artefact_deja_possede() -> void:
	var catalog := _catalog(3)
	var run := _run(10)
	run.artifacts.append(catalog[0])
	var shop := ShopState.new(run, catalog, _rules(5), _rng())
	assert_eq(shop.offers.size(), 2)
	assert_false(_ids(shop.offers).has(catalog[0].id))


func test_achat_debite_ajoute_et_retire_l_offre() -> void:
	var run := _run(10)
	var shop := ShopState.new(run, _catalog(5, 6), _rules(), _rng())
	var bought: ArtifactDefinition = shop.offers[0]
	assert_true(shop.buy(0))
	assert_eq(run.stones, 4)
	assert_true(run.artifacts.has(bought))
	assert_eq(shop.offers.size(), 1)


func test_achat_refuse_sans_assez_de_pierres() -> void:
	var run := _run(3)
	var shop := ShopState.new(run, _catalog(5, 6), _rules(), _rng())
	assert_false(shop.buy(0))
	assert_eq(run.stones, 3)
	assert_eq(run.artifacts.size(), 0)
	assert_eq(shop.offers.size(), 2)


func test_achat_refuse_au_maximum_d_artefacts() -> void:
	var run := _run(100)
	run.artifacts.append(_artifact("deja", 1))
	var shop := ShopState.new(run, _catalog(5), _rules(2, 1), _rng())
	assert_false(shop.buy(0))
	assert_eq(run.stones, 100)


func test_achat_index_invalide() -> void:
	var shop := ShopState.new(_run(100), _catalog(5), _rules(), _rng())
	assert_false(shop.buy(-1))
	assert_false(shop.buy(2))


func test_relance_debite_et_augmente_le_cout() -> void:
	var run := _run(20)
	var shop := ShopState.new(run, _catalog(5), _rules(), _rng())
	assert_true(shop.reroll())
	assert_eq(run.stones, 15)
	assert_eq(shop.reroll_cost, 6)
	assert_eq(shop.offers.size(), 2)


func test_relance_refusee_sans_assez_de_pierres() -> void:
	var run := _run(4)
	var shop := ShopState.new(run, _catalog(5), _rules(), _rng())
	assert_false(shop.reroll())
	assert_eq(run.stones, 4)
	assert_eq(shop.reroll_cost, 5)


func test_meme_seed_memes_offres() -> void:
	var catalog := _catalog(10)
	var a := ShopState.new(_run(10), catalog, _rules(), _rng(42))
	var b := ShopState.new(_run(10), catalog, _rules(), _rng(42))
	assert_eq(_ids(a.offers), _ids(b.offers))