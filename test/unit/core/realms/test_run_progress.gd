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
