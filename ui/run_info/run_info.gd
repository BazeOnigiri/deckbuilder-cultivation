class_name RunInfo
extends RefCounted
## Contenu du rouleau « Voie de cultivation » pendant une run : onglets en signets Mains, Parcours, Run. Lecture seule.
## Mains : une tablette de jade par main. Parcours : le chemin du royaume, de bas en haut. Run : tuiles de chiffres.
## Touches : les actions du clavier et leur touche.

const POSITION_KEYS := ["UI_INFO_CLEARED", "UI_INFO_CURRENT", "UI_INFO_UPCOMING"]
## Sceau pose sur un goulot franchi (decoratif, police des sceaux).
const CLEARED_GLYPH := "破"
const MEDITANT := preload("res://ui/round/meditant.svg")
const HAND_COLUMNS := 3


static func build(run: RunState, hands: Array[HandDefinition]) -> TabContainer:
	var tabs := TabContainer.new()
	tabs.theme_type_variation = &"ScrollTabs"
	_add_tab(tabs, "UI_INFO_TAB_HANDS", _hand_tablets(run, hands))
	_add_tab(tabs, "UI_INFO_TAB_PATH", _path(run))
	_add_tab(tabs, "UI_INFO_TAB_RUN", _run_tiles(run, hands))
	_add_tab(tabs, "UI_INFO_TAB_KEYS", _keys())
	return tabs


## Une ligne par action : touche en pastille, puis ce qu'elle fait.
static func _keys() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	for entry: Array in Keys.LISTED:
		var key := SideColumn.make_label(&"KeyCap")
		key.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		key.text = Keys.name_of(entry[0])
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid.add_child(key)
		var text := SideColumn.make_label(&"ScrollText")
		text.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		text.text = Keys.text_of(entry[1])
		grid.add_child(text)
	return grid


static func _add_tab(tabs: TabContainer, title_key: String, content: Control) -> void:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(tabs.get_theme_constant(&"info_width", &"ScrollPanel"),
		tabs.get_theme_constant(&"tab_height", &"ScrollPanel"))
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	tabs.add_child(scroll)
	tabs.set_tab_title(tabs.get_tab_count() - 1, tr_key(title_key))


static func tr_key(key: String) -> String:
	return TranslationServer.translate(key)


## Les mains, de la plus forte a la plus faible, a leur niveau actuel.
static func _hand_tablets(run: RunState, hands: Array[HandDefinition]) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = HAND_COLUMNS
	var sorted: Array[HandDefinition] = hands.duplicate()
	sorted.sort_custom(func(a: HandDefinition, b: HandDefinition) -> bool: return a.priority > b.priority)
	for hand: HandDefinition in sorted:
		grid.add_child(_tablet(hand, run.hand_levels.level_of(hand.id), run.stats.hands.count_of(hand.id)))
	return grid


## Nom, pastilles de niveau, Qi x Comprehension en pilules jade et or, nombre de fois jouee.
static func _tablet(hand: HandDefinition, level: int, played: int) -> PanelContainer:
	var tablet := PanelContainer.new()
	tablet.theme_type_variation = &"HandTablet"
	tablet.custom_minimum_size.x = tablet.get_theme_constant(&"width", &"HandTablet")
	var column := VBoxContainer.new()
	column.add_child(SideColumn.make_label(&"ScrollText", hand.name_key))
	column.add_child(_example(hand))
	var pips := LevelPips.new()
	pips.level = level
	pips.tooltip_text = tr_key("UI_INFO_LEVEL_N") % level
	column.add_child(pips)
	var value := HBoxContainer.new()
	var qi := SideColumn.make_label(&"QiPill")
	qi.text = str(hand.qi_at(level))
	value.add_child(qi)
	value.add_child(SideColumn.make_label(&"ScrollCaption", "UI_INFO_TIMES"))
	var comprehension := SideColumn.make_label(&"ComprehensionPill")
	comprehension.text = str(hand.comprehension_at(level))
	value.add_child(comprehension)
	column.add_child(value)
	var count := SideColumn.make_label(&"ScrollCaption")
	count.text = tr_key("UI_INFO_PLAYED_COUNT") % played
	column.add_child(count)
	tablet.add_child(column)
	return tablet


