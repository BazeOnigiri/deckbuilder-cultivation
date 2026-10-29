extends GutTest


func _bottleneck(multiplier: float) -> BottleneckDefinition:
	var bottleneck := BottleneckDefinition.new()
	bottleneck.id = &"test"
	bottleneck.name_key = "TEST"
	bottleneck.score_multiplier = multiplier
	return bottleneck


func _realm(order: int, base_score: int, multipliers: Array) -> RealmDefinition:
	var realm := RealmDefinition.new()
	realm.id = StringName("royaume_%d" % order)
	realm.name_key = "TEST"
	realm.order = order
	realm.base_score = base_score
	for multiplier: float in multipliers:
		realm.bottlenecks.append(_bottleneck(multiplier))
	return realm


func _progress(realms: Array) -> RunProgress:
	var typed: Array[RealmDefinition] = []
	typed.assign(realms)
	return RunProgress.new(typed)


func test_objectif_vaut_base_fois_multiplicateur() -> void:
	var progress := _progress([_realm(1, 200, [1.0, 1.5, 2.0])])
	assert_eq(progress.current_target(), 200)
	progress.advance()
	assert_eq(progress.current_target(), 300)
	progress.advance()
	assert_eq(progress.current_target(), 400)


func test_objectif_arrondi() -> void:
	var progress := _progress([_realm(1, 333, [1.5])])
	assert_eq(progress.current_target(), 500)


func test_passe_au_royaume_suivant() -> void:
	var progress := _progress([_realm(1, 100, [1.0]), _realm(2, 500, [1.0])])
	assert_true(progress.advance())
	assert_eq(progress.current_realm().order, 2)
	assert_eq(progress.current_target(), 500)


func test_royaumes_tries_par_ordre() -> void:
	var progress := _progress([_realm(2, 500, [1.0]), _realm(1, 100, [1.0])])
	assert_eq(progress.current_realm().order, 1)


func test_fin_de_run() -> void:
	var progress := _progress([_realm(1, 100, [1.0]), _realm(2, 500, [1.0, 2.0])])
	assert_true(progress.advance())
	assert_true(progress.advance())
	assert_false(progress.advance())
	assert_true(progress.is_finished)
	assert_false(progress.advance())
	assert_eq(progress.current_target(), 1000)

func test_position_des_goulots_du_royaume_courant() -> void:
	var progress := _progress([_realm(1, 100, [1.0, 1.5, 2.0])])
	progress.advance()
	assert_eq(progress.bottleneck_position(0), -1)
	assert_eq(progress.bottleneck_position(1), 0)
	assert_eq(progress.bottleneck_position(2), 1)


func test_run_terminee_tout_est_franchi() -> void:
	var progress := _progress([_realm(1, 100, [1.0])])
	progress.advance()
	assert_true(progress.is_finished)
	assert_eq(progress.bottleneck_position(0), -1)

func test_restauration_de_la_position() -> void:
	var progress := _progress([_realm(1, 100, [1.0, 2.0]), _realm(2, 500, [1.0])])
	progress.advance()
	progress.advance()
	var restored := _progress([_realm(1, 100, [1.0, 2.0]), _realm(2, 500, [1.0])])
	assert_true(restored.restore(progress.to_dict()))
	assert_eq(restored.current_target(), 500)


func test_restauration_hors_limites_refusee() -> void:
	var progress := _progress([_realm(1, 100, [1.0, 2.0])])
	assert_false(progress.restore({"realm": 0, "bottleneck": 5}))
	assert_false(progress.restore({"realm": - 1, "bottleneck": 0}))
	assert_false(progress.restore("pas un dictionnaire"))
	assert_eq(progress.current_target(), 100)

func test_numeros_du_royaume_et_du_goulot() -> void:
	var progress := _progress([_realm(1, 100, [1.0, 2.0]), _realm(2, 500, [1.0])])
	assert_eq(progress.realm_count(), 2)
	assert_eq(progress.realm_number(), 1)
	assert_eq(progress.bottleneck_number(), 1)
	progress.advance()
	assert_eq(progress.bottleneck_number(), 2)
	progress.advance()
	assert_eq(progress.realm_number(), 2)
	assert_eq(progress.bottleneck_number(), 1)


