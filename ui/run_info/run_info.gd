class_name RunInfo
extends RefCounted
## Contenu du rouleau « Voie de cultivation » pendant une run : onglets en signets Mains, Parcours, Run. Lecture seule.

const POSITION_KEYS := ["UI_INFO_CLEARED", "UI_INFO_CURRENT", "UI_INFO_UPCOMING"]
## Sceau pose a cote d'un goulot franchi (decoratif, police des sceaux).
const CLEARED_GLYPH := "破"


static func build(run: RunState, hands: Array[HandDefinition]) -> TabContainer:
	var tabs := TabContainer.new()
	tabs.theme_type_variation = &"ScrollTabs"
	_add_tab(tabs, "UI_INFO_TAB_HANDS", _hands_grid(run, hands))
	_add_tab(tabs, "UI_INFO_TAB_PATH", _path(run))
	_add_tab(tabs, "UI_INFO_TAB_RUN", _run_rows(run, hands))
	return tabs


static func _add_tab(tabs: TabContainer, title_key: String, content: Control) -> void:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(tabs.get_theme_constant(&"text_width", &"ScrollPanel") * 1.6,
		tabs.get_theme_constant(&"tab_height", &"ScrollPanel"))
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	tabs.add_child(scroll)
	tabs.set_tab_title(tabs.get_tab_count() - 1, tr_key(title_key))


static func tr_key(key: String) -> String:
	return TranslationServer.translate(key)


static func _cell(grid: GridContainer, text: String, type: StringName = &"ScrollText") -> Label:
	var label := SideColumn.make_label(type)
	label.text = text
	grid.add_child(label)
	return label


## Les mains, de la plus forte a la plus faible, a leur niveau actuel.
static func _hands_grid(run: RunState, hands: Array[HandDefinition]) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override(&"h_separation", 32)
	for key: String in ["UI_INFO_HAND", "UI_INFO_LEVEL", "UI_INFO_VALUE", "UI_INFO_PLAYED"]:
		_cell(grid, tr_key(key), &"ScrollCaption")
	var sorted: Array[HandDefinition] = hands.duplicate()
	sorted.sort_custom(func(a: HandDefinition, b: HandDefinition) -> bool: return a.priority > b.priority)
	for hand: HandDefinition in sorted:
		var level: int = run.hand_levels.level_of(hand.id)
		_cell(grid, tr_key(hand.name_key))
		_cell(grid, str(level))
		_cell(grid, tr_key("UI_INFO_VALUE_FORMAT") % [hand.qi_at(level), hand.comprehension_at(level)])
		_cell(grid, str(run.stats.hands.count_of(hand.id)))
	return grid


## Les goulots du royaume en cours seulement : les royaumes suivants restent une surprise.
static func _path(run: RunState) -> VBoxContainer:
	var realm: RealmDefinition = run.progress.current_realm()
	var path := VBoxContainer.new()
	var title := SideColumn.make_label(&"ScrollTitle", realm.name_key)
	path.add_child(title)
	for b: int in realm.bottlenecks.size():
		var bottleneck: BottleneckDefinition = realm.bottlenecks[b]
		var position: int = run.progress.bottleneck_position(b)
		var glyph := SideColumn.make_label(&"PathSeal")
		glyph.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		glyph.text = CLEARED_GLYPH if position < 0 else ""
		var state := SideColumn.make_label(&"ScrollCaption", POSITION_KEYS[position + 1])
		var extra: Array[Control] = [state, glyph]
		var line := ScrollRows.row(bottleneck.name_key, tr_key("UI_INFO_TARGET") + " " + str(RunProgress.target_for(realm, bottleneck)), extra)
		path.add_child(line)
		if bottleneck.constraint != null:
			var constraint := SideColumn.make_label(&"ScrollWarning", bottleneck.constraint.description_key)
			constraint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			path.add_child(constraint)
	return path


static func _run_rows(run: RunState, hands: Array[HandDefinition]) -> VBoxContainer:
	var rows := VBoxContainer.new()
	var stats := run.stats
	rows.add_child(ScrollRows.row("UI_STATS_HANDS_PLAYED", str(stats.hands.total())))
	rows.add_child(ScrollRows.row("UI_STATS_BEST_HAND_SCORE", str(stats.best_hand_score)))
	rows.add_child(ScrollRows.row("UI_STATS_FAVORITE_HAND", hand_name(stats.hands.most_played(), hands)))
	rows.add_child(ScrollRows.row("UI_INFO_DISCARDS", str(stats.discards_used)))
	rows.add_child(ScrollRows.row("UI_INFO_STONES", str(stats.stones_earned)))
	rows.add_child(ScrollRows.row("UI_INFO_CLEARED_COUNT", str(stats.bottlenecks_cleared)))
	return rows


static func hand_name(hand_id: String, hands: Array[HandDefinition]) -> String:
	for hand: HandDefinition in hands:
		if hand.id == hand_id:
			return tr_key(hand.name_key)
	return tr_key("UI_NONE")
