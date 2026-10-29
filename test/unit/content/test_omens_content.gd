extends GutTest
## Presages de content/omens : valides, ids et glyphes uniques, glyphes dans la police des sceaux.

var _content: GameContent


func before_all() -> void:
	_content = GameContent.load_default()


func test_chaque_fichier_donne_un_presage() -> void:
	var count := 0
	for file_name: String in DirAccess.get_files_at(GameContent.OMENS_DIR):
		if file_name.trim_suffix(".remap").ends_with(".tres"):
			count += 1
	assert_eq(_content.omens.size(), count)
	assert_between(count, 8, 10)


func test_valides_ids_et_glyphes_uniques() -> void:
	var font: FontFile = load("res://ui/fonts/MaShanZheng-Sceaux.ttf")
	var ids := {}
	var glyphs := {}
	for omen: OmenDefinition in _content.omens:
		assert_true(omen.is_valid(), omen.resource_path)
		assert_false(ids.has(omen.id), "id en double : %s" % omen.id)
		ids[omen.id] = true
		assert_eq(omen.glyph.length(), 1, "glyphe d'un caractere : %s" % omen.id)
		if omen.glyph.length() == 1:
			assert_true(font.has_char(omen.glyph.unicode_at(0)), "glyphe absent de la police : %s" % omen.id)
		assert_false(glyphs.has(omen.glyph), "glyphe en double : %s" % omen.id)
		glyphs[omen.glyph] = true


func test_textes_traduits() -> void:
	for omen: OmenDefinition in _content.omens:
		for key: String in [omen.name_key, omen.description_key]:
			assert_ne(TranslationServer.translate(key), key, key)


func test_main_de_repli_existe() -> void:
	var hand_ids := _content.hands.map(func(hand: HandDefinition) -> String: return String(hand.id))
	for omen: OmenDefinition in _content.omens:
		if omen.effect is LevelHandOmenEffect:
			assert_has(hand_ids, String((omen.effect as LevelHandOmenEffect).fallback_hand))
