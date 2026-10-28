class_name LegacyCatalog
extends RefCounted
## Charge les heritages depuis content/legacies/.

const DEFAULT_DIR := "res://content/legacies"


static func load_definitions(dir_path: String = DEFAULT_DIR) -> Array[LegacyDefinition]:
	var result: Array[LegacyDefinition] = []
	for res: Resource in ContentLoader.load_all(dir_path):
		var definition := res as LegacyDefinition
		if definition == null:
			push_warning("Ressource ignoree dans %s : %s" % [dir_path, res.resource_path])
			continue
		result.append(definition)
	return result
