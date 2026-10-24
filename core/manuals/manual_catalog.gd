class_name ManualCatalog
extends RefCounted
## Charge les manuels depuis content/manuals/.

const DEFAULT_DIR := "res://content/manuals"


static func load_definitions(dir_path: String = DEFAULT_DIR) -> Array[ManualDefinition]:
	var result: Array[ManualDefinition] = []
	for res: Resource in ContentLoader.load_all(dir_path):
		var definition := res as ManualDefinition
		if definition == null:
			push_warning("Ressource ignoree dans %s : %s" % [dir_path, res.resource_path])
			continue
		result.append(definition)
	return result