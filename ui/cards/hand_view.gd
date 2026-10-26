class_name HandView
extends Control
## La main : cartes en eventail qui rejoignent leur place avec un ressort, flottent, et s'inclinent vers la souris.
## Garde les vues d'une action a l'autre : une carte qui reste bouge au lieu de reapparaitre.

## Une carte a ete selectionnee ou deselectionnee.
signal selection_changed

var feel: HandFeel = preload("res://ui/cards/hand_feel.tres")
## Injecte par l'ecran de run. reduce_motion : pas de flottement ni d'inclinaison, les cartes vont droit a leur place.
var settings: GameSettings = GameSettings.new()

var _views: Dictionary[CardInstance, CardView] = {}
## Position et angle de chaque vue. Cree a sa premiere frame, quand la taille de la main est connue.
var _poses: Dictionary[CardView, CardSpring] = {}
## Inclinaison x, inclinaison y, echelle.
var _tilts: Dictionary[CardView, CardSpring] = {}
var _time: float = 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	custom_minimum_size.y = CardView.CARD_SIZE.y + _lift() + feel.arc_height


## Affiche ces cartes, dans cet ordre. Les vues des cartes deja la sont gardees et deselectionnees.
func set_cards(cards: Array[CardInstance]) -> void:
	for card: CardInstance in _views.keys():
		if not cards.has(card):
			var old: CardView = _views[card]
			_views.erase(card)
			_poses.erase(old)
			_tilts.erase(old)
			# remove_child tout de suite : queue_free seul laisse l'enfant compte jusqu'a la frame suivante.
			remove_child(old)
			old.queue_free()
	for i: int in cards.size():
		var view: CardView = _views.get(cards[i])
		if view == null:
			view = CardView.new()
			view.card = cards[i]
			view.toggled.connect(selection_changed.emit.unbind(1))
			_views[cards[i]] = view
			add_child(view)
		else:
			view.set_pressed_no_signal(false)
			view.refresh()
		move_child(view, i)


func _process(delta: float) -> void:
	_time += delta
	var count: int = get_child_count()
	var slots := HandLayout.slots(count, size.x, CardView.CARD_SIZE.x, feel)
	# Centre d'une carte posee au milieu de l'eventail ; les bouts descendent de arc_height.
	var base := Vector2(size.x / 2, size.y - CardView.CARD_SIZE.y / 2 - feel.arc_height)
	for i: int in count:
		var view := get_child(i) as CardView
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


func _lift() -> float:
	return get_theme_constant(&"lift", &"CardButton")
