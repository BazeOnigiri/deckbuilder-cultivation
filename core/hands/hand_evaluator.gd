class_name HandEvaluator
extends RefCounted
## Trouve la main la plus forte. Ne connait aucune main en dur.

var _definitions: Array[HandDefinition] = []


func _init(definitions: Array[HandDefinition]) -> void:
	_definitions = definitions.duplicate()
	_definitions.sort_custom(func(a: HandDefinition, b: HandDefinition) -> bool:
		return a.priority > b.priority)


## Renvoie null si aucune main ne correspond (aucune carte jouee).
func evaluate(cards: Array[CardInstance]) -> HandResult:
	for definition: HandDefinition in _definitions:
		var scoring: Array[CardInstance] = definition.detector.detect(cards)
		if not scoring.is_empty():
			return HandResult.new(definition, scoring)
	return null