func _tribulation(id: StringName) -> BottleneckDefinition:
	var tribulation := _bottleneck(2.0)
	tribulation.id = id
	tribulation.constraint = TribulationConstraint.new()
	return tribulation


func _with_tribulations() -> RunProgress:
	var realms: Array = []
	for order: int in range(1, 4):
		var realm := _realm(order, 100 * order, [1.0])
		realm.bottlenecks.append(_tribulation(&"fixe"))
		realms.append(realm)
	return _progress(realms)


func _pool(count: int) -> Array[BottleneckDefinition]:
	var pool: Array[BottleneckDefinition] = []
	for i: int in count:
		pool.append(_tribulation(StringName("trib_%d" % i)))
	return pool


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_tirage_des_tribulations_deterministe_et_sans_doublon() -> void:
	var pool := _pool(3)
	var a := _with_tribulations()
	a.draw_tribulations(pool, _rng(5))
	var b := _with_tribulations()
	b.draw_tribulations(pool, _rng(5))
	assert_eq(a.tribulations(), b.tribulations())
	var ids := {}
	for tribulation: BottleneckDefinition in a.tribulations():
		assert_has(pool, tribulation)
		ids[tribulation.id] = true
	assert_eq(ids.size(), 3)
	assert_eq(a.realms()[0].bottlenecks[0].constraint, null, "le premier goulot ne change pas")


func test_pool_vide_garde_les_tribulations() -> void:
	var progress := _with_tribulations()
	progress.draw_tribulations([], _rng(1))
	assert_eq(progress.tribulations()[0].id, &"fixe")


func test_tirage_restaure_depuis_la_sauvegarde() -> void:
	var pool := _pool(3)
	var progress := _with_tribulations()
	progress.draw_tribulations(pool, _rng(9))
	progress.advance()
	var restored := _with_tribulations()
	assert_true(restored.restore(JSON.parse_string(JSON.stringify(progress.to_dict())), pool))
	assert_eq(restored.tribulations(), progress.tribulations())
	assert_eq(restored.bottleneck_number(), 2)


func test_ancienne_sauvegarde_sans_tirage() -> void:
	var restored := _with_tribulations()
	assert_true(restored.restore({"realm": 1, "bottleneck": 0}, _pool(3)))
	assert_eq(restored.tribulations()[1].id, &"fixe")
	assert_eq(restored.endless_count(), 0)


func test_royaumes_sans_fin_croissants_et_sauvegardes() -> void:
	var pool := _pool(3)
	var progress := _with_tribulations()
	progress.endless_growth = 2.5
	progress.significant_digits = 2
	for i: int in 3:
		progress.advance()
		progress.advance()
	assert_true(progress.is_finished)
	var rng := _rng(2)
	progress.add_endless_realm(pool, rng)
	progress.add_endless_realm(pool, rng)
	assert_false(progress.is_finished)
	assert_eq(progress.endless_count(), 2)
	var realms := progress.realms()
	assert_eq(realms[3].base_score, 750, "300 x 2,5")
	assert_eq(realms[4].base_score, 1900, "750 x 2,5 = 1875, deux chiffres")
	assert_eq(realms[4].number, 2)
	assert_eq(realms[4].name_key, RunProgress.ENDLESS_NAME_KEY)
	assert_eq(progress.current_realm(), realms[4])
	assert_ne(progress.tribulations()[4], progress.tribulations()[3], "pas deux fois la meme de suite")
	var restored := _with_tribulations()
	restored.endless_growth = 2.5
	assert_true(restored.restore(JSON.parse_string(JSON.stringify(progress.to_dict())), pool))
	assert_eq(restored.realm_count(), 5)
	assert_eq(restored.current_realm().base_score, 1900)
	var ids := func(list: Array[BottleneckDefinition]) -> Array: return list.map(func(b: BottleneckDefinition) -> StringName: return b.id)
	assert_eq(ids.call(restored.tribulations()), ids.call(progress.tribulations()))


func test_nom_d_un_royaume_genere() -> void:
	var realm := RunProgress.endless_realm(_realm(1, 100, [1.0]), 4, null, 2.0, 2)
	assert_eq(realm.number, 4)
	assert_eq(realm.id, &"royaume_sans_fin_4")
	assert_string_contains(realm.title(), "4")
