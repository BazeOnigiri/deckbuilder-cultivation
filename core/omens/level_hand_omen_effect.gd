class_name LevelHandOmenEffect
extends OmenEffect
## La main la plus jouee de la run monte de amount niveaux ; fallback_hand si aucune main n'a encore ete jouee.

@export var amount: int = 1
@export var fallback_hand: StringName = &""


func apply_now(run: RunState, _rng: RandomNumberGenerator) -> void:
	var hand_id := run.stats.hands.most_played()
	if hand_id.is_empty():
		hand_id = String(fallback_hand)
	for i: int in amount:
		run.hand_levels.level_up(hand_id)
