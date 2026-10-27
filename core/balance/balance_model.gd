class_name BalanceModel
extends RefCounted
## Formules de l'equilibrage, pures et testees. Explications et exemples : docs/equilibrage.md.
## Unite commune (courbe de cout) : le gain relatif de score, 0.1 = +10 % de score moyen.


## Valeur d'une pierre k : le gain de score qu'achete une pierre. Ancree sur l'economie, pas sur les objets :
## les pierres d'un royaume (rewards) bien depensees multiplient la puissance par power_per_realm,
## soit produit(1 + k x pierres du goulot) = power_per_realm, resolu par dichotomie (le produit croit avec k).
## Ajouter des objets ne change donc ni k ni la difficulte : seulement leurs propres prix.
static func stone_value(rules: BalanceRules, economy: EconomyRules, rewards: Array[int]) -> float:
	if rewards.is_empty() or rules.power_per_realm <= 1.0:
		return 0.0
	var low := 0.0
	var high := 1.0
	while _power(rules, economy, high, rewards) < rules.power_per_realm:
		high *= 2.0
	for i: int in 60:
		var middle := (low + high) / 2.0
		if _power(rules, economy, middle, rewards) < rules.power_per_realm:
			low = middle
		else:
			high = middle
	return (low + high) / 2.0


## Puissance achetee avec les pierres d'un royaume : produit des (1 + k x pierres gagnees a chaque goulot).
static func _power(rules: BalanceRules, economy: EconomyRules, stone: float, rewards: Array[int]) -> float:
	var power := 1.0
	for bottleneck_reward: int in rewards:
		power *= 1.0 + stone * stones_earned(rules, economy, bottleneck_reward)
	return power


## Prix = gain / k : un objet deux fois plus utile coute deux fois plus cher.
static func price(rules: BalanceRules, gain: float, stone: float) -> int:
	return maxi(rules.min_price, roundi(gain / stone)) if stone > 0.0 else rules.min_price


## Multiplicateur du goulot numero index (0 = premier) d'un royaume : 1, 1 + pas, 1 + 2 x pas...
static func bottleneck_multiplier(rules: BalanceRules, index: int) -> float:
	return 1.0 + rules.bottleneck_step * index


## Pierres de base d'un goulot : une part fixe et une part qui suit sa difficulte.
static func reward(rules: BalanceRules, multiplier: float) -> int:
	return roundi(rules.reward_base + rules.reward_per_difficulty * multiplier)


## Pierres que le joueur de reference gagne en franchissant un goulot : recompense, mains restantes, interets.
static func stones_earned(rules: BalanceRules, economy: EconomyRules, bottleneck_reward: int) -> int:
	@warning_ignore("integer_division")
	var interest := mini(rules.reference_savings / economy.interest_step, economy.interest_cap)
	return bottleneck_reward + rules.reference_hands_left * economy.stones_per_hand_left + interest


## Croissance G d'un royaume au suivant : la puissance que le joueur achete (produit des 1 + k x pierres de
## chaque goulot), fois la pression qui garde la difficulte un pas devant lui.
static func realm_growth(rules: BalanceRules, economy: EconomyRules, stone: float, rewards: Array[int]) -> float:
	return rules.pressure * _power(rules, economy, stone, rewards)


## Score de base d'un royaume : T1 x G1 x G2... (croissances des royaumes d'avant), arrondi pour la lecture.
## Royaumes tous batis pareil : T1 x G^(ordre - 1). T1 : score d'un round atteint par la part
## first_bottleneck_success des joueurs de reference au depart.
static func realm_base_score(rules: BalanceRules, measures: BalanceMeasures, previous_growths: Array[float]) -> int:
	var score := measures.round_score_reached_by(rules.first_bottleneck_success)
	for growth: float in previous_growths:
		score *= growth
	return roundi(round_to_digits(score, rules.significant_digits))


## Toutes les valeurs que l'equilibrage ecrit, pour ces mesures et ce contenu (realms tries par ordre) :
## {"stone": k, "prices": {id: prix}, "bottlenecks": [[multiplicateur, recompense] par goulot de chaque royaume],
## "realms": [score de base par royaume]}. L'outil les ecrit, le test verifie que les .tres n'ont pas derive.
static func solve(rules: BalanceRules, measures: BalanceMeasures, economy: EconomyRules,
		realms: Array[RealmDefinition], artifacts: Array[ArtifactDefinition], manuals: Array[ManualDefinition]) -> Dictionary:
	var bottlenecks: Array = []
	var realm_rewards: Array = []
	for realm: RealmDefinition in realms:
		var row: Array = []
		var rewards: Array[int] = []
		for index: int in realm.bottlenecks.size():
			var multiplier := bottleneck_multiplier(rules, index)
			rewards.append(reward(rules, multiplier))
			row.append([multiplier, rewards[-1]])
		bottlenecks.append(row)
		realm_rewards.append(rewards)
	# La pierre se regle sur le premier royaume, celui ou le joueur commence a acheter.
	var first_rewards: Array[int] = realm_rewards[0] if not realm_rewards.is_empty() else []
	var stone := stone_value(rules, economy, first_rewards)
	var prices := {}
	for artifact: ArtifactDefinition in artifacts:
		prices[artifact.id] = price(rules, measures.gains.get(artifact.id, 0.0), stone)
	for manual: ManualDefinition in manuals:
		prices[manual.id] = price(rules, measures.gains.get(manual.id, 0.0), stone)
	var bases: Array[int] = []
	var growths: Array[float] = []
	for rewards: Array[int] in realm_rewards:
		bases.append(realm_base_score(rules, measures, growths))
		growths.append(realm_growth(rules, economy, stone, rewards))
	return {"stone": stone, "prices": prices, "bottlenecks": bottlenecks, "realms": bases, "growths": growths}


## Garde digits chiffres significatifs : 1117 -> 1100 (2 chiffres), 428 -> 430.
static func round_to_digits(value: float, digits: int) -> float:
	if value <= 0.0:
		return 0.0
	var scale := pow(10.0, floorf(log(value) / log(10.0)) - digits + 1)
	return roundf(value / scale) * scale
