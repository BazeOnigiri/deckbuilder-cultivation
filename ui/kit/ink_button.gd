class_name InkButton
extends Button
## Choix de menu en texte seul (type Theme InkButton) : au survol ou au focus, un trait de pinceau
## se dessine sous le texte, de gauche a droite, et s'efface quand la souris part.

const STROKE := preload("res://ui/kit/trait_pinceau.svg")

var reduce_motion: bool = false
## 0 = pas de trait, 1 = trait complet.
var ink: float = 0.0
var _tween: Tween


func _ready() -> void:
	if theme_type_variation.is_empty():
		theme_type_variation = &"InkButton"
	mouse_default_cursor_shape = CURSOR_POINTING_HAND
	mouse_entered.connect(_paint.bind(1.0))
	mouse_exited.connect(_paint.bind(0.0))
	focus_entered.connect(_paint.bind(1.0))
	focus_exited.connect(_paint.bind(0.0))


func _paint(to: float) -> void:
	if _tween != null:
		_tween.kill()
	var time: float = get_theme_constant(&"stroke_ms", &"InkButton") / 1000.0
	if reduce_motion or time <= 0.0:
		_set_ink(to)
		return
	_tween = create_tween()
	_tween.tween_method(_set_ink, ink, to, time * absf(to - ink)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _set_ink(value: float) -> void:
	ink = value
	queue_redraw()


## Dessine apres le texte du bouton : le trait reste sous la ligne de base, il ne cache pas les lettres.
func _draw() -> void:
	if ink <= 0.0 or disabled:
		return
	var height: float = get_theme_constant(&"stroke_height", &"InkButton")
	var font := get_theme_font(&"font")
	var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, get_theme_font_size(&"font_size")).x
	var width := minf(size.x, text_width * 1.15)
	var left := (size.x - width) / 2 if alignment == HORIZONTAL_ALIGNMENT_CENTER else 0.0
	var rect := Rect2(left, size.y - height, width * ink, height)
	var source := Rect2(0, 0, STROKE.get_width() * ink, STROKE.get_height())
	draw_texture_rect_region(STROKE, rect, source)
