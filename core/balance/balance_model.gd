class_name BalanceModel
extends RefCounted
## Formules de l'equilibrage, pures et testees. Explications et exemples : docs/equilibrage.md.
## Unite commune (courbe de cout) : le gain relatif de score, 0.1 = +10 % de score moyen.


## Valeur d'une pierre k : le gain de score qu'achete une pierre, ancre sur le prix voulu d'un artefact typique.
## Artefact typique = gain median : un artefact trop fort (ou trop faible) ne fausse pas le prix de tous les autres.
static func stone_value(rules: BalanceRules, artifact_gains: Array[float]) -> float:
	if artifact_gains.is_empty():
		return 0.0
	var sorted := artifact_gains.duplicate()
	sorted.sort()
	var middle := sorted.size() / 2
	var median: float = sorted[middle] if sorted.size() % 2 == 1 else (sorted[middle - 1] + sorted[middle]) / 2.0
	return median / rules.mean_artifact_price


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
	var power := 1.0
	for bottleneck_reward: int in rewards:
		power *= 1.0 + stone * stones_earned(rules, economy, bottleneck_reward)
	return rules.pressure * power


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
	var artifact_gains: Array[float] = []
	for artifact: ArtifactDefinition in artifacts:
		artifact_gains.append(measures.gains.get(artifact.id, 0.0))
	var stone := stone_value(rules, artifact_gains)
	var prices := {}
	for artifact: ArtifactDefinition in artifacts:
		prices[artifact.id] = price(rules, measures.gains.get(artifact.id, 0.0), stone)
	for manual: ManualDefinition in manuals:
		prices[manual.id] = price(rules, measures.gains.get(manual.id, 0.0), stone)
	var bottlenecks: Array = []
	var bases: Array[int] = []
	var growths: Array[float] = []
	for realm: RealmDefinition in realms:
		var row: Array = []
		var rewards: Array[int] = []
		for index: int in realm.bottlenecks.size():
			var multiplier := bottleneck_multiplier(rules, index)
			rewards.append(reward(rules, multiplier))
			row.append([multiplier, rewards[-1]])
		bottlenecks.append(row)
		bases.append(realm_base_score(rules, measures, growths))
		growths.append(realm_growth(rules, economy, stone, rewards))
	return {"stone": stone, "prices": prices, "bottlenecks": bottlenecks, "realms": bases, "growths": growths}


## Garde digits chiffres significatifs : 1117 -> 1100 (2 chiffres), 428 -> 430.
static func round_to_digits(value: float, digits: int) -> float:
	if value <= 0.0:
		return 0.0
	var scale := pow(10.0, floorf(log(value) / log(10.0)) - digits + 1)
	return roundf(value / scale) * scale
