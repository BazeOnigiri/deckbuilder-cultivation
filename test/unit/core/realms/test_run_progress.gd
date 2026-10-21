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