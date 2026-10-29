extends GutTest
## Compendium : un onglet par categorie, un emplacement par contenu, les jamais vus en silhouette.

const SCREEN := preload("res://ui/compendium/compendium_screen.tscn")

var _content: GameContent


func before_all() -> void:
	_content = GameContent.load_default()


func _screen(profile: ProfileStats) -> Control:
	var screen := SCREEN.instantiate()
	screen.profile = profile
	screen.content = _content
	screen.settings = GameSettings.new()
	screen.settings.reduce_motion = true
	return add_child_autofree(screen)


func _slots(screen: Control, tab: int) -> Array[ItemSlot]:
	var slots: Array[ItemSlot] = []
	slots.assign(screen.get_node("%Tabs").get_child(tab).find_children("*", "ItemSlot", true, false))
	return slots


func test_un_onglet_par_categorie_avec_tous_les_contenus() -> void:
	var screen := _screen(ProfileStats.new())
	var tabs: TabContainer = screen.get_node("%Tabs")
	assert_eq(tabs.get_tab_count(), Compendium.Kind.size())
	assert_eq(_slots(screen, Compendium.Kind.ARTIFACT).size(), _content.artifacts.size())
	assert_eq(_slots(screen, Compendium.Kind.PACK).size(), _content.packs.size())
	assert_gt(_slots(screen, Compendium.Kind.TRIBULATION).size(), 0)


func test_tout_est_masque_sans_profil() -> void:
	var screen := _screen(ProfileStats.new())
	for slot: ItemSlot in _slots(screen, Compendium.Kind.ARTIFACT):
		assert_eq(slot.glyph, ContentSlots.HIDDEN_GLYPH)
		assert_eq(slot.title, tr("UI_COMPENDIUM_UNKNOWN"))
		assert_true(slot.disabled)


func test_un_contenu_vu_est_revele_avec_son_prix() -> void:
	var profile := ProfileStats.new()
	var artifact := _content.artifacts[1]
	profile.mark_seen("artifact", artifact.id)
	var slots := _slots(_screen(profile), Compendium.Kind.ARTIFACT)
	assert_eq(slots[1].title, tr(artifact.name_key))
	assert_string_contains(slots[1].description, tr("UI_COMPENDIUM_PRICE") % artifact.price)
	assert_eq(slots[1].rarity, artifact.rarity)
	assert_eq(slots[0].glyph, ContentSlots.HIDDEN_GLYPH, "les autres restent masques")


func test_compteur_vus_sur_total() -> void:
	var profile := ProfileStats.new()
	profile.mark_seen("pill", _content.pills[0].id)
	var screen := _screen(profile)
	var page: Control = screen.get_node("%Tabs").get_child(Compendium.Kind.PILL).get_child(0)
	var counter: Label = page.get_child(0)
	assert_eq(counter.text, tr("UI_COMPENDIUM_SEEN") % [1, _content.pills.size()])


func test_tribulation_revelee_montre_sa_contrainte() -> void:
	var profile := ProfileStats.new()
	var tribulation := Compendium.new(_content, profile).entries(Compendium.Kind.TRIBULATION)[0] as BottleneckDefinition
	profile.mark_seen("tribulation", tribulation.id)
	var slot := _slots(_screen(profile), Compendium.Kind.TRIBULATION)[0]
	assert_eq(slot.kind, ItemSlot.Kind.TRIBULATION)
	assert_eq(slot.description, tr(tribulation.constraint.description_key))


func test_retour() -> void:
	var screen := _screen(ProfileStats.new())
	watch_signals(screen)
	screen.get_node("%BackButton").pressed.emit()
	assert_signal_emitted(screen, "back_requested")


func test_le_menu_ouvre_le_compendium() -> void:
	var menu := preload("res://ui/menu/menu_screen.tscn").instantiate()
	menu.settings = GameSettings.new()
	add_child_autofree(menu)
	watch_signals(menu)
	menu.get_node("%CompendiumButton").pressed.emit()
	assert_signal_emitted(menu, "compendium_requested")
