class_name HandView
extends Control
## La main : cartes en eventail qui rejoignent leur place avec un ressort, flottent, et s'inclinent vers la souris.
## Garde les vues d'une action a l'autre : une carte qui reste bouge au lieu de reapparaitre.
## Les cartes jouees montent dans une rangee au-dessus le temps que le score soit montre.
## Une carte qui quitte la main (jouee, defaussee, detruite) se dissout au lieu de disparaitre d'un coup.

## Une carte a ete selectionnee ou deselectionnee.
signal selection_changed

var feel: HandFeel = preload("res://ui/cards/hand_feel.tres")
## Injecte par l'ecran de run. reduce_motion : pas de flottement ni d'inclinaison, les cartes vont droit a leur place.
var settings: GameSettings = GameSettings.new()

var _views: Dictionary[CardInstance, CardView] = {}
## Cartes de la main, dans l'ordre affiche.
var _order: Array[CardView] = []
## Cartes jouees, en attendant clear_played().
var _played: Array[CardView] = []
## Position et angle de chaque vue. Cree a sa premiere frame, quand la taille de la main est connue.
var _poses: Dictionary[CardView, CardSpring] = {}
## Inclinaison x, inclinaison y, echelle.
var _tilts: Dictionary[CardView, CardSpring] = {}
## Cartes qui se dissolvent, et ou en est leur dissolution (0 a 1).
var _leaving: Dictionary[CardView, float] = {}
## Enfant interne : les cartes qui partent n'apparaissent plus dans get_children(), qui ne liste que la main.
var _leaving_layer := Control.new()
var _time: float = 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	custom_minimum_size.y = CardView.CARD_SIZE.y + _lift() + feel.arc_height
	_leaving_layer.mouse_filter = MOUSE_FILTER_IGNORE
	# INTERNAL_MODE_FRONT : dessinees avant la main, donc derriere les cartes qui restent.
	add_child(_leaving_layer, false, INTERNAL_MODE_FRONT)


## Affiche ces cartes, dans cet ordre. Les vues des cartes deja la sont gardees et deselectionnees.
func set_cards(cards: Array[CardInstance]) -> void:
	var departed := false
	for card: CardInstance in _views.keys():
		if not cards.has(card):
			_depart(_views[card])
			_views.erase(card)
			departed = true
	if departed:
		Sons.play(&"carte_defausse")
	_order.clear()
	var drawn := false
	for card: CardInstance in cards:
		var view: CardView = _views.get(card)
		if view == null:
			drawn = true
			view = CardView.new()
			view.card = card
			view.toggled.connect(selection_changed.emit.unbind(1))
			_views[card] = view
			add_child(view)
		else:
			view.set_pressed_no_signal(false)
			view.refresh()
		_order.append(view)
		move_child(view, -1)
	if drawn:
		Sons.play(&"carte_pioche")


## Sort ces cartes de la main : elles montent dans la rangee du score et ne reagissent plus a la souris.
func play_out(cards: Array[CardInstance]) -> void:
	Sons.play(&"carte_jouee")
	for card: CardInstance in cards:
		var view: CardView = _views.get(card)
		if view == null:
			continue
		_views.erase(card)
		_order.erase(view)
		view.set_pressed_no_signal(false)
		view.mouse_filter = MOUSE_FILTER_IGNORE
		_played.append(view)


func clear_played() -> void:
	for view: CardView in _played:
		_depart(view)
	_played.clear()


## Petit bond de la carte, quand elle compte.
func pulse(card: CardInstance) -> void:
	var view := _view_of(card)
	if view != null and _tilts.has(view) and not settings.reduce_motion:
		_tilts[view].velocity.z += feel.pulse_kick


## sealed(card) -> bool : vrai si la tribulation scelle la carte. Appele par round_screen apres set_cards.
func mark_sealed(sealed: Callable) -> void:
	var newly := false
	for view: CardView in _order:
		var on: bool = sealed.call(view.card)
		newly = newly or (on and not view.is_sealed())
		view.set_sealed(on)
	if newly:
		Sons.play(&"sceau")


## Une pilule vient de fondre dans la carte : elle s'eclaire de la couleur de son (nouvel) element.
func transmute(card: CardInstance) -> void:
	Sons.play(&"pilule")
	var view := _view_of(card)
	if view == null or settings.reduce_motion or feel.transmute_time <= 0.0:
		return
	var color := ElementStyles.of(card.element).color
	view.self_modulate = Color(color.r * feel.transmute_glow, color.g * feel.transmute_glow, color.b * feel.transmute_glow)
	view.create_tween().tween_property(view, "self_modulate", Color.WHITE, feel.transmute_time)


