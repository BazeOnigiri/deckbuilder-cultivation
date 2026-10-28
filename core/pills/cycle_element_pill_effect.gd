class_name CycleElementPillEffect
extends PillEffect
## Chaque carte prend l'element que le sien engendre (cycle d'engendrement : bois > feu > terre > metal > eau).

@export var cycle: ElementCycle


func apply(cards: Array[CardInstance], _deck: DeckState, _run: RunState = null) -> void:
	for card: CardInstance in cards:
		card.element = cycle.next_of(card.element)
