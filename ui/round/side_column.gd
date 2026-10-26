class_name SideColumn
extends PanelContainer
## Colonne de droite de l'ecran de round : goulot, objectif, Qi du round, apercu de la main, compteurs.
## Affichage seulement : round_screen lui passe l'etat. Apparence dans le Theme (types Side*, BossBanner, StatBox).

signal path_requested
signal options_requested

## Le Qi du round defile au meme rythme que le compteur de la sequence.
var feel: ScoreFeel = preload("res://ui/round/score_feel.tres")
var settings: GameSettings = GameSettings.new()

var _banner := PanelContainer.new()
var _stage := make_label(&"SideTitle")
var _constraint := make_label(&"SideCaption")
var _ring := GoalRing.new()
var _target := make_label(&"SideTarget")
var _round_qi := make_label(&"SideValue")
var _hand_name := make_label(&"SideTitle")
var _hand_level := make_label(&"SideCaption")
var _qi := make_label(&"QiValue")
var _comprehension := make_label(&"ComprehensionValue")
var _hands := make_label(&"SideValue")
var _discards := make_label(&"SideValue")
var _stones := make_label(&"SideValue")
var _realm := make_label(&"SideValue")
var _bottleneck := make_label(&"SideValue")
## Score affiche par le compteur et l'anneau, qui rattrape le vrai score.
var _shown_score: int = 0
var _target_score: int = 0
var _roll: Tween
## Le bandeau scintille pendant une tribulation.
var _flicker: Tween


func _ready() -> void:
	theme_type_variation = &"SidePanel"
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override(&"separation", get_theme_constant(&"separation", &"SidePanel"))
	add_child(layout)

	# Noms longs (tribulations) : retour a la ligne plutot qu'une colonne qui deborde de l'ecran.
	_stage.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_constraint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hand_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var banner_text := VBoxContainer.new()
	banner_text.add_child(_stage)
	banner_text.add_child(_constraint)
	_banner.add_child(banner_text)
	layout.add_child(_banner)

	var goal := HBoxContainer.new()
	goal.add_child(_ring)
	var goal_text := VBoxContainer.new()
	goal_text.alignment = BoxContainer.ALIGNMENT_CENTER
	goal_text.add_child(make_label(&"SideCaption", "UI_SIDE_TARGET"))
	goal_text.add_child(_target)
	goal_text.add_child(make_label(&"SideCaption", "UI_SIDE_TO_WIN"))
	goal.add_child(goal_text)
	layout.add_child(goal)

	layout.add_child(_row(make_label(&"SideCaption", "UI_SIDE_ROUND_QI"), _round_qi))

	var preview := VBoxContainer.new()
	preview.add_child(_row(_hand_name, _hand_level))
	var values := HBoxContainer.new()
	values.add_child(_stat_box(_qi, "UI_SIDE_QI"))
	values.add_child(make_label(&"SideTitle", "x"))
	values.add_child(_stat_box(_comprehension, "UI_SIDE_COMPREHENSION"))
	preview.add_child(values)
	layout.add_child(preview)

	var round_counters := HBoxContainer.new()
	round_counters.add_child(_stat_box(_hands, "UI_SIDE_HANDS"))
	round_counters.add_child(_stat_box(_discards, "UI_SIDE_DISCARDS"))
	round_counters.add_child(_stat_box(_stones, "UI_SIDE_STONES"))
	layout.add_child(round_counters)
	var path_counters := HBoxContainer.new()
	path_counters.add_child(_stat_box(_realm, "UI_SIDE_REALM"))
	path_counters.add_child(_stat_box(_bottleneck, "UI_SIDE_BOTTLENECK"))
	layout.add_child(path_counters)

	var spacer := Control.new()
	spacer.size_flags_vertical = SIZE_EXPAND_FILL
	layout.add_child(spacer)
	var buttons := HBoxContainer.new()
	buttons.add_child(_button("UI_SIDE_PATH", path_requested))
	buttons.add_child(_button("UI_OPTIONS_BUTTON", options_requested))
	layout.add_child(buttons)
	show_preview(null, 1)


## Goulot fige au debut du round par round_screen (la progression avance des la victoire).
func show_stage(realm: RealmDefinition, bottleneck: BottleneckDefinition) -> void:
	_stage.text = tr("UI_STAGE") % [tr(realm.name_key), tr(bottleneck.name_key)]
	var constraint := bottleneck.constraint
	_constraint.text = tr(constraint.description_key) if constraint != null else ""
	_constraint.visible = constraint != null
	_banner.theme_type_variation = &"BossBanner" if constraint != null else &"StageBanner"
	if _flicker != null:
		_flicker.kill()
	_banner.modulate = Color.WHITE
	if constraint != null and not settings.reduce_motion and feel.banner_flicker_time > 0.0:
		_flicker = create_tween().set_loops()
		_flicker.tween_property(_banner, "modulate", feel.banner_flicker_color, feel.banner_flicker_time).set_trans(Tween.TRANS_SINE)
		_flicker.tween_property(_banner, "modulate", Color.WHITE, feel.banner_flicker_time).set_trans(Tween.TRANS_SINE)