## Exemple de la main en petites cartes, comme Balatro : celles qui comptent en pleine couleur, les autres pales.
static func _example(hand: HandDefinition) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", row.get_theme_constant(&"card_gap", &"HandTablet"))
	var cards := hand.example_cards()
	var scoring := hand.detector.detect(cards)
	var card_scale: float = row.get_theme_constant(&"card_percent", &"HandTablet") / 100.0
	var unused := row.get_theme_color(&"unused_card", &"HandTablet")
	for card: CardInstance in cards:
		row.add_child(CardView.small(card, card_scale, Color.WHITE if scoring.has(card) else unused))
	return row


## Les goulots du royaume en cours seulement, la tribulation en haut : les royaumes suivants restent une surprise.
static func _path(run: RunState) -> VBoxContainer:
	var realm: RealmDefinition = run.progress.current_realm()
	var path := VBoxContainer.new()
	path.add_theme_constant_override(&"separation", 0)
	var title := SideColumn.make_label(&"ScrollTitle", realm.name_key)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	path.add_child(title)
	var last: int = realm.bottlenecks.size() - 1
	for b: int in range(last, -1, -1):
		var bottleneck: BottleneckDefinition = realm.bottlenecks[b]
		var position: int = run.progress.bottleneck_position(b)
		var line := HBoxContainer.new()
		var node := PathNode.new()
		node.position_state = position
		node.line_up = b < last
		node.line_down = b > 0
		line.add_child(node)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var state := SideColumn.make_label(&"ScrollCaption", POSITION_KEYS[position + 1])
		var extra: Array[Control] = [state]
		text.add_child(ScrollRows.row(bottleneck.name_key, tr_key("UI_INFO_TARGET_N") % RunProgress.target_for(realm, bottleneck), extra))
		if bottleneck.constraint != null:
			var constraint := SideColumn.make_label(&"ScrollWarning", bottleneck.constraint.description_key)
			constraint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			text.add_child(constraint)
		line.add_child(text)
		path.add_child(line)
	return path


static func _run_tiles(run: RunState, hands: Array[HandDefinition]) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", column.get_theme_constant(&"separation", &"ScrollPanel"))
	var tiles := HFlowContainer.new()
	var stats := run.stats
	tiles.add_child(ScrollTiles.stat(str(stats.bottlenecks_cleared), "UI_INFO_CLEARED_COUNT", CLEARED_GLYPH))
	tiles.add_child(ScrollTiles.stat(str(stats.hands.total()), "UI_STATS_HANDS_PLAYED"))
	tiles.add_child(ScrollTiles.stat(str(stats.best_hand_score), "UI_STATS_BEST_HAND_SCORE"))
	tiles.add_child(ScrollTiles.stat(str(stats.discards_used), "UI_INFO_DISCARDS"))
	tiles.add_child(ScrollTiles.stat(str(stats.stones_earned), "UI_INFO_STONES"))
	column.add_child(tiles)
	column.add_child(ScrollRows.row("UI_STATS_FAVORITE_HAND", hand_name(stats.hands.most_played(), hands)))
	column.add_child(ScrollRows.row("UI_INFO_LEGACIES", "" if not run.legacies.is_empty() else tr_key("UI_NONE")))
	if not run.legacies.is_empty():
		var slots := HFlowContainer.new()
		for slot: ItemSlot in legacy_slots(run.legacies):
			slots.add_child(slot)
		column.add_child(slots)
	return column


## Un emplacement par heritage, avec son infobulle (nom et description), comme en boutique.
static func legacy_slots(legacies: Array[LegacyDefinition]) -> Array[ItemSlot]:
	var slots: Array[ItemSlot] = []
	for legacy: LegacyDefinition in legacies:
		var slot := ItemSlot.new()
		slot.kind = ItemSlot.Kind.LEGACY
		slot.glyph = legacy.glyph
		slot.set_info(tr_key(legacy.name_key), tr_key(legacy.description_key))
		slots.append(slot)
	return slots


