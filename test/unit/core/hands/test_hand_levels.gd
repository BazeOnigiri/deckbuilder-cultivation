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