extends GutTest
## Auras d'artefact en boutique (emplacement, prix, sauvegarde) et cartes ameliorees du sceau de disciples.


func _edition(id: StringName, takes_slot: bool, bonus: int = 0) -> EditionDefinition:
	var edition := EditionDefinition.new()
	edition.id = id
	edition.takes_slot = takes_slot
	edition.for_cards = takes_slot
	edition.price_bonus = bonus
	if takes_slot:
		edition.score_effect = ScoreEffect.new()
	return edition


func _modifiers(editions: Array[EditionDefinition]) -> CardModifierCatalog:
	var catalog := CardModifierCatalog.new()
	catalog.editions = editions
	var enhancement := EnhancementDefinition.new()
	enhancement.id = &"test_amelioration"
	catalog.enhancements.append(enhancement)
	var talisman := TalismanDefinition.new()
	talisman.id = &"test_talisman"
	catalog.talismans.append(talisman)
	return catalog


var _artifacts := _catalog(4)


func _owned() -> ArtifactDefinition:
	var artifact := ArtifactDefinition.new()
	artifact.id = &"artefact_possede"
	artifact.price = 5
	return artifact


func _catalog(count: int) -> Array[ArtifactDefinition]:
	var catalog: Array[ArtifactDefinition] = []
	for i: int in count:
		var artifact := ArtifactDefinition.new()
		artifact.id = StringName("artefact_%d" % i)
		artifact.price = 5
		catalog.append(artifact)
	return catalog


func _run(stones: int) -> RunState:
	var economy := EconomyRules.new()
	economy.starting_stones = stones
	return RunState.new(null, null, null, null, economy)


func _rules(max_artifacts: int, edition_chance: float) -> ShopRules:
	var rules := ShopRules.new()
	rules.id = &"test"
	rules.offer_count = 2
	rules.max_pills = 2
	rules.max_artifacts = max_artifacts
	rules.artifact_edition_chance = edition_chance
	return rules


func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	return rng


func _shop(run: RunState, rules: ShopRules, modifiers: CardModifierCatalog, saved: Dictionary = {},
		packs: Array[PackDefinition] = [], deck: DeckDefinition = DeckDefinition.new()) -> ShopState:
	return ShopState.new(run, _artifacts, [] as Array[ManualDefinition], [] as Array[PillDefinition], packs,
		[] as Array[LegacyDefinition], deck, rules, _rng(), saved, modifiers)


func test_aura_du_vide_s_achete_emplacements_pleins() -> void:
	var run := _run(100)
	var editions: Array[EditionDefinition] = [_edition(&"vide", false, 5)]
	var shop := _shop(run, _rules(1, 1.0), _modifiers(editions))
	run.add_artifact(_owned())
	assert_eq(shop.offer_editions.size(), shop.offers.size(), "chance 1 : toutes les offres ont une aura")
	assert_eq(shop.price_of(0), 10, "prix de l'artefact + bonus de l'aura")
	assert_true(shop.can_buy(0))
	assert_true(shop.buy(0))
	assert_eq(run.stones, 90)
	assert_eq(run.artifact_slots_used(), 1)
	assert_eq(run.artifact_editions[run.artifacts[1].id].id, &"vide")


func test_aura_qui_prend_un_emplacement_ne_s_achete_pas_plein() -> void:
	var run := _run(100)
	var editions: Array[EditionDefinition] = [_edition(&"brume", true)]
	var shop := _shop(run, _rules(1, 1.0), _modifiers(editions))
	run.add_artifact(_owned())
	assert_false(shop.can_buy(0))


func test_chance_nulle_aucune_aura() -> void:
	var editions: Array[EditionDefinition] = [_edition(&"brume", true)]
	assert_true(_shop(_run(10), _rules(5, 0.0), _modifiers(editions)).offer_editions.is_empty())


func test_auras_des_offres_sauvegardees() -> void:
	var editions: Array[EditionDefinition] = [_edition(&"vide", false)]
	var modifiers := _modifiers(editions)
	var run := _run(10)
	var shop := _shop(run, _rules(5, 1.0), modifiers)
	var data: Dictionary = JSON.parse_string(JSON.stringify(shop.to_dict()))
	var restored := _shop(run, _rules(5, 1.0), modifiers, data)
	assert_eq(restored.offers, shop.offers)
	assert_eq(restored.offer_editions, shop.offer_editions)


func test_sceau_de_disciples_propose_des_cartes_ameliorees() -> void:
	var deck := DeckDefinition.new()
	deck.ranks = RankRules.new()
	for rank: int in range(1, 6):
		deck.cards.append(CardData.create(StringName("c%d" % rank), Element.Type.FEU, rank))
	var pack := PackDefinition.new()
	pack.id = &"sceau_test"
	pack.kind = PackDefinition.Kind.CARD
	pack.choices = 3
	pack.price = 1
	pack.enhancement_chance = 1.0
	pack.edition_chance = 1.0
	pack.talisman_chance = 1.0
	var packs: Array[PackDefinition] = [pack]
	var editions: Array[EditionDefinition] = [_edition(&"brume", true)]
	var modifiers := _modifiers(editions)
	var rules := _rules(5, 0.0)
	rules.pack_count = 1
	# Sans paquet de run, add_card ne peut rien inserer : une vraie pioche vide suffit.
	var rng := RandomNumberGenerator.new()
	var run := RunState.new(DeckState.new(DeckDefinition.new(), rng), null, null, null, EconomyRules.new())
	run.stones = 10
	var shop := _shop(run, rules, modifiers, {}, packs, deck)
	assert_true(shop.buy_pack(0))
	assert_eq(shop.opening.cards.size(), 3)
	for card: CardInstance in shop.opening.cards:
		assert_not_null(card.enhancement)
		assert_not_null(card.edition)
		assert_not_null(card.talisman)
	var data: Dictionary = JSON.parse_string(JSON.stringify(shop.to_dict()))
	var restored := _shop(run, rules, modifiers, data, packs, deck)
	assert_eq(restored.opening.cards.size(), 3)
	assert_eq(restored.opening.cards[0].talisman, shop.opening.cards[0].talisman)
	assert_true(shop.take(0))
	assert_eq(run.cards().size(), 1)
	assert_eq(run.cards()[0].enhancement.id, &"test_amelioration")
	assert_eq(run.cards()[0].edition.id, &"brume")
