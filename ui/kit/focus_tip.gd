class_name FocusTip
extends Node
## Infobulle d'une carte ou d'un objet sans souris : montree quand le Control a le focus visible (clavier,
## manette), ou tant que le doigt reste appuye dessus (tactile). Le relacher apres un appui long ne clique pas.
## Meme bulle que le survol (_make_custom_tooltip du Control), posee au-dessus de lui. Delai dans le Theme
## (InfoBubble/constants/long_press_ms), ecart (InfoBubble/constants/anchor_gap).

## Appui long sur le Control : son infobulle est montree (ex. la rangee d'objets propose alors la vente).
signal long_pressed

## Couche de dessin des bulles : au-dessus de l'ecran et des rouleaux.
const LAYER := 100

var _target: Control
var _layer: CanvasLayer
## Numero de l'appui en cours : un minuteur d'un appui deja relache ne montre rien.
var _touch: int = 0
var _swallow_release := false


## Ajoute la bulle au Control, en enfant interne (absent de get_children()).
static func attach(control: Control) -> FocusTip:
	var tip := FocusTip.new()
	tip.name = "FocusTip"
	control.add_child(tip, false, Node.INTERNAL_MODE_BACK)
	return tip


func _ready() -> void:
	_target = get_parent() as Control
	_target.focus_entered.connect(_on_focus_entered)
	_target.focus_exited.connect(hide_tip)
	_target.gui_input.connect(_on_gui_input)


func _exit_tree() -> void:
	hide_tip()


func is_shown() -> bool:
	return _layer != null


func _on_focus_entered() -> void:
	# Focus cache (pose au clic) : le survol montre deja l'infobulle native.
	if _target.has_focus(true):
		show_tip()


func _on_gui_input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch != null:
		_touch += 1
		if touch.pressed:
			var current := _touch
			var delay: float = _target.get_theme_constant(&"long_press_ms", &"InfoBubble") / 1000.0
			# Temps reel : la vitesse du jeu ne change pas la duree d'un appui.
			get_tree().create_timer(delay, true, false, true).timeout.connect(func() -> void:
				if current == _touch and is_inside_tree():
					_swallow_release = true
					show_tip()
					long_pressed.emit())
		else:
			hide_tip()
		return
	# Le clic emule du doigt arrive avant le relachement tactile : on l'avale pour que l'appui long ne clique pas.
	var click := event as InputEventMouseButton
	if click != null and _swallow_release and not click.pressed:
		_swallow_release = false
		_target.accept_event()


func show_tip() -> void:
	hide_tip()
	var bubble: Control
	if _target.has_method(&"_make_custom_tooltip"):
		bubble = _target.call(&"_make_custom_tooltip", _target.tooltip_text) as Control
	elif not _target.tooltip_text.is_empty():
		bubble = InfoBubble.build(_target.tooltip_text, "")
	if bubble == null:
		return
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"TooltipPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bubble)
	_layer = CanvasLayer.new()
	_layer.layer = LAYER
	_layer.add_child(panel)
	add_child(_layer)
	panel.reset_size()
	panel.position = _place(panel.size)


func hide_tip() -> void:
	if _layer != null:
		_layer.queue_free()
		_layer = null


## Au-dessus du Control, centree ; dessous s'il n'y a pas la place ; toujours dans l'ecran.
func _place(bubble: Vector2) -> Vector2:
	var rect := _target.get_global_rect()
	var gap: float = _target.get_theme_constant(&"anchor_gap", &"InfoBubble")
	var screen := _target.get_viewport_rect().size
	var top := rect.position.y - bubble.y - gap
	if top < 0.0:
		top = rect.end.y + gap
	var left := clampf(rect.get_center().x - bubble.x / 2.0, 0.0, maxf(screen.x - bubble.x, 0.0))
	return Vector2(left, clampf(top, 0.0, maxf(screen.y - bubble.y, 0.0)))
