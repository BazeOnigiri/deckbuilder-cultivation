class_name GameHistory
extends RefCounted
## Contenu du rouleau « Historique » : une entree par partie terminee, la plus recente en haut.
## Chaque entree : date, resultat, royaume et goulot atteints, meilleur coup, puis le build final en emplacements.


static func build(profile: ProfileStats, content: GameContent) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(scroll.get_theme_constant(&"info_width", &"ScrollPanel"),
		scroll.get_theme_constant(&"tab_height", &"ScrollPanel"))
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	if profile.games.is_empty():
		column.add_child(SideColumn.make_label(&"ScrollCaption", "UI_HISTORY_EMPTY"))
		return scroll
	for i: int in range(profile.games.size() - 1, -1, -1):
		column.add_child(_entry(profile.games[i], content))
	return scroll


static func _entry(game: GameRecord, content: GameContent) -> VBoxContainer:
	var entry := VBoxContainer.new()
	var header := SideColumn.make_label(&"ScrollText")
	header.text = "%s  -  %s" % [date_text(game.played_at), _tr("UI_HISTORY_WON" if game.won else "UI_HISTORY_LOST")]
	entry.add_child(header)
	entry.add_child(ScrollRows.row("UI_HISTORY_STAGE", stage_text(game.realm_id, game.bottleneck_id, content)))
	entry.add_child(ScrollRows.row("UI_STATS_BEST_HAND_SCORE", best_hand_text(game.best_hand_score, game.best_hand_id, content.hands)))
	entry.add_child(ScrollRows.row("UI_STATS_FAVORITE_HAND", RunInfo.hand_name(game.favorite_hand_id, content.hands)))
	if not game.seed_text.is_empty():
		entry.add_child(ScrollRows.row("UI_HISTORY_SEED", game.seed_text))
	var build := HFlowContainer.new()
	for id: String in game.artifacts:
		_add_slot(build, content.artifact_by_id(StringName(id)))
	for id: String in game.legacies:
		_add_slot(build, content.legacy_by_id(StringName(id)))
	entry.add_child(build)
	entry.add_child(HSeparator.new())
	return entry


static func _add_slot(parent: Control, item: Resource) -> void:
	# Un contenu retire du jeu depuis la partie n'a plus de dessin : il est ignore.
	if item != null:
		parent.add_child(ContentSlots.of(item))


## « Royaume : goulot » depuis les ids. Introuvables (contenu retire) : « aucun ».
static func stage_text(realm_id: String, bottleneck_id: String, content: GameContent) -> String:
	for realm: RealmDefinition in content.realms:
		if String(realm.id) != realm_id:
			continue
		for bottleneck: BottleneckDefinition in realm.bottlenecks:
			if String(bottleneck.id) == bottleneck_id:
				return _tr("UI_STAGE") % [_tr(realm.name_key), _tr(bottleneck.name_key)]
	return _tr("UI_NONE")


## « 1234 (Paire) » : le score du meilleur coup et le nom de sa main.
static func best_hand_text(score: int, hand_id: String, hands: Array[HandDefinition]) -> String:
	if hand_id.is_empty():
		return str(score)
	return "%d (%s)" % [score, RunInfo.hand_name(hand_id, hands)]


## Date locale « 2026-10-29 14:05 ».
static func date_text(unix_time: int) -> String:
	var local := unix_time + int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	return Time.get_datetime_string_from_unix_time(local, true).substr(0, 16)


static func _tr(key: String) -> String:
	return TranslationServer.translate(key)
