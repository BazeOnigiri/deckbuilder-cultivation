extends GutTest
## Rencontres de content/events : valides, ids et glyphes uniques, glyphes dans la police des sceaux, textes FR et EN.

var _content: GameContent


func before_all() -> void:
	_content = GameContent.load_default()


func test_chaque_fichier_donne_une_rencontre() -> void:
	var count := 0
	for file_name: String in DirAccess.get_files_at(GameContent.EVENTS_DIR):
		if file_name.trim_suffix(".remap").ends_with(".tres"):
			count += 1
	assert_eq(_content.events.size(), count)
	assert_between(count, 10, 14)


func test_regles_valides() -> void:
	assert_not_null(_content.event_rules)
	assert_true(_content.event_rules.is_valid())
	assert_between(_content.event_rules.chance, 0.01, 1.0)


func test_valides_ids_et_glyphes_uniques() -> void:
	var font: FontFile = load("res://ui/fonts/MaShanZheng-Sceaux.ttf")
	var ids := {}
	var glyphs := {}
	for event: EventDefinition in _content.events:
		assert_true(event.is_valid(), event.resource_path)
		assert_true(String(event.id).begins_with("evenement_"), String(event.id))
		assert_false(ids.has(event.id), "id en double : %s" % event.id)
		ids[event.id] = true
		assert_eq(event.glyph.length(), 1, "glyphe d'un caractere : %s" % event.id)
		if event.glyph.length() == 1:
			assert_true(font.has_char(event.glyph.unicode_at(0)), "glyphe absent de la police : %s" % event.id)
		assert_false(glyphs.has(event.glyph), "glyphe en double : %s" % event.id)
		glyphs[event.glyph] = true


## Toutes les rencontres ne demandent pas le meme royaume : il y en a des le premier.
func test_rencontres_des_le_premier_royaume() -> void:
	assert_true(_content.events.any(func(event: EventDefinition) -> bool: return event.min_realm == 1))
	var realms := _content.realms.size()
	for event: EventDefinition in _content.events:
		assert_true(event.min_realm <= realms, "%s : royaume jamais atteint" % event.id)


func _keys(event: EventDefinition) -> Array[String]:
	var keys: Array[String] = [event.title_key, event.text_key]
	for choice: EventChoice in event.choices:
		keys.append(choice.label_key)
		if choice.cost != null:
			keys.append("EVENT_COST_" + EventCost.Kind.keys()[choice.cost.kind])
		for outcome: EventOutcome in choice.outcomes:
			keys.append(outcome.text_key)
	return keys


func test_textes_en_francais_et_en_anglais() -> void:
	var extra: Array[String] = ["UI_EVENT_CONTINUE", "UI_EVENT_CHANCE", "UI_KIND_EVENT", "UI_COMPENDIUM_EVENTS",
		"EVENT_FX_NOTHING", "EVENT_BLOCK_STONES", "EVENT_BLOCK_CARDS", "EVENT_BLOCK_ARTIFACT", "EVENT_BLOCK_ARTIFACT_SLOT",
		"EVENT_BLOCK_NO_ARTIFACT", "EVENT_BLOCK_PILL_SLOT", "UNLOCK_EVENTS_SEEN"]
	for locale: String in ["fr", "en"]:
		var translation := TranslationServer.get_translation_object(locale)
		assert_not_null(translation, locale)
		var keys: Array[String] = extra.duplicate()
		for event: EventDefinition in _content.events:
			keys.append_array(_keys(event))
		for key: String in keys:
			assert_ne(String(translation.get_message(key)), "", "%s absent en %s" % [key, locale])


func test_presages_donnes_existent() -> void:
	for event: EventDefinition in _content.events:
		for choice: EventChoice in event.choices:
			for outcome: EventOutcome in choice.outcomes:
				for effect: EventEffect in outcome.effects:
					if effect is OmenEventEffect:
						assert_not_null(_content.omen_by_id((effect as OmenEventEffect).omen.id),
							"%s : presage hors de content/omens (non sauvegardable)" % event.id)
