class_name RunInfoDialog
extends AcceptDialog
## Fenetre Infos pendant une run : mains, parcours, statistiques. Construite en code, lecture seule.

const SIZE := Vector2i(760, 520)
const POSITION_KEYS := ["UI_INFO_CLEARED", "UI_INFO_CURRENT", "UI_INFO_UPCOMING"]

var _run: RunState
var _hands: Array[HandDefinition]


## A appeler avant add_child.
func setup(run: RunState, hands: Array[HandDefinition]) -> void:
	_run = run
	_hands = hands


func _ready() -> void:
	title = tr("UI_RUN_INFO")
	var tabs := TabContainer.new()
	add_child(tabs)
	_add_tab(tabs, "UI_INFO_TAB_HANDS", _hands_grid())
	_add_tab(tabs, "UI_INFO_TAB_PATH", _path_grid())
	_add_tab(tabs, "UI_INFO_TAB_RUN", _run_grid())
	confirmed.connect(queue_free)
	canceled.connect(queue_free)


func _add_tab(tabs: TabContainer, title_key: String, grid: GridContainer) -> void:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(SIZE) - Vector2(40, 120)
	scroll.add_child(grid)
	tabs.add_child(scroll)
	tabs.set_tab_title(tabs.get_tab_count() - 1, tr(title_key))


func _grid(columns: int, header_keys: Array) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 32)
	grid.add_theme_constant_override("v_separation", 8)
	for key: String in header_keys:
		_cell(grid, tr(key))
	return grid


func _cell(grid: GridContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	grid.add_child(label)


## Les 12 mains, de la plus forte a la plus faible, a leur niveau actuel.
func _hands_grid() -> GridContainer:
	var grid := _grid(4, ["UI_INFO_HAND", "UI_INFO_LEVEL", "UI_INFO_VALUE", "UI_INFO_PLAYED"])
	var sorted: Array[HandDefinition] = _hands.duplicate()
	sorted.sort_custom(func(a: HandDefinition, b: HandDefinition) -> bool: return a.priority > b.priority)
	for hand: HandDefinition in sorted:
		var level: int = _run.hand_levels.level_of(hand.id)
		_cell(grid, tr(hand.name_key))
		_cell(grid, str(level))
		_cell(grid, tr("UI_INFO_VALUE_FORMAT") % [hand.qi_at(level), hand.comprehension_at(level)])
		_cell(grid, str(_run.stats.hands.count_of(hand.id)))
	return grid


## Les goulots du royaume en cours seulement : les royaumes suivants restent une surprise.
func _path_grid() -> GridContainer:
	var realm: RealmDefinition = _run.progress.current_realm()
	var grid := _grid(4, [realm.name_key, "UI_INFO_TARGET", "UI_INFO_CONSTRAINT", "UI_INFO_STATE"])
	for b: int in realm.bottlenecks.size():
		var bottleneck: BottleneckDefinition = realm.bottlenecks[b]
		_cell(grid, tr(bottleneck.name_key))
		_cell(grid, str(RunProgress.target_for(realm, bottleneck)))
		_cell(grid, tr(bottleneck.constraint.description_key) if bottleneck.constraint != null else "")
		_cell(grid, tr(POSITION_KEYS[_run.progress.bottleneck_position(b) + 1]))
	return grid


func _run_grid() -> GridContainer:
	var grid := _grid(2, [])
	var stats := _run.stats
	_cell(grid, tr("UI_STATS_HANDS_PLAYED"))
	_cell(grid, str(stats.hands.total()))
	_cell(grid, tr("UI_STATS_BEST_HAND_SCORE"))
	_cell(grid, str(stats.best_hand_score))
	_cell(grid, tr("UI_STATS_FAVORITE_HAND"))
	_cell(grid, _hand_name(stats.hands.most_played()))
	_cell(grid, tr("UI_INFO_DISCARDS"))
	_cell(grid, str(stats.discards_used))
	_cell(grid, tr("UI_INFO_STONES"))
	_cell(grid, str(stats.stones_earned))
	_cell(grid, tr("UI_INFO_CLEARED_COUNT"))
	_cell(grid, str(stats.bottlenecks_cleared))
	return grid


func _hand_name(hand_id: String) -> String:
	for hand: HandDefinition in _hands:
		if hand.id == hand_id:
			return tr(hand.name_key)
	return tr("UI_NONE")