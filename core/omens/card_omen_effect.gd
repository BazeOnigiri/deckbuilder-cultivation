class_name CardOmenEffect
extends OmenEffect
## Copie d'une carte du paquet tiree au hasard, avec une amelioration tiree au hasard, ajoutee au paquet.


func apply_now(run: RunState, rng: RandomNumberGenerator) -> void:
	var cards := run.cards()
	if cards.is_empty():
		return
	var model: CardInstance = cards[rng.randi_range(0, cards.size() - 1)]
	var card := run.add_card(model.data, model.ranks)
	if run.card_modifiers != null:
		run.card_modifiers.roll_onto(card, rng, 1.0, 0.0, 0.0)
