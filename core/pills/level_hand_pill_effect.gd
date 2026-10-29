class_name LevelHandPillEffect
extends PillEffect
## La main que forment les cartes choisies monte de amount niveaux (comme un manuel de technique).

@export var amount: int = 1


func apply(cards: Array[CardInstance], _deck: DeckState, run: RunState = null) -> void:
	var hand := run.evaluate(cards)
	if hand == null:
		return
	for i: int in amount:
		run.hand_levels.level_up(hand.definition.id)
