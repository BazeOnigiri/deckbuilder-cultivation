class_name ArtifactCatalog
extends RefCounted
## Charge les artefacts depuis content/artifacts/.

const DEFAULT_DIR := "res://content/artifacts"


static func load_definitions(dir_path: String = DEFAULT_DIR) -> Array[ArtifactDefinition]:
	var result: Array[ArtifactDefinition] = []
	for res: Resource in ContentLoader.load_all(dir_path):
		var definition := res as ArtifactDefinition
		if definition == null:
			push_warning("Ressource ignoree dans %s : %s" % [dir_path, res.resource_path])
			continue
		result.append(definition)
	return result