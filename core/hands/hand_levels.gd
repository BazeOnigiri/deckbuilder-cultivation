class_name HandLevels
extends RefCounted
## Niveau de chaque main pendant une run (1 par defaut). Monte avec les manuels.

var _levels: Dictionary = {}


func level_of(hand_id: String) -> int:
	return _levels.get(hand_id, 1)


func level_up(hand_id: String) -> void:
	_levels[hand_id] = level_of(hand_id) + 1


func to_dict() -> Dictionary:
	return _levels.duplicate()


## Ne garde que les paires id texte -> niveau superieur a 1 (le niveau 1 est la valeur par defaut).
static func from_dict(data: Variant) -> HandLevels:
	var levels := HandLevels.new()
	if not data is Dictionary:
		return levels
	for key: Variant in data:
		if key is String and SaveData.int_of(data, key) > 1:
			levels._levels[key] = SaveData.int_of(data, key)
	return levels