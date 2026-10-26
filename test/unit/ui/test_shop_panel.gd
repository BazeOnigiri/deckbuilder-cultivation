extends GutTest
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
		slots.append(offer.get_child(0) as ItemSlot)
	return slots


func test_un_emplacement_par_offre() -> void:
	var parts := _panel(0)
	var shop: ShopState = parts[1]
	var slots := _slots(parts[0])
	assert_eq(slots.size(), shop.offers.size() + shop.manual_offers.size() + shop.pill_offers.size())
	for slot: ItemSlot in slots:
		assert_false(slot.glyph.is_empty())
		assert_true(slot.disabled, "pas de pierres : rien d'achetable")


func test_clic_achete_l_artefact() -> void:
	var parts := _panel(100)
	var panel: ShopPanel = parts[0]
	var run: RunState = parts[2]
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