## Centre de la carte a l'ecran, ou Vector2.INF si elle n'est pas affichee.
func card_center(card: CardInstance) -> Vector2:
	var view := _view_of(card)
	return Vector2.INF if view == null else view.get_global_transform() * (CardView.CARD_SIZE / 2)


## Milieu du bord haut de la rangee des cartes jouees, a l'ecran.
func played_row_top() -> Vector2:
	return get_global_transform() * (_base() - Vector2(0, feel.play_rise + CardView.CARD_SIZE.y / 2))


func _process(delta: float) -> void:
	_time += delta
	_layout(_order, _base(), delta)
	_layout(_played, _base() - Vector2(0, feel.play_rise), delta)
	_dissolve(delta)


## Centre d'une carte posee au milieu de l'eventail ; les bouts descendent de arc_height.
func _base() -> Vector2:
	return Vector2(size.x / 2, size.y - CardView.CARD_SIZE.y / 2 - feel.arc_height)


func _layout(views: Array[CardView], base: Vector2, delta: float) -> void:
	var slots := HandLayout.slots(views.size(), size.x, CardView.CARD_SIZE.x, feel)
	for i: int in views.size():
		var view := views[i]
		var pose := Vector3(base.x + slots[i].x, base.y + slots[i].y, slots[i].z)
		if view.button_pressed:
			pose.y -= _lift()
		var tilt := Vector3(0, 0, feel.hover_scale if view.is_hovered() else 1.0)
		if not settings.reduce_motion:
			# Chaque carte a sa phase, sinon toute la main flotterait d'un bloc.
			var phase: float = i * 1.7
			pose.y += sin(_time * feel.idle_speed + phase) * feel.idle_amplitude
			pose.z += deg_to_rad(feel.idle_rotation) * sin(_time * feel.idle_speed * 0.7 + phase)
			if view.is_hovered():
				# Souris de -1 a 1 sur la carte. Le cote sous la souris s'enfonce.
				var mouse := (view.get_local_mouse_position() / CardView.CARD_SIZE * 2.0 - Vector2.ONE).clamp(-Vector2.ONE, Vector2.ONE)
				tilt.x = -mouse.y * deg_to_rad(feel.tilt_max)
				tilt.y = mouse.x * deg_to_rad(feel.tilt_max)
		_move(view, pose, tilt, delta)


func _move(view: CardView, pose: Vector3, tilt: Vector3, delta: float) -> void:
	if not _poses.has(view):
		var start := pose + Vector3(feel.deal_offset.x, feel.deal_offset.y, 0)
		_poses[view] = CardSpring.new(start)
		_tilts[view] = CardSpring.new(tilt)
	var pose_spring: CardSpring = _poses[view]
	var tilt_spring: CardSpring = _tilts[view]
	if settings.reduce_motion:
		pose_spring.snap(pose)
		tilt_spring.snap(tilt)
	else:
		pose_spring.step(pose, delta, feel.stiffness, feel.damping)
		tilt_spring.step(tilt, delta, feel.stiffness, feel.damping)
	view.position = Vector2(pose_spring.value.x, pose_spring.value.y) - CardView.CARD_SIZE / 2
	view.rotation = pose_spring.value.z
	view.scale = Vector2.ONE * tilt_spring.value.z
	view.set_tilt(Vector2(tilt_spring.value.x, tilt_spring.value.y))


func _view_of(card: CardInstance) -> CardView:
	var view: CardView = _views.get(card)
	if view != null:
		return view
	for played: CardView in _played:
		if played.card == card:
			return played
	return null


## La carte quitte la main tout de suite (plus comptee, plus cliquable) et se dissout la ou elle est.
func _depart(view: CardView) -> void:
	_poses.erase(view)
	_tilts.erase(view)
	view.set_pressed_no_signal(false)
	view.mouse_filter = MOUSE_FILTER_IGNORE
	view.reparent(_leaving_layer)
	_leaving[view] = 0.0


func _dissolve(delta: float) -> void:
	for view: CardView in _leaving.keys():
		var amount: float = 1.0 if feel.dissolve_time <= 0.0 else _leaving[view] + delta / feel.dissolve_time
		if amount >= 1.0:
			_leaving.erase(view)
			view.queue_free()
			continue
		_leaving[view] = amount
		view.set_dissolve(amount)
		if not settings.reduce_motion:
			view.position.y -= feel.dissolve_drift * delta


func _lift() -> float:
	return get_theme_constant(&"lift", &"CardButton")
