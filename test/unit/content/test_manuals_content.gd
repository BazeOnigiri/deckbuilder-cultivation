extends GutTest

const MANUALS_DIR := "res://content/manuals"

var _manuals: Array[ManualDefinition]


func before_all() -> void:
	_manuals = ManualCatalog.load_definitions(MANUALS_DIR)


func test_tous_les_manuels_valides() -> void:
	assert_gt(_manuals.size(), 0)
	for manual: ManualDefinition in _manuals:
		assert_true(manual.is_valid(), "manuel invalide : %s" % manual.resource_path)


## Si une main est ajoutee sans relancer tools/generate_manuals.gd, ce test le signale.
func test_un_manuel_par_main() -> void:
	var hand_ids: Array[String] = []
	for manual: ManualDefinition in _manuals:
		assert_false(hand_ids.has(manual.hand.id), "deux manuels pour %s" % manual.hand.id)
		hand_ids.append(manual.hand.id)
	for hand: HandDefinition in HandCatalog.load_definitions():
		assert_true(hand_ids.has(hand.id), "pas de manuel pour %s" % hand.id)


func test_ids_uniques() -> void:
	var ids: Dictionary = {}
	for manual: ManualDefinition in _manuals:
		assert_false(ids.has(manual.id), "id en double : %s" % manual.id)
		ids[manual.id] = true


## Chaque livre est different : sinogramme propre (dans la police des sceaux), et couleur + motif jamais repetes.
func test_couvertures_toutes_differentes() -> void:
	var font: FontFile = load("res://ui/fonts/MaShanZheng-Sceaux.ttf")
	var glyphs := {}
	var covers := {}
	for manual: ManualDefinition in _manuals:
		assert_eq(manual.glyph.length(), 1, "sinogramme d'un caractere : %s" % manual.id)
		if manual.glyph.length() == 1:
			assert_true(font.has_char(manual.glyph.unicode_at(0)), "sinogramme absent de la police : %s" % manual.id)
		assert_false(glyphs.has(manual.glyph), "sinogramme en double : %s" % manual.id)
		glyphs[manual.glyph] = true
		var cover := Vector2i(manual.tier, manual.pattern)
		assert_false(covers.has(cover), "couleur et motif deja pris : %s" % manual.id)
		covers[cover] = true


## Couleur de couverture : suit la rarete de la main, et existe dans le Theme.
func test_couleur_selon_la_rarete() -> void:
	var theme: Theme = load("res://ui/theme/lavis_de_nuit.tres")
	for a: ManualDefinition in _manuals:
		assert_true(theme.has_color(StringName("tier_%d" % a.tier), &"ManualCover"), "couleur absente : %s" % a.id)
		for b: ManualDefinition in _manuals:
			if a.hand.priority < b.hand.priority:
				assert_lte(a.tier, b.tier, "%s plus commun que %s" % [a.id, b.id])
