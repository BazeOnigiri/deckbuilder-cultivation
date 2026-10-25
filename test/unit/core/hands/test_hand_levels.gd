extends GutTest


func test_niveau_un_par_defaut() -> void:
	assert_eq(HandLevels.new().level_of("main_paire"), 1)


func test_level_up_augmente_d_un() -> void:
	var levels := HandLevels.new()
	levels.level_up("main_paire")
	levels.level_up("main_paire")
	assert_eq(levels.level_of("main_paire"), 3)


func test_mains_independantes() -> void:
	var levels := HandLevels.new()
	levels.level_up("main_paire")
	assert_eq(levels.level_of("main_brelan"), 1)

func test_valeurs_d_une_main_selon_son_niveau() -> void:
	var hand := HandDefinition.new()
	hand.base_qi = 10
	hand.base_comprehension = 2
	hand.level_qi = 15
	hand.level_comprehension = 1
	assert_eq(hand.qi_at(1), 10)
	assert_eq(hand.qi_at(3), 40)
	assert_eq(hand.comprehension_at(3), 4)

func test_aller_retour_et_valeurs_invalides() -> void:
	var levels := HandLevels.new()
	levels.level_up("main_paire")
	levels.level_up("main_paire")
	var restored := HandLevels.from_dict(levels.to_dict())
	assert_eq(restored.level_of("main_paire"), 3)
	var bad := HandLevels.from_dict({"main_full": "x", "main_brelan": - 4, "main_carre": 2.0})
	assert_eq(bad.level_of("main_full"), 1)
	assert_eq(bad.level_of("main_brelan"), 1)
	assert_eq(bad.level_of("main_carre"), 2)