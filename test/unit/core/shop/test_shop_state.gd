extends GutTest


func _artifact(id: String, price: int) -> ArtifactDefinition:
	var artifact := ArtifactDefinition.new()
	artifact.id = StringName(id)
	artifact.price = price
	return artifact


func _catalog(count: int, price: int = 5) -> Array[ArtifactDefinition]:
	var catalog: Array[ArtifactDefinition] = []
	for i: int in count:
		catalog.append(_artifact("a%d" % i, price))
	return catalog


func _manuals(count: int = 3, price: int = 3) -> Array[ManualDefinition]:
	var manuals: Array[ManualDefinition] = []
	for i: int in count:
		var hand := HandDefinition.new()
		hand.id = "main_%d" % i
		var manual := ManualDefinition.new()
		manual.id = StringName("manuel_%d" % i)
		manual.hand = hand
		manual.price = price
		manuals.append(manual)
	return manuals

func _pills(count: int = 3, price: int = 3) -> Array[PillDefinition]:
	var pills: Array[PillDefinition] = []
	for i: int in count:
		var pill := PillDefinition.new()
		pill.id = StringName("pilule_%d" % i)
		pill.price = price
		pills.append(pill)
	return pills

func _rules(offer_count: int = 2, max_artifacts: int = 5) -> ShopRules:
	var rules := ShopRules.new()
	rules.id = &"test"
	rules.offer_count = offer_count
	rules.max_pills = 2
	rules.reroll_base_cost = 5
	rules.reroll_cost_step = 1
	rules.max_artifacts = max_artifacts
	return rules


## Seuls les pierres, les artefacts et les niveaux de main de la run servent a la boutique.
func _run(stones: int) -> RunState:
	var economy := EconomyRules.new()
	economy.starting_stones = stones
	return RunState.new(null, null, null, null, economy)


func _rng(seed_value: int = 1) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _shop(run: RunState, catalog: Array[ArtifactDefinition], rules: ShopRules = null, seed_value: int = 1) -> ShopState:
	var packs: Array[PackDefinition] = []
	return ShopState.new(run, catalog, _manuals(), _pills(), packs, [] as Array[LegacyDefinition], DeckDefinition.new(), rules if rules != null else _rules(),
		_rng(seed_value))

## Boutique d'un seul emplacement, toujours de ce type d'offre.
func _shop_of(run: RunState, kind: ShopRules.OfferKind, max_artifacts: int = 5) -> ShopState:
	var rules := _rules(1, max_artifacts)
	rules.kind_weights = PackedFloat32Array([0, 0, 0])
	rules.kind_weights[kind] = 1.0
	return _shop(run, _catalog(5), rules)


func _ids(artifacts: Array[ArtifactDefinition]) -> Array:
	var ids: Array = []
	for artifact: ArtifactDefinition in artifacts:
		ids.append(artifact.id)
	return ids


func test_offres_distinctes_au_bon_nombre() -> void:
	var shop := _shop(_run(10), _catalog(5))
	assert_eq(shop.offers.size(), 2)
	assert_ne(shop.offers[0].id, shop.offers[1].id)


func test_jamais_un_artefact_deja_possede() -> void:
	var catalog := _catalog(3)
	var run := _run(10)
	run.artifacts.append(catalog[0])
	var shop := _shop(run, catalog, _rules(5))
	assert_eq(shop.offers.size(), 2)
	assert_false(_ids(shop.offers).has(catalog[0].id))


func test_achat_debite_ajoute_et_retire_l_offre() -> void:
	var run := _run(10)
	var shop := _shop(run, _catalog(5, 6))
	var bought: ArtifactDefinition = shop.offers[0]
	assert_true(shop.buy(0))
	assert_eq(run.stones, 4)
	assert_true(run.artifacts.has(bought))
	assert_eq(shop.offers.size(), 1)


func test_achat_refuse_sans_assez_de_pierres() -> void:
	var run := _run(3)
	var shop := _shop(run, _catalog(5, 6))
	assert_false(shop.buy(0))
	assert_eq(run.stones, 3)
	assert_eq(run.artifacts.size(), 0)
	assert_eq(shop.offers.size(), 2)


