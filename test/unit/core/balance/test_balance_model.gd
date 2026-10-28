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


func _hand(id: String, priority: int) -> HandDefinition:
	var hand := HandDefinition.new()
	hand.id = id
	hand.priority = priority
	return hand


func test_surprise_nulle_pour_une_main_toujours_la() -> void:
	assert_almost_eq(BalanceModel.surprise(1.0), 0.0, 1e-9)
	assert_almost_eq(BalanceModel.surprise(0.1) - BalanceModel.surprise(1.0), log(10.0), 1e-9)


func test_force_des_mains_entre_les_bornes() -> void:
	var rules := _rules()
	var max_surprise := BalanceModel.surprise(1e-6)
	assert_almost_eq(BalanceModel.hand_strength(rules, 1.0, max_surprise), rules.weakest_hand_strength, 1e-6)
	assert_almost_eq(BalanceModel.hand_strength(rules, 1e-6, max_surprise), rules.strongest_hand_strength, 1e-3)
	var previous := 0.0
	for rarity: float in [1.0, 0.5, 0.05, 0.003, 1e-4, 1e-6]:
		var strength := BalanceModel.hand_strength(rules, rarity, max_surprise)
		assert_gt(strength, previous, "plus rare, plus forte : %f" % rarity)
		previous = strength


func test_qi_fois_comprehension_proche_de_la_force() -> void:
	var rules := _rules()
	for strength: float in [5.0, 16.0, 140.0, 520.0, 1800.0]:
		var values := BalanceModel.hand_values(rules, strength)
		assert_almost_eq(float(values["qi"] * values["comprehension"]), strength, strength * 0.15)
		assert_gte(values["comprehension"], 1)
		assert_gte(values["level_qi"], 1)
	assert_eq(BalanceModel.hand_values(rules, 5.0), {"qi": 5, "comprehension": 1, "level_qi": 2, "level_comprehension": 0})


func test_priorites_par_rarete_egalite_departagee() -> void:
	var rules := _rules()
	var measures := BalanceMeasures.new()
	measures.hand_rarities = {"commune": 1.0, "rare_a": 0.001, "rare_b": 0.001, "moyenne": 0.1, "impossible": 0.0}
	var hands: Array[HandDefinition] = [_hand("rare_b", 90), _hand("commune", 10), _hand("rare_a", 40),
		_hand("moyenne", 20), _hand("impossible", 5)]
	var values := BalanceModel.solve_hands(rules, measures, hands)
	assert_false(values.has("impossible"), "une main jamais tiree garde ses valeurs")
	assert_eq(values["commune"]["priority"], 10)
	assert_eq(values["moyenne"]["priority"], 20)
	assert_eq(values["rare_a"]["priority"], 30, "a rarete egale, l'ancienne priorite departage")
	assert_eq(values["rare_b"]["priority"], 40)
	assert_eq(values["rare_a"]["qi"], values["rare_b"]["qi"])


func test_empreinte_suit_le_contenu_mesure_pas_les_resultats() -> void:
	var content := GameContent.load_default()
	var rules := _rules()
	var signature := BalanceModel.content_signature(content, rules)
	assert_eq(BalanceModel.content_signature(content, rules), signature, "stable")
	var hand: HandDefinition = content.hands[0]
	var qi := hand.base_qi
	hand.base_qi += 7
	assert_eq(BalanceModel.content_signature(content, rules), signature, "un resultat ecrit par l'outil n'y entre pas")
	hand.base_qi = qi
	var card: CardData = content.starter_deck.cards[0]
	card.rank += 1
	assert_ne(BalanceModel.content_signature(content, rules), signature, "un paquet change rend les mesures perimees")
	card.rank -= 1


## 18 artefacts en 50/30/15/5 % : 9 Mortels, 5 Spirituels, 3 Celestes, 1 Divin ; le plus fort est le plus rare.
func test_raretes_par_gain_mesure() -> void:
	var measures := _measures([1.0])
	var artifacts: Array[ArtifactDefinition] = []
	for i: int in 18:
		var artifact := ArtifactDefinition.new()
		artifact.id = StringName("a%02d" % i)
		artifacts.append(artifact)
		measures.gains[artifact.id] = 0.01 * (18 - i)
	var rarities := BalanceModel.rarities(_rules(), measures, artifacts)
	var counts := [0, 0, 0, 0]
	for tier: int in rarities.values():
		counts[tier] += 1
	assert_eq(counts, [9, 5, 3, 1])
	assert_eq(rarities[&"a00"], 3, "gain le plus fort : Divin")
	assert_eq(rarities[&"a17"], 0, "gain le plus faible : Mortel")
