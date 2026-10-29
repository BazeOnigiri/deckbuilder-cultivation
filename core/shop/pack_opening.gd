class_name PackOpening
extends RefCounted
## Sceau-tresor ouvert : les choix tires (ArtifactDefinition, ManualDefinition, PillDefinition ou CardData selon
## pack.kind) et combien on peut encore en prendre.

var pack: PackDefinition
var choices: Array[Resource] = []
var picks_left: int
## Sceau de cartes : la carte proposee pour chaque choix, avec ses ameliorations (meme index que choices).
var cards: Array[CardInstance] = []


func _init(p_pack: PackDefinition, p_choices: Array[Resource]) -> void:
	pack = p_pack
	choices = p_choices
	picks_left = p_pack.picks


func is_done() -> bool:
	return picks_left <= 0 or choices.is_empty()