func test_achat_refuse_au_maximum_d_artefacts() -> void:
	var run := _run(100)
	run.artifacts.append(_artifact("deja", 1))
	var shop := _shop(run, _catalog(5), _rules(2, 1))
	assert_false(shop.buy(0))
	assert_eq(run.stones, 100)


func test_achat_index_invalide() -> void:
	var shop := _shop(_run(100), _catalog(5))
	assert_false(shop.buy(-1))
	assert_false(shop.buy(2))


func test_relance_debite_et_augmente_le_cout() -> void:
	var run := _run(20)
	var shop := _shop(run, _catalog(5))
	assert_true(shop.reroll())
	assert_eq(run.stones, 15)
	assert_eq(shop.reroll_cost, 6)
	assert_eq(shop.offers.size(), 2)


func test_relance_refusee_sans_assez_de_pierres() -> void:
	var run := _run(4)
	var shop := _shop(run, _catalog(5))
	assert_false(shop.reroll())
	assert_eq(run.stones, 4)
	assert_eq(shop.reroll_cost, 5)


func test_meme_seed_memes_offres() -> void:
	var catalog := _catalog(10)
	var a := _shop(_run(10), catalog, null, 42)
	var b := _shop(_run(10), catalog, null, 42)
	assert_eq(_ids(a.offers), _ids(b.offers))


func test_un_manuel_propose() -> void:
	var shop := _shop_of(_run(10), ShopRules.OfferKind.MANUAL)
	assert_eq(shop.manual_offers.size(), 1)
	assert_true(shop.offers.is_empty())


func test_achat_manuel_monte_le_niveau_et_debite() -> void:
	var run := _run(10)
	var shop := _shop_of(run, ShopRules.OfferKind.MANUAL)
	var hand_id: String = shop.manual_offers[0].hand.id
	assert_true(shop.buy_manual(0))
	assert_eq(run.stones, 7)
	assert_eq(run.hand_levels.level_of(hand_id), 2)
	assert_eq(shop.manual_offers.size(), 0)


func test_manuel_achetable_au_maximum_d_artefacts() -> void:
	var run := _run(10)
	run.artifacts.append(_artifact("deja", 1))
	var shop := _shop_of(run, ShopRules.OfferKind.MANUAL, 1)
	assert_true(shop.buy_manual(0))


func test_achat_manuel_refuse_sans_assez_de_pierres() -> void:
	var run := _run(2)
	var shop := _shop_of(run, ShopRules.OfferKind.MANUAL)
	assert_false(shop.buy_manual(0))
	assert_eq(run.stones, 2)


func test_une_pilule_proposee() -> void:
	var shop := _shop_of(_run(10), ShopRules.OfferKind.PILL)
	assert_eq(shop.pill_offers.size(), 1)


func test_achat_pilule_ajoute_a_l_inventaire_et_debite() -> void:
	var run := _run(10)
	var shop := _shop_of(run, ShopRules.OfferKind.PILL)
	assert_true(shop.buy_pill(0))
	assert_eq(run.stones, 7)
	assert_eq(run.pills.size(), 1)
	assert_eq(shop.pill_offers.size(), 0)


func test_achat_pilule_refuse_inventaire_plein() -> void:
	var run := _run(10)
	run.pills.append_array(_pills(2))
	var shop := _shop_of(run, ShopRules.OfferKind.PILL)
	assert_false(shop.buy_pill(0))
	assert_eq(run.stones, 10)


## Chaque emplacement tire son type : sur 3000 relances d'un emplacement, la repartition suit 70 / 15 / 15.
func test_types_d_offre_selon_leurs_poids() -> void:
	var rules := _rules(1)
	rules.kind_weights = PackedFloat32Array([70, 15, 15])
	rules.reroll_base_cost = 0
	rules.reroll_cost_step = 0
	var shop := _shop(_run(0), _catalog(5), rules)
	var counts := [0, 0, 0]
	var rolls := 3000
	for i: int in rolls:
		counts[0] += shop.offers.size()
		counts[1] += shop.manual_offers.size()
		counts[2] += shop.pill_offers.size()
		shop.reroll()
	assert_almost_eq(counts[0] / float(rolls), 0.70, 0.03)
	assert_almost_eq(counts[1] / float(rolls), 0.15, 0.03)
	assert_almost_eq(counts[2] / float(rolls), 0.15, 0.03)


