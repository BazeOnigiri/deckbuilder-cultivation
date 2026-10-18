# res://test/unit/test_smoke.gd
extends GutTest
## Test de fumée : vérifie seulement que GUT tourne, y compris en headless.
## À supprimer quand de vrais tests existeront.


func test_gut_fonctionne() -> void:
	assert_eq(1 + 1, 2, "GUT doit pouvoir exécuter un test simple")