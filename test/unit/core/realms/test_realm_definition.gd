extends GutTest


func _valid_realm() -> RealmDefinition:
	var bottleneck := BottleneckDefinition.new()
	bottleneck.id = &"b"
	bottleneck.name_key = "B"
	bottleneck.score_multiplier = 1.0
	var realm := RealmDefinition.new()
	realm.id = &"r"
	realm.name_key = "R"
	realm.base_score = 100
	realm.bottlenecks.append(bottleneck)
	return realm


func test_royaume_complet_valide() -> void:
	assert_true(_valid_realm().is_valid())


func test_royaume_sans_goulot_invalide() -> void:
	var realm := _valid_realm()
	realm.bottlenecks.clear()
	assert_false(realm.is_valid())


func test_royaume_avec_goulot_invalide_invalide() -> void:
	var realm := _valid_realm()
	realm.bottlenecks[0].score_multiplier = 0.0
	assert_false(realm.is_valid())


func test_royaume_avec_goulot_nul_invalide() -> void:
	var realm := _valid_realm()
	realm.bottlenecks.append(null)
	assert_false(realm.is_valid())