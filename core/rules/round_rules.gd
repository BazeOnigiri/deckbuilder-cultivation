class_name RoundRules
extends Resource
## Regles d'un round en donnees. Les valeurs vivent dans content/rules/, jamais dans le code.

@export var id: String = ""
@export var hand_size: int = 0
@export var hands_per_round: int = 0
@export var discards_per_round: int = 0
## Nombre max de cartes jouees ou defaussees d'un coup.
@export var max_selected_cards: int = 0


func is_valid() -> bool:
	return (not id.is_empty() and hand_size > 0 and hands_per_round > 0
		and discards_per_round >= 0 and max_selected_cards > 0 and max_selected_cards <= hand_size)