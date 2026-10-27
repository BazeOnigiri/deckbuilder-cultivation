class_name DeckDefinition
extends Resource
## Définition d'un paquet : la liste des cartes avec lesquelles une partie commence.
## Un deck alternatif = un nouveau .tres, sans code.

@export var id: StringName = &""
@export var cards: Array[CardData] = []
## Rangs du paquet et Qi de chaque rang. Absent : une carte rapporte son rang en Qi.
@export var ranks: RankRules


## Vrai si le paquet contient au moins une carte, aucune carte nulle,
## aucune carte sans ID et aucun ID en double.
func is_valid() -> bool:
	if cards.is_empty():
		return false
	var ids: Dictionary = {}
	for card: CardData in cards:
		if card == null or card.id == &"":
			return false
		if ids.has(card.id):
			return false
		ids[card.id] = true
	return true