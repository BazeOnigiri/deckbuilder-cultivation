extends GutTest
## Formules de l'equilibrage : valeurs connues et sens de variation (docs/equilibrage.md).


func _rules() -> BalanceRules:
	var rules := BalanceRules.new()
	rules.id = &"test"
	return rules


func _economy() -> EconomyRules:
	var economy := EconomyRules.new()
	economy.id = &"test"
	economy.stones_per_hand_left = 1
	economy.interest_step = 5
	economy.interest_cap = 5
	return economy


func _measures(scores: Array) -> BalanceMeasures:
	var measures := BalanceMeasures.new()
	measures.round_scores = PackedFloat32Array(scores)
	return measures


func test_arrondi_a_deux_chiffres() -> void:
	assert_eq(BalanceModel.round_to_digits(1117.0, 2), 1100.0)
	assert_eq(BalanceModel.round_to_digits(428.0, 2), 430.0)
	assert_almost_eq(BalanceModel.round_to_digits(7.44, 2), 7.4, 0.0001)
	assert_eq(BalanceModel.round_to_digits(0.0, 2), 0.0)


func test_goulots_comme_balatro() -> void:
	var rules := _rules()
	assert_eq(BalanceModel.bottleneck_multiplier(rules, 0), 1.0)
	assert_eq(BalanceModel.bottleneck_multiplier(rules, 1), 1.5)
	assert_eq(BalanceModel.bottleneck_multiplier(rules, 2), 2.0)


func test_recompense_suit_la_difficulte() -> void:
	var rules := _rules()
	assert_eq([BalanceModel.reward(rules, 1.0), BalanceModel.reward(rules, 1.5), BalanceModel.reward(rules, 2.0)], [3, 4, 5])


## Courbe de cout : prix proportionnel au gain, jamais sous le prix minimum.
func test_prix_proportionnel_au_gain() -> void:
	var rules := _rules()
	assert_eq(BalanceModel.price(rules, 0.2, 0.05), 4)
	assert_eq(BalanceModel.price(rules, 0.4, 0.05), 8, "deux fois plus utile, deux fois plus cher")
	assert_eq(BalanceModel.price(rules, 0.0, 0.05), rules.min_price)
	assert_eq(BalanceModel.price(rules, 0.2, 0.0), rules.min_price, "pas de division par zero")


## La pierre se deduit de l'economie : les pierres d'un royaume, bien depensees, donnent power_per_realm.
func test_valeur_de_la_pierre_par_l_economie() -> void:
	var rules := _rules()
	rules.power_per_realm = 2.0
	var rewards: Array[int] = [3, 4, 5]
	var stone := BalanceModel.stone_value(rules, _economy(), rewards)
	var power := 1.0
	for earned: int in [6, 7, 8]:
		power *= 1.0 + stone * earned
	assert_almost_eq(power, 2.0, 0.0001, "le joueur double sa puissance sur un royaume")
	rules.power_per_realm = 3.0
	assert_gt(BalanceModel.stone_value(rules, _economy(), rewards), stone, "plus de puissance par royaume : pierre plus precieuse")
	assert_eq(BalanceModel.stone_value(rules, _economy(), []), 0.0)


## Ajouter des objets ne change ni la valeur de la pierre ni les objectifs : seulement leurs propres prix.
func test_le_contenu_ne_change_pas_la_difficulte() -> void:
	var realm := RealmDefinition.new()
	realm.order = 1
	for i: int in 3:
		realm.bottlenecks.append(BottleneckDefinition.new())
	var realms: Array[RealmDefinition] = [realm, realm]
	var measures := _measures(range(400, 1400))
	var weak := ArtifactDefinition.new()
	weak.id = &"faible"
	measures.gains[&"faible"] = 0.01
	var no_artifacts: Array[ArtifactDefinition] = []
	var with_weak: Array[ArtifactDefinition] = [weak]
	var before := BalanceModel.solve(_rules(), measures, _economy(), realms, no_artifacts, [])
	var after := BalanceModel.solve(_rules(), measures, _economy(), realms, with_weak, [])
	assert_eq(after["stone"], before["stone"])
	assert_eq(after["realms"], before["realms"])


func test_pierres_gagnees_par_goulot() -> void:
	var rules := _rules()
	rules.reference_hands_left = 1
	rules.reference_savings = 10
	assert_eq(BalanceModel.stones_earned(rules, _economy(), 3), 3 + 1 + 2, "recompense + 1 main + interets de 10 pierres")


## Plus le joueur gagne, plus il devient fort, plus le royaume suivant doit monter ; la pression le garde devant.
func test_croissance_par_royaume() -> void:
	var rules := _rules()
	var low := BalanceModel.realm_growth(rules, _economy(), 0.05, [3, 4, 5])
	var high := BalanceModel.realm_growth(rules, _economy(), 0.05, [6, 8, 10])
	assert_gt(low, rules.pressure)
	assert_gt(high, low)
	assert_almost_eq(low, 1.25 * 1.3 * 1.35 * 1.4, 0.0001)


func test_score_de_base_du_royaume() -> void:
	var rules := _rules()
	var measures := _measures(range(1, 101))
	assert_eq(BalanceModel.realm_base_score(rules, measures, []), 11, "90 % des joueurs depassent le 11e score sur 100")
	var growths: Array[float] = [3.0, 2.0]
	assert_eq(BalanceModel.realm_base_score(rules, measures, growths), 66)


## Un royaume ajoute apres la v1 n'a besoin que de son ordre : les formules le prolongent.
func test_royaumes_de_plus_en_plus_durs() -> void:
	var realms: Array[RealmDefinition] = []
	for order: int in [1, 2, 3, 4]:
		var realm := RealmDefinition.new()
		realm.order = order
		for i: int in 3:
			realm.bottlenecks.append(BottleneckDefinition.new())
		realms.append(realm)
	var solved := BalanceModel.solve(_rules(), _measures(range(400, 1400)), _economy(), realms, [], [])
	for r: int in range(1, realms.size()):
		assert_gt(solved["realms"][r], solved["realms"][r - 1], "royaume %d plus dur que le precedent" % (r + 1))
	assert_eq(solved["bottlenecks"][3][2], [2.0, 5], "un 4e royaume suit les memes formules")
