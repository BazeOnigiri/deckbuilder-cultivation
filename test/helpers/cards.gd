extends RefCounted
## Fabrique de cartes pour les tests. Pas de class_name : test/ est exclu de l'export.

const BOIS := Element.Type.BOIS
const FEU := Element.Type.FEU
const TERRE := Element.Type.TERRE
const METAL := Element.Type.METAL
const EAU := Element.Type.EAU


## Ex : hand([[FEU, 3], [EAU, 3]]). Chaque carte recoit un uid et un id distincts.
static func hand(specs: Array) -> Array[CardInstance]:
	var result: Array[CardInstance] = []
	for i: int in specs.size():
		var spec: Array = specs[i]
		var card_id := StringName("test_%d_%d_%d" % [i, spec[0], spec[1]])
		result.append(CardInstance.new(i, CardData.create(card_id, spec[0], spec[1])))
	return result