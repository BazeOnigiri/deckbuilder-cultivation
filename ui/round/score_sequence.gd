class_name ScoreSequence
extends Control
## Rejoue le calcul d'une main jouee, etape par etape, sans texte : la source (carte, artefact) s'allume, une orbe
## de qi file vers la case Qi (jade) ou Comprehension (or) de la colonne, qui defile et s'eclaire a l'arrivee.
## Puis l'ecran tremble et le fond se teinte.
## Affichage seulement : le score est deja calcule et compte quand la sequence commence.

signal finished
## La main jouee : la colonne affiche son nom a la place de l'apercu.
signal hand_named(definition: HandDefinition)
## Chaque etape du compteur qui defile.
signal tally_changed(qi: int, comprehension: float)
## Une orbe arrive dans sa case : la colonne l'eclaire (anneau en plus pour une multiplication).
signal value_hit(phase: ScoreEffect.Phase)

## Parametres globaux de shader declares dans project.godot, lus par le fond lavis.
const PULSE_COLOR := &"pulse_color"
const PULSE_STRENGTH := &"pulse_strength"
const TOTAL_OUTLINE_SIZE := 6
const TOTAL_OUTLINE_COLOR := Color(0.03, 0.05, 0.07, 0.85)
## Trainee d'une orbe : particules par seconde de vol et duree de vie.
const TRAIL_AMOUNT := 60
const TRAIL_LIFETIME := 0.25
## Ecart entre le sceau d'annonce et le haut des cartes jouees.
const ANNOUNCE_MARGIN := 12.0
## Allers-retours du tremblement.
const SHAKES := 6
## Diametre d'une particule de qi, en pixels.
const QI_DOT_SIZE := 12

var feel: ScoreFeel = preload("res://ui/round/score_feel.tres")
var settings: GameSettings = GameSettings.new()
var running: bool = false
## Renvoie le point (global) ou le total s'envole a la fin : le Qi du round de la colonne. Vide : pas d'envol.
var score_target: Callable
## Renvoie le point (global) d'ou part le total : les cases Qi x Comprehension de la colonne. Vide : pas d'envol.
var tally_origin: Callable
## (artefact) -> Vector2 : fait bondir et luire l'emplacement de l'artefact, renvoie son centre (INF s'il n'est pas affiche).
## Vide : l'orbe part du dessus des cartes jouees.
var artifact_hit: Callable
## Centres (globaux) des cases Qi et Comprehension, ou filent les orbes. Vides : pas de vol.
var qi_target: Callable
var comprehension_target: Callable

var _hand_view: HandView
var _shake_target: Control
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
	hand_named.emit(context.hand.definition)
	_roll_to(context.steps[0])
	_announce(tr(context.hand.definition.name_key))
	Sons.play(&"annonce_main")
	await _wait(feel.start_delay + feel.announce_time)
	# Chaque note monte d'un cran dans la gamme : la main se lit comme une phrase qui grimpe.
	var note: int = 0
	for step: ScoreStep in context.steps:
		# La base de la main est deja affichee par le _roll_to du depart : rien ne vole.
		if step.kind == ScoreStep.Kind.BASE:
			continue
		var phase: ScoreEffect.Phase = ScoreEffect.Phase.ADD_QI if step.kind == ScoreStep.Kind.CARD else step.effect.phase
		Sons.play(&"note_carte" if step.card != null else &"orbe_depart", note)
		_send_orb(_light_source(step), phase, step, note)
		note += 1
		# L'orbe a toujours atterri avant l'etape suivante : la colonne suit l'ordre du calcul.
		await _wait(maxf(feel.step_delay, 0.0 if settings.reduce_motion else feel.orb_time))
	var total := context.total()
	_shake(clampf(float(total) / maxi(target_score, 1), 0.0, 1.0))
	_pulse_background(context.hand.scoring_cards)
	_flash(clampf(float(total) / maxi(target_score, 1), 0.0, 1.0))
	_fly_total(total)
	await _wait(feel.end_delay)
	running = false
	finished.emit()


## La source de l'etape s'allume ; renvoie d'ou part son orbe.
## Un artefact declenche par une carte : la carte bondit aussi, mais l'orbe part de l'artefact.
func _light_source(step: ScoreStep) -> Vector2:
	var at := _above_row()
	if step.card != null:
		_hand_view.pulse(step.card)
		at = _hand_view.card_center(step.card)
		_burst(at, ElementStyles.of(step.card.element).color)
	var artifact := step.source as ArtifactDefinition
	if artifact != null and artifact_hit.is_valid():
		var slot: Vector2 = artifact_hit.call(artifact)
		if slot.is_finite():
			at = slot
	return at


