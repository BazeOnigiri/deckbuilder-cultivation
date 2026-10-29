extends GutTest
## Rouleau « Voie de cultivation » : trois signets, une tablette par main, le chemin du royaume en cours.


func _run() -> Array:
	var content := GameContent.load_default()
	return [content.new_run(RandomNumberGenerator.new()), content]


func test_quatre_signets_dont_les_touches() -> void:
	var data := _run()
	var tabs: TabContainer = add_child_autofree(RunInfo.build(data[0], data[1].hands))
	assert_eq(tabs.get_tab_count(), 4)
	var keys: GridContainer = tabs.get_child(3).get_child(0)
	assert_eq(keys.get_child_count(), Keys.LISTED.size() * 2, "une touche et son texte par action")


func test_une_tablette_par_main_avec_son_niveau() -> void:
	var data := _run()
	var tabs: TabContainer = add_child_autofree(RunInfo.build(data[0], data[1].hands))
	var grid: GridContainer = tabs.get_child(0).get_child(0)
	assert_eq(grid.get_child_count(), data[1].hands.size())
	var pips := grid.find_children("*", "Control", true, false).filter(func(node: Node) -> bool: return node is RunInfo.LevelPips)
	assert_eq(pips.size(), data[1].hands.size())
	assert_eq(pips[0].level, 1)


func test_parcours_du_royaume_en_cours() -> void:
	var data := _run()
	var run: RunState = data[0]
	var tabs: TabContainer = add_child_autofree(RunInfo.build(run, data[1].hands))
	var path: VBoxContainer = tabs.get_child(1).get_child(0)
	var lines := path.get_children().filter(func(node: Node) -> bool:
		return node is HBoxContainer and node.get_child(0) is RunInfo.PathNode)
	assert_eq(lines.size(), run.progress.current_realm().bottlenecks.size())
	var first: RunInfo.PathNode = lines[-1].get_child(0)
	assert_eq(first.position_state, 0, "le premier goulot, en bas du chemin, est en cours")
	assert_false(first.line_down)
	assert_true(lines[0].get_child(0).line_down, "la tribulation, en haut, est reliee au reste")


## Comme Balatro : chaque tablette montre un exemple, les cartes qui ne comptent pas sont pales.
func test_exemple_de_main_en_petites_cartes() -> void:
	var data := _run()
	var tabs: TabContainer = add_child_autofree(RunInfo.build(data[0], data[1].hands))
	var grid: GridContainer = tabs.get_child(0).get_child(0)
	for tablet: Node in grid.get_children():
		var views := tablet.find_children("*", "CardView", true, false)
		assert_eq(views.size(), 5)
	var pair: HandDefinition = load("res://content/hands/main_paire.tres")
	var row := RunInfo._example(pair)
	add_child_autofree(row)
	var pale := 0
	for view: CardView in row.find_children("*", "CardView", true, false):
		if view.modulate != Color.WHITE:
			pale += 1
	assert_eq(pale, 3, "paire : trois cartes ne comptent pas")


## Un heritage possede est un emplacement avec infobulle (nom et description), comme en boutique.
func test_heritages_en_emplacements_avec_infobulle() -> void:
	var data := _run()
	var content: GameContent = data[1]
	var legacies: Array[LegacyDefinition] = [content.legacies[0]]
	var slots := RunInfo.legacy_slots(legacies)
	assert_eq(slots.size(), 1)
	assert_eq(slots[0].kind, ItemSlot.Kind.LEGACY)
	assert_eq(slots[0].title, tr(legacies[0].name_key))
	assert_eq(slots[0].description, tr(legacies[0].description_key))
	(slots[0] as Node).free()


func test_onglet_run_montre_les_heritages_possedes() -> void:
	var data := _run()
	var run: RunState = data[0]
	run.legacies.assign([data[1].legacies[0]])
	var tabs: TabContainer = add_child_autofree(RunInfo.build(run, data[1].hands))
	var found := tabs.get_child(2).find_children("*", "ItemSlot", true, false)
	assert_eq(found.size(), 1)
