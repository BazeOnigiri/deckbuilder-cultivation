class_name ImbuePillEffect
extends PillEffect
## Pose une amelioration, une aura et/ou un talisman sur les cartes : remplace celui du meme genre qu'elles avaient.

@export var enhancement: EnhancementDefinition
@export var edition: EditionDefinition
@export var talisman: TalismanDefinition


func apply(cards: Array[CardInstance], _deck: DeckState, _run: RunState = null) -> void:
	for card: CardInstance in cards:
		if enhancement != null:
			card.enhancement = enhancement
		if edition != null:
			card.edition = edition
		if talisman != null:
			card.talisman = talisman
