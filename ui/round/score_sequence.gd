class_name ScoreSequence
extends Control
## Rejoue le calcul d'une main jouee, etape par etape : la carte qui compte bondit, lache du qi et son montant s'envole,
## le compteur Qi x Comprehension defile, puis l'ecran tremble et le fond se teinte selon le score.
## Affichage seulement : le score est deja calcule et compte quand la sequence commence.

signal finished

## Parametres globaux de shader declares dans project.godot, lus par le fond lavis.
const PULSE_COLOR := &"pulse_color"
const PULSE_STRENGTH := &"pulse_strength"
const POPUP_OUTLINE_SIZE := 6
const POPUP_OUTLINE_COLOR := Color(0.03, 0.05, 0.07, 0.85)
## Ecart entre le tableau du score et le haut des cartes jouees.
const BOARD_MARGIN := 12.0
const BOARD_WIDTH := 320.0
## Allers-retours du tremblement.
const SHAKES := 6
## Diametre d'une particule de qi, en pixels.
const QI_DOT_SIZE := 12

var feel: ScoreFeel = preload("res://ui/round/score_feel.tres")
var settings: GameSettings = GameSettings.new()
var running: bool = false
## Renvoie le point (global) ou le total s'envole a la fin : le Qi du round de la colonne. Vide : pas d'envol.
var score_target: Callable
## (artefact) -> Vector2 : fait bondir l'emplacement de l'artefact et renvoie ou poser sa popup (INF s'il n'est pas affiche).
## Vide : popup au-dessus du tableau.
var artifact_hit: Callable

var _hand_view: HandView
var _shake_target: Control
var _board: VBoxContainer
var _hand_name: Label
var _tally: Label
var _rng := RandomNumberGenerator.new()
var _shown := Vector2.ZERO
## Point lumineux flou, partage par toutes les particules.
var _qi_texture: GradientTexture2D


## hand_view : la main, dont les cartes jouees bondissent. shake_target : ce qui tremble (le contenu de l'ecran).
func setup(hand_view: HandView, shake_target: Control) -> void:
	_hand_view = hand_view
	_shake_target = shake_target


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	_board = VBoxContainer.new()
	_board.mouse_filter = MOUSE_FILTER_IGNORE
	_hand_name = _board_label()
	_tally = _board_label()
	_tally.add_theme_color_override(&"font_color", feel.comprehension_color)
	add_child(_board)
	_qi_texture = GradientTexture2D.new()
	_qi_texture.width = QI_DOT_SIZE
	_qi_texture.height = QI_DOT_SIZE
	_qi_texture.fill = GradientTexture2D.FILL_RADIAL
	_qi_texture.fill_from = Vector2(0.5, 0.5)
	_qi_texture.fill_to = Vector2(0.5, 0.0)
	_qi_texture.gradient = _fade_out()


func _exit_tree() -> void:
	RenderingServer.global_shader_parameter_set(PULSE_STRENGTH, 0.0)


func play(context: ScoreContext, target_score: int) -> void:
	running = true
	_hand_name.text = tr(context.hand.definition.name_key)
	# Texte en place avant de mesurer le tableau, sinon il grandit par-dessus les cartes.
	_roll_to(context.steps[0])
	_place_board()
	await _wait(feel.start_delay)
	for step: ScoreStep in context.steps:
		match step.kind:
			ScoreStep.Kind.CARD:
				_hand_view.pulse(step.card)
				_burst(_hand_view.card_center(step.card), ElementStyles.of(step.card.element).color)
				_popup(tr("UI_POPUP_QI") % step.card.rank, _hand_view.card_center(step.card), feel.qi_color)
			ScoreStep.Kind.EFFECT:
				_show_effect(step)
		_roll_to(step)
		await _wait(feel.step_delay)
	var total := context.total()
	_tally.text += " " + tr("UI_POPUP_TOTAL") % total
	_shake(clampf(float(total) / maxi(target_score, 1), 0.0, 1.0))
	_pulse_background(context.hand.scoring_cards)
	_fly_total(total)
	await _wait(feel.end_delay)
	_hand_name.text = ""
	_tally.text = ""
	running = false
	finished.emit()


func _show_effect(step: ScoreStep) -> void:
	var amount := String.num(step.effect.amount, 2)
	var text: String = ""
	match step.effect.phase:
		ScoreEffect.Phase.ADD_QI:
			text = tr("UI_POPUP_QI") % roundi(step.effect.amount)
		ScoreEffect.Phase.ADD_COMPREHENSION:
			text = tr("UI_POPUP_COMPREHENSION_ADD") % amount
		ScoreEffect.Phase.MULT_COMPREHENSION:
			text = tr("UI_POPUP_COMPREHENSION_MULT") % amount
	# Le nom de l'artefact : le joueur voit d'ou viennent ses points.
	var artifact := step.source as ArtifactDefinition
	var at := _above_board()
	if artifact != null:
		text = tr(artifact.name_key) + "\n" + text
		if artifact_hit.is_valid():
			var slot: Vector2 = artifact_hit.call(artifact)
			if slot.is_finite():
				at = slot
	if step.card != null:
		_hand_view.pulse(step.card)
		at = _hand_view.card_center(step.card)
		_burst(at, ElementStyles.of(step.card.element).color)
	var color := feel.qi_color if step.effect.phase == ScoreEffect.Phase.ADD_QI else feel.comprehension_color
	_popup(text, at, color)


func _roll_to(step: ScoreStep) -> void:
	var to := Vector2(step.qi, step.comprehension)
	if step.kind == ScoreStep.Kind.BASE or feel.roll_time <= 0.0:
		_set_tally(to)
		return
	create_tween().tween_method(_set_tally, _shown, to, feel.roll_time)


