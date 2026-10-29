extends GutTest
## Difficultes et defis de content/difficulties et content/challenges.

var _content: GameContent


func before_all() -> void:
	_content = GameContent.load_default()


## Une propriete de regle que modifie un modificateur doit exister quelque part, sinon il ne fait rien.
func _known(property: StringName) -> bool:
	return property in _content.round_rules or property in _content.economy or property in _content.shop_rules


func _translated(key: String) -> bool:
	return TranslationServer.translate(key) != key


func test_difficultes_valides_et_numerotees() -> void:
	assert_gte(_content.difficulties.size(), 2)
	for i: int in _content.difficulties.size():
		var difficulty := _content.difficulties[i]
		assert_true(difficulty.is_valid(), String(difficulty.id))
		assert_eq(difficulty.level, i + 1, "niveaux 1, 2, 3... sans trou")
		assert_true(_translated(difficulty.name_key), difficulty.name_key)
		assert_true(_translated(difficulty.description_key), difficulty.description_key)
		for modifier: RuleModifier in difficulty.modifiers:
			assert_true(_known(modifier.property), String(modifier.property))
	assert_true(_content.difficulties[0].modifiers.is_empty(), "le niveau 1 est le jeu de base")


func test_chaque_niveau_ajoute_une_contrainte() -> void:
	for difficulty: DifficultyDefinition in _content.difficulties.slice(1):
		assert_false(difficulty.modifiers.is_empty(), String(difficulty.id))


func test_defis_valides() -> void:
	assert_between(_content.challenges.size(), 4, 6)
	var starter_ids := _content.starter_deck.cards.map(func(card: CardData) -> StringName: return card.id)
	for challenge: ChallengeDefinition in _content.challenges:
		assert_true(challenge.is_valid(), String(challenge.id))
		assert_true(_translated(challenge.name_key), challenge.name_key)
		assert_true(_translated(challenge.description_key), challenge.description_key)
		assert_not_null(_content.difficulty_of(challenge.difficulty), "difficulte connue : %s" % challenge.id)
		for modifier: RuleModifier in challenge.modifiers:
			assert_true(_known(modifier.property), String(modifier.property))
		if challenge.deck != null:
			for card: CardData in challenge.deck.cards:
				assert_has(starter_ids, card.id, "la sauvegarde retrouve les cartes dans le paquet habituel")
		var rules := _content.round_rules.duplicate()
		for modifier: RuleModifier in _content.modifiers_for(RunSetup.for_challenge(challenge, "X")):
			modifier.apply_to(rules)
		assert_true(rules.is_valid(), "defi jouable : %s" % challenge.id)


func test_pool_de_tribulations() -> void:
	assert_gte(_content.tribulations.size(), _content.realms.size(), "une tribulation differente par royaume")
	for tribulation: BottleneckDefinition in _content.tribulations:
		assert_not_null(tribulation.constraint)


func test_nom_des_royaumes_generes_traduit() -> void:
	assert_true(_translated(RunProgress.ENDLESS_NAME_KEY))
	assert_string_contains(String(TranslationServer.translate(RunProgress.ENDLESS_NAME_KEY)), "%d")
