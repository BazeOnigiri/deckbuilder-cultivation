class_name InterestOmenEffect
extends OmenEffect
## Les interets de la recompense du prochain goulot franchi sont multiplies par factor.

@export var factor: int = 2


func timing() -> Timing:
	return Timing.NEXT_REWARD


func apply_to_reward(reward: RoundReward) -> void:
	reward.interest *= factor
