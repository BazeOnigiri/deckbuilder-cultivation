extends GutTest


func _rules() -> EconomyRules:
	var rules := EconomyRules.new()
	rules.id = &"test"
	rules.stones_per_hand_left = 1
	rules.interest_step = 5
	rules.interest_cap = 5
	return rules


func test_total_additionne_les_trois_parts() -> void:
	var reward := RoundReward.compute(_rules(), 3, 2, 10)
	assert_eq(reward.base, 3)
	assert_eq(reward.hands, 2)
	assert_eq(reward.interest, 2)
	assert_eq(reward.total(), 7)


func test_interets_arrondis_vers_le_bas() -> void:
	assert_eq(RoundReward.compute(_rules(), 0, 0, 9).interest, 1)
	assert_eq(RoundReward.compute(_rules(), 0, 0, 4).interest, 0)


func test_interets_plafonnes() -> void:
	assert_eq(RoundReward.compute(_rules(), 0, 0, 100).interest, 5)


func test_aucune_main_restante() -> void:
	assert_eq(RoundReward.compute(_rules(), 3, 0, 0).total(), 3)