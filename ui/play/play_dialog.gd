class_name PlayDialog
extends AcceptDialog
## Fenetre Nouvelle partie : onglet pour commencer, onglet Continuer si une run est sauvegardee.

signal new_run_requested
signal continue_requested

const SIZE := Vector2i(560, 380)

var _saved_run: RunState


## saved_run : apercu de la run sauvegardee, null si aucune. A appeler avant add_child.
func setup(saved_run: RunState) -> void:
	_saved_run = saved_run


func _ready() -> void:
	title = tr("UI_NEW_RUN")
	ok_button_text = tr("UI_BACK")
	var tabs := TabContainer.new()
	add_child(tabs)
	tabs.add_child(_new_run_tab())
	tabs.set_tab_title(0, tr("UI_NEW_RUN"))
	if _saved_run != null:
		tabs.add_child(_continue_tab())
		tabs.set_tab_title(1, tr("UI_CONTINUE"))
	confirmed.connect(queue_free)
	canceled.connect(queue_free)


func _new_run_tab() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	if _saved_run != null:
		var warning := Label.new()
		warning.text = tr("UI_NEW_RUN_WARNING")
		warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		warning.custom_minimum_size = Vector2(480, 0)
		box.add_child(warning)
	var button := Button.new()
	button.text = tr("UI_START_RUN")
	button.pressed.connect(new_run_requested.emit)
	box.add_child(button)
	return box


func _continue_tab() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 32)
	var progress := _saved_run.progress
	_row(grid, "UI_SAVED_STAGE", tr("UI_STAGE") % [tr(progress.current_realm().name_key), tr(progress.current_bottleneck().name_key)])
	_row(grid, "UI_SAVED_STONES", str(_saved_run.stones))
	_row(grid, "UI_SAVED_ARTIFACTS", _names(_saved_run.artifacts))
	_row(grid, "UI_SAVED_PILLS", _names(_saved_run.pills))
	_row(grid, "UI_INFO_CLEARED_COUNT", str(_saved_run.stats.bottlenecks_cleared))
	_row(grid, "UI_STATS_HANDS_PLAYED", str(_saved_run.stats.hands.total()))
	box.add_child(grid)
	var button := Button.new()
	button.text = tr("UI_CONTINUE")
	button.pressed.connect(continue_requested.emit)
	box.add_child(button)
	return box


func _row(grid: GridContainer, name_key: String, value: String) -> void:
	var name_label := Label.new()
	name_label.text = tr(name_key)
	var value_label := Label.new()
	value_label.text = value
	grid.add_child(name_label)
	grid.add_child(value_label)


func _names(list: Array) -> String:
	var names: Array[String] = []
	for item: Resource in list:
		names.append(tr(item.name_key))
	return ", ".join(names) if not names.is_empty() else tr("UI_NONE")