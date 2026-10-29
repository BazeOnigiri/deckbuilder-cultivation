class_name TalismanDefinition
extends CardModifier
## Talisman colle sur une carte : regles hors du calcul (recompte, pierres, pilule, niveau de main).

## La carte compte autant de fois en plus : son Qi, ses effets et les artefacts qu'elle declenche.
@export var retriggers: int = 0
## La main jouee monte d'autant de niveaux quand la carte compte (apres le score du coup).
@export var scored_level_ups: int = 0
## Pierres gagnees si la carte est encore en main quand le goulot est franchi.
@export var held_stones: int = 0
## Defaussee : cree une pilule au hasard, s'il reste un emplacement de pilule.
@export var discard_pill: bool = false


func is_valid() -> bool:
	return (super() and retriggers >= 0 and scored_level_ups >= 0 and held_stones >= 0
		and (retriggers > 0 or scored_level_ups > 0 or held_stones > 0 or discard_pill))
