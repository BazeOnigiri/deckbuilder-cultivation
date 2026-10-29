class_name UnlockCatalog
extends RefCounted
## Charge les verrous (content/unlocks/) et les succes (content/achievements/).

const RULES_DIR := "res://content/unlocks"
const ACHIEVEMENTS_DIR := "res://content/achievements"


static func load_rules(dir_path: String = RULES_DIR) -> Array[UnlockRule]:
	var result: Array[UnlockRule] = []
	for res: Resource in ContentLoader.load_all(dir_path):
		if res is UnlockRule:
			result.append(res)
		else:
			push_warning("Ressource ignoree dans %s : %s" % [dir_path, res.resource_path])
	return result


static func load_achievements(dir_path: String = ACHIEVEMENTS_DIR) -> Array[AchievementDefinition]:
	var result: Array[AchievementDefinition] = []
	for res: Resource in ContentLoader.load_all(dir_path):
		if res is AchievementDefinition:
			result.append(res)
		else:
			push_warning("Ressource ignoree dans %s : %s" % [dir_path, res.resource_path])
	return result
