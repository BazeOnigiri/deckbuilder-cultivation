class_name RealmCatalog
extends RefCounted
## Charge les royaumes depuis content/realms/.

const DEFAULT_DIR := "res://content/realms"


static func load_definitions(dir_path: String = DEFAULT_DIR) -> Array[RealmDefinition]:
	var result: Array[RealmDefinition] = []
	for res: Resource in ContentLoader.load_all(dir_path):
		var definition := res as RealmDefinition
		if definition == null:
			push_warning("Ressource ignoree dans %s : %s" % [dir_path, res.resource_path])
			continue
		result.append(definition)
	return result