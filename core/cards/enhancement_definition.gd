class_name EnhancementDefinition
extends CardModifier
## Amelioration d'une carte : effets de score et regles speciales, toutes en donnees.

## Applique a chaque fois que la carte compte (recomptes compris).
@export var scored_effect: ScoreEffect
## Applique pour chaque main jouee pendant que la carte reste en main.
@export var held_effect: ScoreEffect
## Pierres gagnees a chaque fois que la carte compte.
@export var scored_stones: int = 0
## Chance que la carte se brise (quitte le paquet) apres avoir compte, tiree avec la RNG de la run.
@export_range(0.0, 1.0) var break_chance: float = 0.0
## La carte compte pour tous les elements (Purete, Harmonie, Cycle, artefacts d'element).
@export var any_element: bool = false
## La carte n'a pas de rang : elle ne forme aucune combinaison, mais compte toujours quand elle est jouee.
@export var rankless: bool = false
## Qi de la carte quand elle compte, a la place de celui de son rang. -1 : celui du rang.
@export var fixed_qi: int = -1


func is_valid() -> bool:
	return (super() and scored_stones >= 0 and break_chance >= 0.0 and break_chance <= 1.0 and fixed_qi >= -1
		and (scored_effect != null or held_effect != null or scored_stones > 0 or any_element or rankless))
