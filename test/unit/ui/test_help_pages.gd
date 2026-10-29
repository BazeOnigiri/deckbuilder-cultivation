extends GutTest
## Aide « Comment jouer » : sections remplies avec les vraies valeurs du contenu, dans les deux langues.


func after_each() -> void:
	TranslationServer.set_locale("fr")


func test_les_nombres_viennent_du_contenu() -> void:
	var content := GameContent.load_default()
	var text := "\n".join(HelpPages.sections(content).map(func(s: PackedStringArray) -> String: return s[1]))
	assert_string_contains(text, "%d mains" % content.round_rules.hands_per_round)
	assert_string_contains(text, str(content.economy.interest_cap))
	assert_string_contains(text, str(content.realms.size()))


func test_aucune_cle_non_traduite_en_francais_et_en_anglais() -> void:
	var content := GameContent.load_default()
	for locale: String in ["fr", "en"]:
		TranslationServer.set_locale(locale)
		for section: PackedStringArray in HelpPages.sections(content):
			assert_false(section[0].begins_with("HELP_"), "titre %s (%s)" % [section[0], locale])
			assert_false(section[1].begins_with("HELP_"), "corps %s (%s)" % [section[1], locale])
			assert_false(section[1].contains("%d") or section[1].contains("%s"), "format non rempli : " + section[1])


func test_le_signet_aide_n_existe_qu_avec_le_contenu() -> void:
	var content := GameContent.load_default()
	var run := content.new_run(RandomNumberGenerator.new())
	var without: TabContainer = add_child_autofree(RunInfo.build(run, content.hands))
	var with_help: TabContainer = add_child_autofree(RunInfo.build(run, content.hands, content))
	assert_eq(with_help.get_tab_count(), without.get_tab_count() + 1)