static func hand_name(hand_id: String, hands: Array[HandDefinition]) -> String:
	for hand: HandDefinition in hands:
		if hand.id == hand_id:
			return tr_key(hand.name_key)
	return tr_key("UI_NONE")


## Une pastille par niveau, pleine jusqu'au niveau atteint (le nombre exact est dans l'infobulle).
class LevelPips extends Control:
	var level: int = 1

	func _ready() -> void:
		var radius: float = get_theme_constant(&"pip_radius", &"HandTablet")
		custom_minimum_size.y = radius * 2 + 2

	func _draw() -> void:
		var radius: float = get_theme_constant(&"pip_radius", &"HandTablet")
		var gap: float = get_theme_constant(&"pip_gap", &"HandTablet")
		var count: int = get_theme_constant(&"pip_max", &"HandTablet")
		for i: int in count:
			var color := get_theme_color(&"pip_on" if i < level else &"pip_off", &"HandTablet")
			draw_circle(Vector2(radius + i * (radius * 2 + gap), size.y / 2), radius, color)
		# Au-dela de pip_max les pastilles ne disent plus rien : le niveau exact suit en chiffres.
		if level > count:
			var font := get_theme_font(&"font", &"ScrollCaption")
			var font_size := get_theme_font_size(&"font_size", &"ScrollCaption")
			draw_string(font, Vector2(count * (radius * 2 + gap) + gap, size.y / 2 + font.get_ascent(font_size) / 2),
				str(level), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, get_theme_color(&"pip_on", &"HandTablet"))


## Etape du chemin : rond vide a venir, meditant sur le goulot en cours, sceau 破 sur un goulot franchi.
## Le trait relie les etapes voisines.
class PathNode extends Control:
	## -1 franchi, 0 en cours, 1 a venir (RunProgress.bottleneck_position).
	var position_state: int = 1
	var line_up: bool = false
	var line_down: bool = false

	func _ready() -> void:
		var marker: float = get_theme_constant(&"marker_size", &"PathNode")
		custom_minimum_size = Vector2(marker, marker * get_theme_constant(&"height_percent", &"PathNode") / 100.0)
		size_flags_vertical = Control.SIZE_FILL
		var rect := Rect2(Vector2.ZERO, Vector2(marker, marker))
		if position_state < 0:
			var seal := SideColumn.make_label(&"PathSeal")
			seal.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
			seal.text = CLEARED_GLYPH
			seal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			seal.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			add_child(seal)
			seal.position = rect.position
			seal.size = rect.size
		elif position_state == 0:
			var meditant := TextureRect.new()
			meditant.texture = MEDITANT
			meditant.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			meditant.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			add_child(meditant)
			var inset: float = get_theme_constant(&"meditant_inset_percent", &"PathNode") / 100.0
			meditant.position = rect.position + rect.size * inset
			meditant.size = rect.size * (1.0 - 2.0 * inset)

	func _draw() -> void:
		var marker: float = get_theme_constant(&"marker_size", &"PathNode")
		var width: float = get_theme_constant(&"line_width", &"PathNode")
		var center := Vector2(size.x / 2, marker / 2)
		var radius := marker / 2 - width
		var line := get_theme_color(&"line", &"PathNode")
		var arc_points: int = get_theme_constant(&"arc_points", &"PathNode")
		if line_up:
			draw_line(Vector2(center.x, 0), center - Vector2(0, radius), line, width)
		if line_down:
			draw_line(center + Vector2(0, radius), Vector2(center.x, size.y), line, width)
		match position_state:
			-1:
				draw_arc(center, radius, 0, TAU, arc_points, get_theme_color(&"cleared", &"PathNode"), width, true)
			0:
				draw_circle(center, radius, get_theme_color(&"current", &"PathNode"))
			_:
				draw_arc(center, radius, 0, TAU, arc_points, get_theme_color(&"upcoming", &"PathNode"), width, true)