func _set_tally(values: Vector2) -> void:
	_shown = values
	_tally.text = tr("UI_TALLY") % [roundi(values.x), values.y]


func _popup(text: String, at: Vector2, color: Color) -> void:
	if not at.is_finite():
		at = _above_board()
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = MOUSE_FILTER_IGNORE
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_font_size_override(&"font_size", feel.popup_font_size)
	label.add_theme_constant_override(&"outline_size", POPUP_OUTLINE_SIZE)
	label.add_theme_color_override(&"font_outline_color", POPUP_OUTLINE_COLOR)
	add_child(label)
	label.reset_size()
	label.global_position = at - label.size / 2
	# Le nom d'un artefact du bord ne doit pas sortir de l'ecran.
	label.global_position.x = clampf(label.global_position.x, 0.0, maxf(0.0, get_viewport_rect().size.x - label.size.x))
	var tween := label.create_tween().set_parallel()
	if not settings.reduce_motion:
		tween.tween_property(label, "position:y", label.position.y - feel.popup_rise, feel.popup_time)
	tween.tween_property(label, "modulate:a", 0.0, feel.popup_time / 2).set_delay(feel.popup_time / 2)
	tween.chain().tween_callback(label.queue_free)


## Le total quitte le tableau et file vers le Qi du round, qui defile ensuite.
func _fly_total(total: int) -> void:
	if settings.reduce_motion or not score_target.is_valid() or feel.end_delay <= 0.0:
		return
	var label := Label.new()
	label.text = str(total)
	label.mouse_filter = MOUSE_FILTER_IGNORE
	label.add_theme_color_override(&"font_color", feel.comprehension_color)
	label.add_theme_font_size_override(&"font_size", feel.popup_font_size)
	label.add_theme_constant_override(&"outline_size", POPUP_OUTLINE_SIZE)
	label.add_theme_color_override(&"font_outline_color", POPUP_OUTLINE_COLOR)
	add_child(label)
	label.reset_size()
	label.global_position = _board.get_global_rect().get_center() - label.size / 2
	var target: Vector2 = score_target.call() - label.size / 2
	var tween := label.create_tween()
	tween.tween_property(label, "global_position", target, feel.end_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(label.queue_free)


## Gerbe de qi de la couleur de l'element, qui monte et s'eteint.
func _burst(at: Vector2, color: Color) -> void:
	if settings.reduce_motion or not at.is_finite() or feel.particle_amount <= 0:
		return
	var particles := CPUParticles2D.new()
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = feel.particle_amount
	particles.lifetime = feel.particle_lifetime
	particles.texture = _qi_texture
	particles.spread = 180.0
	particles.direction = Vector2.UP
	particles.initial_velocity_min = feel.particle_speed * 0.4
	particles.initial_velocity_max = feel.particle_speed
	# Le qi s'eleve : gravite vers le haut, freinee.
	particles.gravity = Vector2(0, -feel.particle_speed)
	particles.damping_min = feel.particle_speed
	particles.damping_max = feel.particle_speed
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.0
	particles.color = color
	particles.color_ramp = _fade_out()
	add_child(particles)
	particles.global_position = at
	particles.emitting = true
	get_tree().create_timer(feel.particle_lifetime + 0.1).timeout.connect(particles.queue_free)


## Blanc opaque vers transparent : multiplie la couleur, la particule s'efface en vieillissant.
static func _fade_out() -> Gradient:
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1, 1, 1, 0))
	return gradient


## ratio : part de l'objectif du goulot atteinte par cette main seule.
func _shake(ratio: float) -> void:
	var amplitude: float = feel.shake_max * ratio
	if settings.reduce_motion or amplitude < 0.5:
		return
	var origin := _shake_target.position
	var tween := _shake_target.create_tween()
	var step_time: float = feel.shake_time / (SHAKES + 1)
	for i: int in SHAKES:
		var fade: float = 1.0 - float(i) / SHAKES
		var offset := Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * amplitude * fade
		tween.tween_property(_shake_target, "position", origin + offset, step_time)
	tween.tween_property(_shake_target, "position", origin, step_time)


## Le fond prend la couleur de l'element le plus present parmi les cartes qui comptent, puis revient.
func _pulse_background(cards: Array[CardInstance]) -> void:
	if settings.reduce_motion or cards.is_empty():
		return
	var counts: Dictionary[Element.Type, int] = {}
	for card: CardInstance in cards:
		counts[card.element] = counts.get(card.element, 0) + 1
	var dominant: Element.Type = cards[0].element
	for element: Element.Type in counts:
		if counts[element] > counts[dominant]:
			dominant = element
	RenderingServer.global_shader_parameter_set(PULSE_COLOR, ElementStyles.of(dominant).color)
	create_tween().tween_method(_set_pulse, feel.pulse_strength, 0.0, feel.pulse_time)


func _set_pulse(strength: float) -> void:
	RenderingServer.global_shader_parameter_set(PULSE_STRENGTH, strength)


## Le tableau du score se place juste au-dessus de la rangee des cartes jouees.
func _place_board() -> void:
	_board.reset_size()
	var top := _hand_view.played_row_top()
	_board.global_position = Vector2(top.x - _board.size.x / 2, top.y - _board.size.y - BOARD_MARGIN)


## Ou montrer un effet qui ne vient pas d'une carte : au-dessus du tableau, sans cacher le compteur.
func _above_board() -> Vector2:
	var rect := _board.get_global_rect()
	return Vector2(rect.get_center().x, rect.position.y - feel.popup_font_size)


func _board_label() -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size.x = BOARD_WIDTH
	_board.add_child(label)
	return label


func _wait(seconds: float) -> void:
	if seconds > 0.0:
		await get_tree().create_timer(seconds).timeout
