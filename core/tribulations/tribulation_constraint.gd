class_name TribulationConstraint
extends Resource
## Contrainte d'une tribulation. La classe de base ne contraint rien (objet neutre) :
## un goulot sans contrainte en recoit une, et RoundState n'a jamais a tester null.

@export var description_key: String = ""


func hands_per_round(base: int) -> int:
	return base


func discards_per_round(base: int) -> int:
	return base


func hand_size(base: int) -> int:
	return base


## Cartes jouees ou defaussees en une fois.
func max_selected_cards(base: int) -> int:
	return base


## Part du Qi de chaque carte qui compte (1 = tout son Qi).
func card_qi_scale() -> float:
	return 1.0


## Mains perdues a chaque defausse.
func discard_hand_cost() -> int:
	return 0


## Une carte qui ne compte pas forme quand meme la main, mais n'ajoute ni son rang ni ses effets.
func counts(_card: CardInstance) -> bool:
	return true