## L'orbe file en courbe vers la case de sa phase ; la case defile et s'eclaire a l'arrivee.
func _send_orb(from: Vector2, phase: ScoreEffect.Phase, step: ScoreStep, note: int) -> void:
	var target_of: Callable = qi_target if phase == ScoreEffect.Phase.ADD_QI else comprehension_target
	if settings.reduce_motion or feel.orb_time <= 0.0 or not target_of.is_valid() or not from.is_finite():
		_land(phase, step, note)
		return
	var to: Vector2 = target_of.call()
	var color := feel.qi_color if phase == ScoreEffect.Phase.ADD_QI else feel.comprehension_color
	var side: float = feel.orb_mult_size if phase == ScoreEffect.Phase.MULT_COMPREHENSION else feel.orb_size
	var orb := Sprite2D.new()
	orb.texture = _qi_texture
	orb.scale = Vector2.ONE * side / QI_DOT_SIZE
	orb.modulate = color
	orb.global_position = from
	add_child(orb)
	var trail := CPUParticles2D.new()
	trail.local_coords = false
	trail.amount = TRAIL_AMOUNT
	trail.lifetime = TRAIL_LIFETIME
	trail.texture = _qi_texture
	trail.gravity = Vector2.ZERO
	trail.initial_velocity_max = 0.0
	trail.color = color
	trail.color_ramp = _fade_out()
	orb.add_child(trail)
	# Point de controle de la courbe : a mi-chemin, decale vers le haut de orb_arc fois la distance.
	var control := (from + to) / 2 + Vector2.UP * from.distance_to(to) * feel.orb_arc
	var tween := orb.create_tween()
	tween.tween_method(func(t: float) -> void:
		orb.global_position = from.lerp(control, t).lerp(control.lerp(to, t), t), 0.0, 1.0, feel.orb_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		_land(phase, step, note)
		# L'orbe s'eteint, sa trainee finit de se dissiper avant la liberation.
		orb.self_modulate.a = 0.0
		trail.emitting = false)
	tween.tween_interval(TRAIL_LIFETIME)
	tween.tween_callback(orb.queue_free)


func _land(phase: ScoreEffect.Phase, step: ScoreStep, note: int) -> void:
	Sons.play(&"multiplication" if phase == ScoreEffect.Phase.MULT_COMPREHENSION else &"orbe_impact", note)
	_roll_to(step)
	value_hit.emit(phase)


func _roll_to(step: ScoreStep) -> void:
	var to := Vector2(step.qi, step.comprehension)
	if step.kind == ScoreStep.Kind.BASE or feel.roll_time <= 0.0:
		_set_tally(to)
		return
	create_tween().tween_method(_set_tally, _shown, to, feel.roll_time)


func _set_tally(values: Vector2) -> void:
	_shown = values
	tally_changed.emit(roundi(values.x), values.y)


## Le nom de la main tombe en grand sur un sceau rouge au-dessus des cartes jouees, puis s'efface.
func _announce(text: String) -> void:
	if feel.announce_time <= 0.0:
		return
	var seal := PanelContainer.new()
	seal.theme_type_variation = &"HandSeal"
	seal.mouse_filter = MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.theme_type_variation = &"HandAnnounce"
	label.text = text
	seal.add_child(label)
	add_child(seal)
	seal.reset_size()
	seal.pivot_offset = seal.size / 2
	var top := _hand_view.played_row_top()
	seal.global_position = top - Vector2(seal.size.x / 2, seal.size.y + ANNOUNCE_MARGIN)
	seal.rotation_degrees = feel.announce_tilt
	var appear: float = feel.announce_time * 0.3
	var fade: float = feel.announce_time * 0.3
	var tween := seal.create_tween()
	if not settings.reduce_motion:
		seal.scale = Vector2.ZERO
		tween.tween_property(seal, "scale", Vector2.ONE, appear).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		tween.tween_interval(appear)
	tween.tween_interval(feel.announce_time - appear - fade)
	tween.tween_property(seal, "modulate:a", 0.0, fade)
	tween.tween_callback(seal.queue_free)


## Le ciel s'eclaire un instant, d'autant plus que le coup est fort. ratio : part de l'objectif atteinte par ce coup.
func _flash(ratio: float) -> void:
	if settings.reduce_motion or feel.flash_max * ratio <= 0.0:
		return
	var sky := ColorRect.new()
	sky.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	sky.mouse_filter = MOUSE_FILTER_IGNORE
	sky.color = Color(feel.flash_color, feel.flash_max * ratio)
	add_child(sky)
	# Derriere les orbes.
	move_child(sky, 0)
	var tween := sky.create_tween()
	tween.tween_property(sky, "color:a", 0.0, feel.flash_time)
	tween.tween_callback(sky.queue_free)


## Le total quitte les cases Qi x Comprehension et file vers le Qi du round, qui defile ensuite.
func _fly_total(total: int) -> void:
	if settings.reduce_motion or not score_target.is_valid() or not tally_origin.is_valid() or feel.end_delay <= 0.0:
		return
	var label := Label.new()
	label.text = str(total)
	label.mouse_filter = MOUSE_FILTER_IGNORE
	label.add_theme_color_override(&"font_color", feel.comprehension_color)
	label.add_theme_font_size_override(&"font_size", feel.total_font_size)
	label.add_theme_constant_override(&"outline_size", TOTAL_OUTLINE_SIZE)
	label.add_theme_color_override(&"font_outline_color", TOTAL_OUTLINE_COLOR)
	add_child(label)
	label.reset_size()
	label.global_position = tally_origin.call() - label.size / 2
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


## D'ou part l'orbe d'un effet qui ne vient ni d'une carte ni d'un artefact affiche : au-dessus des cartes jouees.
func _above_row() -> Vector2:
	return _hand_view.played_row_top() - Vector2(0, ANNOUNCE_MARGIN)


func _wait(seconds: float) -> void:
	if seconds > 0.0:
		await get_tree().create_timer(seconds).timeout
