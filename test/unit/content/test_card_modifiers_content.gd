extends GutTest
## Ameliorations, auras et talismans de content/ : valides, ids et glyphes uniques, glyphes dans la police des sceaux.

var _modifiers: CardModifierCatalog
var _pills: Array[PillDefinition]


func before_all() -> void:
	_modifiers = CardModifierCatalog.load_default()
	_pills = PillCatalog.load_definitions()


func _all() -> Array[CardModifier]:
	var all: Array[CardModifier] = []
	all.append_array(_modifiers.enhancements)
	all.append_array(_modifiers.editions)
	all.append_array(_modifiers.talismans)
	return all


func test_chaque_fichier_charge() -> void:
	for pair: Array in [[CardModifierCatalog.ENHANCEMENTS_DIR, _modifiers.enhancements],
			[CardModifierCatalog.EDITIONS_DIR, _modifiers.editions], [CardModifierCatalog.TALISMANS_DIR, _modifiers.talismans]]:
		var count := Array(DirAccess.get_files_at(pair[0])).filter(func(name: String) -> bool:
			return name.ends_with(".tres")).size()
		assert_eq(pair[1].size(), count, pair[0])


func test_au_moins_le_contenu_demande() -> void:
	assert_gte(_modifiers.enhancements.size(), 6)
	assert_eq(_modifiers.card_editions().size(), 3)
	assert_eq(_modifiers.artifact_editions().size(), 3)
	assert_eq(_modifiers.talismans.size(), 4)
	assert_true(_modifiers.artifact_editions().any(func(edition: EditionDefinition) -> bool: return not edition.takes_slot))


func test_valides_ids_et_glyphes_uniques() -> void:
	var font: FontFile = load("res://ui/fonts/MaShanZheng-Sceaux.ttf")
	var ids: Dictionary = {}
	var glyphs: Dictionary = {}
	for modifier: CardModifier in _all():
		assert_true(modifier.is_valid(), String(modifier.id))
		assert_false(ids.has(modifier.id), "id en double : %s" % modifier.id)
		ids[modifier.id] = true
		assert_true(font.has_char(modifier.glyph.unicode_at(0)), "glyphe absent de la police : %s" % modifier.id)
		assert_false(glyphs.has(modifier.glyph), "glyphe en double : %s" % modifier.id)
		glyphs[modifier.glyph] = true
		assert_ne(tr(modifier.name_key), modifier.name_key, "nom traduit : %s" % modifier.id)
		assert_ne(tr(modifier.description_key), modifier.description_key, "description traduite : %s" % modifier.id)


func test_chaque_amelioration_aura_de_carte_et_talisman_a_sa_pilule() -> void:
	var given: Dictionary = {}
	for pill: PillDefinition in _pills:
		var imbue := pill.effect as ImbuePillEffect
		if imbue == null:
			continue
		assert_true(pill.price >= 3 and pill.price <= 5, "prix entre 3 et 5 : %s" % pill.id)
		for modifier: CardModifier in [imbue.enhancement, imbue.edition, imbue.talisman]:
			if modifier != null:
				given[modifier.id] = true
	var expected: Array[CardModifier] = []
	expected.append_array(_modifiers.enhancements)
	expected.append_array(_modifiers.card_editions())
	expected.append_array(_modifiers.talismans)
	for modifier: CardModifier in expected:
		assert_true(given.has(modifier.id), "pas de pilule pour %s" % modifier.id)


func test_poids_de_tirage_dans_les_donnees() -> void:
	var shop: ShopRules = load(GameContent.SHOP_RULES_PATH)
	assert_gt(shop.artifact_edition_chance, 0.0)
	assert_lt(shop.artifact_edition_chance, 0.2, "une aura d'artefact reste rare")
	var disciples: PackDefinition = load("res://content/packs/sceau_disciples.tres")
	assert_gt(disciples.enhancement_chance, 0.0)
