extends GutTest


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_meme_seed_donne_meme_ordre() -> void:
	var a: Array = range(20)
	var b: Array = range(20)
	RngUtils.shuffle(a, _rng(42))
	RngUtils.shuffle(b, _rng(42))
	assert_eq(a, b)


func test_seeds_differentes_donnent_ordres_differents() -> void:
	var a: Array = range(20)
	var b: Array = range(20)
	RngUtils.shuffle(a, _rng(1))
	RngUtils.shuffle(b, _rng(2))
	assert_ne(a, b)


func test_melange_modifie_ordre() -> void:
	var a: Array = range(20)
	RngUtils.shuffle(a, _rng(42))
	assert_ne(a, range(20))


func test_melange_conserve_les_elements() -> void:
	var a: Array = range(20)
	RngUtils.shuffle(a, _rng(42))
	a.sort()
	assert_eq(a, range(20))


func test_tableaux_vide_et_singleton_ne_plantent_pas() -> void:
	var vide: Array = []
	var un: Array = [7]
	RngUtils.shuffle(vide, _rng(42))
	RngUtils.shuffle(un, _rng(42))
	assert_eq(vide, [])
	assert_eq(un, [7])