## Un type sans objet a proposer (tous les artefacts possedes) laisse sa place aux autres.
func test_type_epuise_laisse_la_place() -> void:
	var catalog := _catalog(1)
	var run := _run(0)
	run.artifacts.append(catalog[0])
	var rules := _rules(2)
	rules.kind_weights = PackedFloat32Array([70, 15, 15])
	var shop := _shop(run, catalog, rules)
	assert_true(shop.offers.is_empty())
	assert_eq(shop.manual_offers.size() + shop.pill_offers.size(), 2)


## Une rarete est tiree selon ses poids, puis un artefact : sur 4000 relances, la repartition suit 70/22/7/1.
func test_tirage_suit_les_poids_de_rarete() -> void:
	var catalog: Array[ArtifactDefinition] = []
	for tier: int in 4:
		for copy: int in 2:
			var artifact := _artifact("r%d_%d" % [tier, copy], 5)
			artifact.rarity = tier
			catalog.append(artifact)
	var rules := _rules(1)
	rules.rarity_weights = PackedFloat32Array([70, 22, 7, 1])
	rules.reroll_base_cost = 0
	rules.reroll_cost_step = 0
	var shop := _shop(_run(0), catalog, rules)
	var counts := [0, 0, 0, 0]
	var rolls := 4000
	for i: int in rolls:
		counts[shop.offers[0].rarity] += 1
		shop.reroll()
	assert_almost_eq(counts[0] / float(rolls), 0.70, 0.03)
	assert_almost_eq(counts[1] / float(rolls), 0.22, 0.03)
	assert_almost_eq(counts[2] / float(rolls), 0.07, 0.02)
	assert_almost_eq(counts[3] / float(rolls), 0.01, 0.01)


## Plus d'artefact d'une rarete (deja possedes) : son poids ne compte plus, les offres restent pleines.
func test_rarete_epuisee_ignoree() -> void:
	var catalog: Array[ArtifactDefinition] = [_artifact("commun", 5), _artifact("divin", 5)]
	catalog[1].rarity = 3
	var rules := _rules(2)
	rules.rarity_weights = PackedFloat32Array([70, 22, 7, 1])
	var shop := _shop(_run(0), catalog, rules)
	assert_eq(shop.offers.size(), 2)


func _pack(kind: PackDefinition.Kind, choices: int = 3, picks: int = 1, price: int = 4) -> PackDefinition:
	var pack := PackDefinition.new()
	pack.id = StringName("sceau_%d" % kind)
	pack.kind = kind
	pack.choices = choices
	pack.picks = picks
	pack.price = price
	return pack


## Boutique sans offre (pas de catalogue) et avec ce seul sceau a vendre.
func _shop_with_pack(run: RunState, pack: PackDefinition, catalog: Array[ArtifactDefinition] = []) -> ShopState:
	var deck := DeckDefinition.new()
	for rank: int in range(1, 6):
		deck.cards.append(CardData.create(StringName("c%d" % rank), Element.Type.FEU, rank))
	var rules := _rules(1)
	rules.pack_count = 1
	var packs: Array[PackDefinition] = [pack]
	return ShopState.new(run, catalog, _manuals(), _pills(), packs, [] as Array[LegacyDefinition], deck, rules, _rng())


func test_sceau_ouvert_montre_ses_choix() -> void:
	var run := _run(10)
	var shop := _shop_with_pack(run, _pack(PackDefinition.Kind.MANUAL))
	assert_eq(shop.pack_offers.size(), 1)
	assert_true(shop.buy_pack(0))
	assert_eq(run.stones, 6)
	assert_eq(shop.opening.choices.size(), 3)
	assert_true(shop.pack_offers.is_empty())


func test_prendre_un_manuel_le_monte_et_ferme_le_sceau() -> void:
	var run := _run(10)
	var shop := _shop_with_pack(run, _pack(PackDefinition.Kind.MANUAL))
	shop.buy_pack(0)
	var hand_id: String = (shop.opening.choices[1] as ManualDefinition).hand.id
	assert_true(shop.take(1))
	assert_eq(run.hand_levels.level_of(hand_id), 2)
	assert_null(shop.opening, "1 choix sur 1 : le sceau se ferme")
	assert_eq(run.stones, 6, "choisir est gratuit")


