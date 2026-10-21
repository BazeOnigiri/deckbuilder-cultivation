class_name RoundReward
extends RefCounted
## Pierres spirituelles gagnees en franchissant un goulot, detaillees pour l'affichage.

var base: int = 0
var hands: int = 0
var interest: int = 0


func total() -> int:
	return base + hands + interest


## Les interets portent sur les pierres possedees avant la recompense.
static func compute(rules: EconomyRules, bottleneck_reward: int, hands_left: int, stones: int) -> RoundReward:
	var reward := RoundReward.new()
	reward.base = bottleneck_reward
	reward.hands = hands_left * rules.stones_per_hand_left
	@warning_ignore("integer_division")
	reward.interest = mini(stones / rules.interest_step, rules.interest_cap)
	return reward