## round null : boutique, pas de round en cours.
func show_run(run: RunState, round_state: RoundState) -> void:
	_stones.text = str(run.stones)
	_realm.text = tr("UI_SIDE_OF") % [run.progress.realm_number(), run.progress.realm_count()]
	_bottleneck.text = tr("UI_SIDE_OF") % [run.progress.bottleneck_number(), run.progress.current_realm().bottlenecks.size()]
	if round_state == null:
		return
	_hands.text = str(round_state.hands_left)
	_discards.text = str(round_state.discards_left)
	_target.text = str(round_state.target_score)
	if round_state.target_score != _target_score or round_state.score < _shown_score:
		# Nouveau round : le compteur repart de zero sans defiler.
		_target_score = round_state.target_score
		_set_shown_score(round_state.score)
	elif round_state.score != _shown_score:
		_roll_to(round_state.score)


## result null : rien de selectionne (ou selection refusee).
func show_preview(result: HandResult, level: int) -> void:
	if result == null:
		_hand_name.text = tr("UI_SIDE_NO_HAND")
		_hand_level.text = ""
		_qi.text = "-"
		_comprehension.text = "-"
		return
	_hand_name.text = tr(result.definition.name_key)
	_hand_level.text = tr("UI_SIDE_LEVEL") % level
	_qi.text = str(result.definition.qi_at(level))
	_comprehension.text = str(result.definition.comprehension_at(level))


## Ou tombent les cristaux des pierres gagnees.
func stones_center() -> Vector2:
	return _stones.get_global_rect().get_center()


## Le compteur de pierres saute quand les cristaux arrivent.
func bump_stones(peak: float) -> void:
	_stones.pivot_offset = _stones.size / 2
	var tween := _stones.create_tween()
	tween.tween_property(_stones, "scale", Vector2.ONE * peak, 0.08)
	tween.tween_property(_stones, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Ou le total d'un coup s'envole a la fin de la sequence.
func round_qi_center() -> Vector2:
	return _round_qi.get_global_rect().get_center()


func _roll_to(score: int) -> void:
	if _roll != null:
		_roll.kill()
	if settings.reduce_motion or feel.roll_time <= 0.0:
		_set_shown_score(score)
		return
	_roll = create_tween()
	_roll.tween_method(_set_shown_score, _shown_score, score, feel.roll_time)


func _set_shown_score(score: int) -> void:
	_shown_score = score
	_round_qi.text = str(score)
	_ring.ratio = clampf(float(score) / maxi(_target_score, 1), 0.0, 1.0)


func _row(left: Control, right: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	left.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(left)
	row.add_child(right)
	return row


## Une valeur dans un encadre, avec sa legende dessous.
func _stat_box(value: Label, caption_key: String) -> PanelContainer:
	var box := PanelContainer.new()
	box.theme_type_variation = &"StatBox"
	box.size_flags_horizontal = SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(value)
	var caption := make_label(&"SideCaption", caption_key)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(caption)
	box.add_child(column)
	return box


func _button(text_key: String, pressed: Signal) -> Button:
	var button := Button.new()
	button.text = text_key
	button.size_flags_horizontal = SIZE_EXPAND_FILL
	button.pressed.connect(pressed.emit)
	return button


static func make_label(type: StringName, text_key: String = "") -> Label:
	var label := Label.new()
	label.theme_type_variation = type
	label.text = text_key
	return label


## Anneau qui se remplit avec le score du round. Taille et couleurs : type GoalRing du Theme.
class GoalRing extends Control:
	var ratio: float = 0.0:
		set(value):
			ratio = value
			queue_redraw()

	func _ready() -> void:
		custom_minimum_size = Vector2.ONE * get_theme_constant(&"size", &"GoalRing")

	func _draw() -> void:
		var width: float = get_theme_constant(&"width", &"GoalRing")
		var radius: float = minf(size.x, size.y) / 2 - width
		var center := size / 2
		draw_arc(center, radius, 0.0, TAU, 64, get_theme_color(&"track", &"GoalRing"), width, true)
		if ratio > 0.0:
			# Part du haut, dans le sens des aiguilles d'une montre.
			draw_arc(center, radius, -PI / 2, -PI / 2 + TAU * ratio, 64, get_theme_color(&"fill", &"GoalRing"), width, true)
