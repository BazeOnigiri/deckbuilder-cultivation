class_name PackCatalog
extends RefCounted
## Charge les sceaux-tresor depuis content/packs/.

const DEFAULT_DIR := "res://content/packs"


static func load_definitions(dir_path: String = DEFAULT_DIR) -> Array[PackDefinition]:
	var result: Array[PackDefinition] = []
	for res: Resource in ContentLoader.load_all(dir_path):
		var definition := res as PackDefinition
		if definition == null:
			push_warning("Ressource ignoree dans %s : %s" % [dir_path, res.resource_path])
			continue
		result.append(definition)
	return result
