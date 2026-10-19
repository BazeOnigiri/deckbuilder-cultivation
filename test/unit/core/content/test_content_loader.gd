extends GutTest


func test_charge_les_ressources_d_un_dossier() -> void:
	var resources := ContentLoader.load_all("res://content/rules")
	assert_gt(resources.size(), 0)
	for res: Resource in resources:
		assert_not_null(res)


func test_ordre_stable() -> void:
	var a := ContentLoader.load_all("res://content/hands")
	var b := ContentLoader.load_all("res://content/hands")
	assert_eq(a.size(), b.size())
	for i: int in a.size():
		assert_eq(a[i].resource_path, b[i].resource_path)