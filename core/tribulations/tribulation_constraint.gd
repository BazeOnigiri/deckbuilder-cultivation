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


## Une carte qui ne compte pas forme quand meme la main, mais n'ajoute ni son rang ni ses effets.
func counts(_card: CardInstance) -> bool:
	return true