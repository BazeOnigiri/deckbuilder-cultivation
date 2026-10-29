class_name PillEffect
extends Resource
## Effet d'une pilule sur les cartes selectionnees. Les cartes ont deja ete verifiees par RunState.
## run : la run, pour les effets qui touchent aux pierres, aux niveaux de main ou ajoutent des cartes (null en test).


func apply(_cards: Array[CardInstance], _deck: DeckState, _run: RunState = null) -> void:
	pass