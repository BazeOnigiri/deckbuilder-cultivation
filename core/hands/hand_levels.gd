class_name HandLevels
extends RefCounted
## Niveau de chaque main pendant une run (1 par defaut). Monte avec les manuels.

var _levels: Dictionary = {}


func level_of(hand_id: String) -> int:
	return _levels.get(hand_id, 1)


func level_up(hand_id: String) -> void:
	_levels[hand_id] = level_of(hand_id) + 1