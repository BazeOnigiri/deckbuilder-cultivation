class_name PillDefinition
extends Resource
## Une pilule : consommable utilise pendant un round sur les cartes selectionnees.

@export var id: StringName = &""
@export var name_key: String = ""
@export var description_key: String = ""
@export var price: int = 0
@export var min_cards: int = 1
@export var max_cards: int = 1
@export var effect: PillEffect


func is_valid() -> bool:
	return (not id.is_empty() and not name_key.is_empty() and not description_key.is_empty()
		and price > 0 and min_cards > 0 and max_cards >= min_cards and effect != null)