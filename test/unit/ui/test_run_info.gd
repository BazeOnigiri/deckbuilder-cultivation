extends GutTest
## Rouleau « Voie de cultivation » : trois signets, une tablette par main, le chemin du royaume en cours.


func _run() -> Array:
	var content := GameContent.load_default()
	return [content.new_run(RandomNumberGenerator.new()), content]


func test_trois_signets() -> void:
	var data := _run()
	var tabs: TabContainer = add_child_autofree(RunInfo.build(data[0], data[1].hands))
	assert_eq(tabs.get_tab_count(), 3)


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
	var lines := path.get_children().filter(func(node: Node) -> bool: return node is HBoxContainer)
	assert_eq(lines.size(), run.progress.current_realm().bottlenecks.size())
	var first: RunInfo.PathNode = lines[-1].get_child(0)
	assert_eq(first.position_state, 0, "le premier goulot, en bas du chemin, est en cours")
	assert_false(first.line_down)
	assert_true(lines[0].get_child(0).line_down, "la tribulation, en haut, est reliee au reste")
