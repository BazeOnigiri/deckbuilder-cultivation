extends GutTest

const Contrast := preload("res://test/helpers/contrast.gd")
## Boutique en emplacements : une offre par emplacement, achat au clic, message apres un manuel.


func _panel(stones: int) -> Array:
	var content := GameContent.load_default()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var run := content.new_run(rng)
	run.stones = stones
	var shop := content.new_shop(run, rng)
	var panel := ShopPanel.new()
	panel.levels = run.hand_levels
	add_child_autofree(panel)
	panel.open(shop)
	return [panel, shop, run]


func _slots(panel: ShopPanel) -> Array[ItemSlot]:
	var slots: Array[ItemSlot] = []
	for offer: Node in panel._offers.get_children():
		slots.append(offer.find_children("*", "ItemSlot", true, false)[0] as ItemSlot)
	return slots


func test_un_emplacement_par_offre() -> void:
	var parts := _panel(0)
	var shop: ShopState = parts[1]
	var slots := _slots(parts[0])
	assert_eq(slots.size(), shop.offers.size() + shop.manual_offers.size() + shop.pill_offers.size() + shop.pack_offers.size()
		+ (1 if shop.legacy_offer() != null else 0))
	for slot: ItemSlot in slots:
		assert_false(slot.glyph.is_empty())
		assert_true(slot.disabled, "pas de pierres : rien d'achetable")


func test_clic_achete_l_artefact() -> void:
	var parts := _panel(100)
	var panel: ShopPanel = parts[0]
	var run: RunState = parts[2]
	if parts[1].offers.is_empty():
		pass_test("pas d'artefact dans ce tirage")
		return
	var before := run.artifacts.size()
	watch_signals(panel)
	_slots(panel)[0].pressed.emit()
	assert_eq(run.artifacts.size(), before + 1)
	assert_signal_emitted(panel, "changed")


func test_manuel_montre_le_gain_de_niveau() -> void:
	var parts := _panel(100)
	var panel: ShopPanel = parts[0]
	var shop: ShopState = parts[1]
	if shop.manual_offers.is_empty():
		pass_test("pas de manuel dans ce tirage")
		return
	var hand: HandDefinition = shop.manual_offers[0].hand
	_slots(panel)[shop.offers.size()].pressed.emit()
	assert_eq(parts[2].hand_levels.level_of(hand.id), 2)
	assert_eq(panel._level_up.text, tr("UI_SHOP_LEVEL_UP") % [tr(hand.name_key), 2, hand.qi_at(1),
		hand.comprehension_at(1), hand.qi_at(2), hand.comprehension_at(2)])


func test_pavillon_avec_enseigne_et_lanternes() -> void:
	var panel: ShopPanel = _panel(10)[0]
	var pavilion := panel.find_children("*", "ShopPavilion", true, false)
	assert_eq(pavilion.size(), 1)
	var lanterns: Array[Node] = panel.find_children("*", "TextureRect", true, false).filter(
		func(node: Node) -> bool: return (node as TextureRect).texture == ShopPanel.LANTERN)
	assert_eq(lanterns.size(), 2)


func test_lanternes_immobiles_si_on_reduit_les_animations() -> void:
	var panel := ShopPanel.new()
	panel.settings = GameSettings.new()
	panel.settings.reduce_motion = true
	add_child_autofree(panel)
	for node: Node in panel.find_children("*", "TextureRect", true, false):
		assert_eq((node as TextureRect).rotation, 0.0)


## L'enseigne est dessinee avec la police des sceaux : ses caracteres doivent y etre.
func test_enseigne_dans_la_police_des_sceaux() -> void:
	var font: FontFile = load("res://ui/fonts/MaShanZheng-Sceaux.ttf")
	for i: int in ShopPanel.SIGN_GLYPHS.length():
		assert_true(font.has_char(ShopPanel.SIGN_GLYPHS.unicode_at(i)), ShopPanel.SIGN_GLYPHS[i])


func test_prix_lisible_sur_l_etiquette() -> void:
	var theme: Theme = load("res://ui/theme/lavis_de_nuit.tres")
	var tag: StyleBoxFlat = theme.get_stylebox("panel", "PriceTag")
	assert_gt(Contrast.ratio(theme.get_color("font_color", "Price"), tag.bg_color), 4.5)
	var seal: StyleBoxFlat = theme.get_stylebox("normal", "SealButton")
	assert_gt(Contrast.ratio(theme.get_color("font_color", "SealButton"), seal.bg_color), 4.5)


## Bug : un nom d'offre ou un message long elargissait la boutique hors de l'ecran.
func test_largeur_independante_des_textes() -> void:
	var panel: ShopPanel = _panel(0)[0]
	var width := panel.get_combined_minimum_size().x
	var long_text := "Pagode des trois sages immortels ".repeat(6)
	panel._level_up.text = long_text
	for title: Label in panel._offers.find_children("*", "Label", true, false):
		if title.theme_type_variation == &"SideCaption":
			title.text = long_text
	assert_almost_eq(panel.get_combined_minimum_size().x, width, 1.0)


func test_manuel_dessine_en_livre() -> void:
	var parts := _panel(0)
	var shop: ShopState = parts[1]
	if shop.manual_offers.is_empty():
		pass_test("pas de manuel dans ce tirage")
		return
	var manual: ManualDefinition = shop.manual_offers[0]
	var slot := _slots(parts[0])[shop.offers.size()]
	assert_eq(slot.kind, ItemSlot.Kind.MANUAL)
	assert_eq(slot.glyph, manual.glyph)
	assert_eq(slot.cover_tier, manual.tier)
	assert_eq(slot.cover_pattern, manual.pattern)


## Un sceau achete s'ouvre dans un rouleau ; prendre son seul choix le referme.
func test_sceau_ouvert_dans_un_rouleau() -> void:
	var parts := _panel(100)
	var panel: ShopPanel = parts[0]
	var shop: ShopState = parts[1]
	var pack_slot: ItemSlot
	for slot: ItemSlot in _slots(panel):
		if slot.kind == ItemSlot.Kind.PACK:
			pack_slot = slot
	assert_not_null(pack_slot)
	pack_slot.pressed.emit()
	assert_not_null(shop.opening)
	assert_not_null(panel._pack_scroll)
	panel._on_take_pressed(0)
	assert_null(shop.opening)
	assert_null(panel._pack_scroll)
	await wait_process_frames(1)


## Les cartes d'un sceau de disciples ont une infobulle : rang, element, Qi.
func test_carte_du_sceau_avec_infobulle() -> void:
	var card := CardInstance.new(-1, GameContent.load_default().starter_deck.cards[0], GameContent.load_default().starter_deck.ranks)
	var tip := CardView.tip_text(card)
	assert_true(tip.contains(CardView.name_of(card)))
	assert_true(tip.contains(tr("ELEMENT_" + Element.to_id(card.element).to_upper())))