func test_deux_choix_a_prendre() -> void:
	var run := _run(10)
	var shop := _shop_with_pack(run, _pack(PackDefinition.Kind.PILL, 3, 2))
	shop.buy_pack(0)
	assert_true(shop.take(0))
	assert_not_null(shop.opening)
	assert_eq(shop.opening.picks_left, 1)
	assert_true(shop.take(0))
	assert_null(shop.opening)
	assert_eq(run.pills.size(), 2)


func test_carte_ajoutee_au_paquet_avec_un_uid_neuf() -> void:
	var run := RunState.new(DeckState.new(_deck_of(3), _rng()), null, null, null, _economy(10))
	var shop := _shop_with_pack(run, _pack(PackDefinition.Kind.CARD))
	shop.buy_pack(0)
	var data: CardData = shop.opening.choices[0]
	assert_true(shop.take(0))
	var cards := run.cards()
	assert_eq(cards.size(), 4)
	assert_eq(cards.back().data, data)
	assert_eq(cards.back().uid, 3)


func test_artefact_refuse_sans_emplacement_libre() -> void:
	var run := _run(10)
	var catalog := _catalog(4)
	for i: int in 5:
		run.artifacts.append(_artifact("deja_%d" % i, 1))
	var shop := _shop_with_pack(run, _pack(PackDefinition.Kind.ARTIFACT, 2), catalog)
	shop.buy_pack(0)
	assert_false(shop.can_take(0))
	assert_false(shop.take(0))


func test_artefacts_du_sceau_ni_possedes_ni_en_vente() -> void:
	var run := _run(10)
	var catalog := _catalog(3)
	run.artifacts.append(catalog[0])
	var shop := _shop_with_pack(run, _pack(PackDefinition.Kind.ARTIFACT, 2), catalog)
	shop.buy_pack(0)
	for choice: Resource in shop.opening.choices:
		assert_ne(choice, catalog[0])
		assert_false(shop.offers.has(choice))


func test_un_seul_sceau_ouvert_et_passer_le_ferme() -> void:
	var run := _run(20)
	var shop := _shop_with_pack(run, _pack(PackDefinition.Kind.PILL))
	shop.pack_offers.append(_pack(PackDefinition.Kind.MANUAL))
	shop.buy_pack(0)
	assert_false(shop.can_buy_pack(0), "un sceau deja ouvert")
	shop.skip()
	assert_null(shop.opening)
	assert_true(shop.can_buy_pack(0))


## La relance change les offres, pas les sceaux.
func test_relance_garde_les_sceaux() -> void:
	var run := _run(20)
	var pack := _pack(PackDefinition.Kind.PILL)
	var shop := _shop_with_pack(run, pack)
	shop.reroll()
	assert_eq(shop.pack_offers, [pack])


## Sceau ouvert sauvegarde : rouvert avec les memes choix et ce qu'il reste a prendre.
func test_sceau_ouvert_restaure() -> void:
	var run := _run(20)
	var pack := _pack(PackDefinition.Kind.PILL, 3, 2)
	var shop := _shop_with_pack(run, pack)
	shop.buy_pack(0)
	shop.take(0)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(shop.to_dict()))
	var deck := DeckDefinition.new()
	var rules := _rules(1)
	var packs: Array[PackDefinition] = [pack]
	var restored := ShopState.new(run, [] as Array[ArtifactDefinition], _manuals(), _pills(), packs, [] as Array[LegacyDefinition],
		deck, rules, _rng(), saved)
	assert_not_null(restored.opening)
	assert_eq(restored.opening.picks_left, 1)
	assert_eq(_ids_of(restored.opening.choices), _ids_of(shop.opening.choices))


func _ids_of(items: Array) -> Array:
	return items.map(func(item: Resource) -> StringName: return item.id)


func _deck_of(count: int) -> DeckDefinition:
	var deck := DeckDefinition.new()
	for rank: int in range(1, count + 1):
		deck.cards.append(CardData.create(StringName("d%d" % rank), Element.Type.EAU, rank))
	return deck


func _economy(stones: int) -> EconomyRules:
	var economy := EconomyRules.new()
	economy.starting_stones = stones
	return economy
