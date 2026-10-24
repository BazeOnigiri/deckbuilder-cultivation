extends GutTest


func test_compte_et_total() -> void:
	var tally := HandTally.new()
	tally.record("main_paire")
	tally.record("main_paire")
	tally.record("main_brelan")
	assert_eq(tally.count_of("main_paire"), 2)
	assert_eq(tally.count_of("main_full"), 0)
	assert_eq(tally.total(), 3)


func test_main_favorite_egalite_stable() -> void:
	var tally := HandTally.new()
	assert_eq(tally.most_played(), "")
	tally.counts = {"main_paire": 5, "main_brelan": 5, "main_full": 2}
	assert_eq(tally.most_played(), "main_brelan")


func test_lecture_ignore_les_valeurs_invalides() -> void:
	var tally := HandTally.from_dict({"main_paire": 4.0, "main_brelan": "x", "main_full": - 2})
	assert_eq(tally.counts, {"main_paire": 4})
	assert_eq(HandTally.from_dict("pas un dictionnaire").total(), 0)