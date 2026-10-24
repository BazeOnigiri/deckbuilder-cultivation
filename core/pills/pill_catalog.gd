class_name PillCatalog
extends RefCounted
## Charge les pilules depuis content/pills/.

const DEFAULT_DIR := "res://content/pills"


static func load_definitions(dir_path: String = DEFAULT_DIR) -> Array[PillDefinition]:
	var result: Array[PillDefinition] = []
	for res: Resource in ContentLoader.load_all(dir_path):
		var definition := res as PillDefinition
		if definition == null:
			push_warning("Ressource ignoree dans %s : %s" % [dir_path, res.resource_path])
			continue
		result.append(definition)
	return result