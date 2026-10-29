extends GutTest
## Donnees des deblocages et des succes : valides, references existantes, un tiers du contenu verrouille.

var _content: GameContent


func before_all() -> void:
	_content = GameContent.load_default()


func test_verrous_valides_et_references_existantes() -> void:
	var rules := UnlockCatalog.load_rules()
	assert_gt(rules.size(), 0)
	var seen: Dictionary = {}
	for rule: UnlockRule in rules:
		assert_true(rule.is_valid(), String(rule.content_id))
		assert_false(seen.has(rule.content_id), "un seul verrou par contenu : %s" % rule.content_id)
		seen[rule.content_id] = true
		var item := _content.item_by_id(rule.content_id)
		assert_not_null(item, "contenu inconnu : %s" % rule.content_id)
		_assert_hand_exists(rule.condition)


func test_environ_un_tiers_du_contenu_est_verrouille() -> void:
	var total := _content.artifacts.size() + _content.pills.size() + _content.legacies.size() + _content.packs.size()
	var locked := UnlockCatalog.load_rules().size()
	assert_between(float(locked) / total, 0.25, 0.4)


func test_les_conditions_de_deblocage_sont_des_conditions_de_profil() -> void:
	for rule: UnlockRule in UnlockCatalog.load_rules():
		assert_lt(rule.condition.kind, UnlockCondition.Kind.WIN_NO_PURCHASE, "%s : un contenu ne se debloque que par le profil" % rule.content_id)


func test_les_artefacts_de_depart_restent_ouverts() -> void:
	var open := _content.unlocks.open(_content.artifacts, ProfileStats.new())
	var cheap := open.filter(func(artifact: ArtifactDefinition) -> bool: return artifact.rarity == 0)
	assert_gte(cheap.size(), 8, "assez d'artefacts simples pour une premiere partie")
	assert_gte(_content.unlocks.open(_content.pills, ProfileStats.new()).size(), 5)
	assert_gte(_content.unlocks.open(_content.packs, ProfileStats.new()).size(), _content.shop_rules.pack_count)


func test_succes_valides_uniques_et_en_bon_nombre() -> void:
	var achievements := UnlockCatalog.load_achievements()
	assert_between(achievements.size(), 15, 25)
	var ids: Dictionary = {}
	var glyphs: Dictionary = {}
	for achievement: AchievementDefinition in achievements:
		assert_true(achievement.is_valid(), String(achievement.id))
		assert_false(ids.has(achievement.id), "id en double : %s" % achievement.id)
		ids[achievement.id] = true
		glyphs[achievement.glyph] = true
		_assert_hand_exists(achievement.condition)
		assert_ne(tr(achievement.name_key), achievement.name_key, "nom traduit : %s" % achievement.id)
		assert_ne(tr(achievement.description_key), achievement.description_key, "description traduite : %s" % achievement.id)
	assert_gte(glyphs.size(), achievements.size() - 1, "glyphes distincts")


func test_chaque_type_de_condition_a_son_texte() -> void:
	for kind: String in UnlockCondition.Kind.keys():
		assert_ne(tr("UNLOCK_" + kind), "UNLOCK_" + kind, kind)


func test_les_glyphes_sont_dans_la_police_des_sceaux() -> void:
	var font := load("res://ui/fonts/MaShanZheng-Sceaux.ttf") as FontFile
	for achievement: AchievementDefinition in UnlockCatalog.load_achievements():
		assert_true(font.has_char(achievement.glyph.unicode_at(0)), achievement.glyph)


func _assert_hand_exists(condition: UnlockCondition) -> void:
	if condition.kind != UnlockCondition.Kind.HAND_PLAYED:
		return
	assert_true(_content.hands.any(func(hand: HandDefinition) -> bool: return hand.id == condition.target), "main inconnue : %s" % condition.target)
