class_name HandCatalog
extends RefCounted
## Charge les definitions de mains depuis content/hands/.

const DEFAULT_DIR := "res://content/hands"


static func load_definitions(dir_path: String = DEFAULT_DIR) -> Array[HandDefinition]:
	var result: Array[HandDefinition] = []
	for res: Resource in ContentLoader.load_all(dir_path):
		var definition := res as HandDefinition
		if definition == null:
			push_warning("Ressource ignoree dans %s : %s" % [dir_path, res.resource_path])
			continue
		result.append(definition)
	return result