class_name HandEvaluator
extends RefCounted
## Trouve la main la plus forte. Ne connait aucune main en dur.

var _definitions: Array[HandDefinition] = []


func _init(definitions: Array[HandDefinition]) -> void:
	_definitions = definitions.duplicate()
	_definitions.sort_custom(func(a: HandDefinition, b: HandDefinition) -> bool:
		return a.priority > b.priority)


## Renvoie null si aucune main ne correspond (aucune carte jouee).
## Les cartes sans rang ne forment aucune combinaison mais comptent toujours ; que des cartes sans rang : la main la
## moins prioritaire.
func evaluate(cards: Array[CardInstance]) -> HandResult:
	var ranked: Array[CardInstance] = []
	var rankless: Array[CardInstance] = []
	for card: CardInstance in cards:
		if card.is_rankless():
			rankless.append(card)
		else:
			ranked.append(card)
	if ranked.is_empty():
		return null if rankless.is_empty() or _definitions.is_empty() else HandResult.new(_definitions.back(), rankless)
	for definition: HandDefinition in _definitions:
		var scoring: Array[CardInstance] = definition.detector.detect(ranked)
		if not scoring.is_empty():
			scoring.append_array(rankless)
			return HandResult.new(definition, scoring)
	return null