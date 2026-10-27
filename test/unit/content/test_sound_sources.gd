extends GutTest
## Manifeste des echantillons (tools/sons/sources.json) : tout est CC0, chaque fichier a une taille attendue.

const MANIFEST := "res://tools/sons/sources.json"


func _manifest() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))


func test_tout_est_cc0() -> void:
	var manifest := _manifest()
	for archive: Dictionary in manifest["archives"]:
		assert_eq(archive["licence"], "CC0 1.0", archive["source"])
	assert_eq(manifest["vcsl"]["licence"], "CC0 1.0")


func test_fichiers_vcsl_avec_taille() -> void:
	var files: Array = _manifest()["vcsl"]["files"]
	assert_gt(files.size(), 0)
	for entry: Dictionary in files:
		assert_gt(int(entry["size"]), 0, entry["path"])
		assert_false(String(entry["path"]).contains(".."), "chemin dans le depot VCSL")


func test_bruitages_choisis_dans_les_archives() -> void:
	var manifest := _manifest()
	var sources: Array = manifest["archives"].map(func(archive: Dictionary) -> String: return archive["source"])
	for source: String in manifest["ogg"]:
		assert_has(sources, source)
