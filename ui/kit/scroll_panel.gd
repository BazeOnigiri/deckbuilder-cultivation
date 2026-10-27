class_name ScrollPanel
extends PanelContainer
## Rouleau de papier de riz : le papier vient du Theme (type ScrollPanel, texture de bruit en tuiles),
## les baguettes de bois a embouts dores sont dessinees en haut et en bas dans _draw().
## vertical faux : rouleau horizontal (baguettes a gauche et a droite), pour une bande suspendue.

@export var vertical: bool = true

## 0 = enroule, 1 = deroule. unroll() l'anime.
var _open: float = 1.0


func _ready() -> void:
	if theme_type_variation.is_empty():
		theme_type_variation = &"ScrollPanel"


## Le papier se deroule entre les baguettes qui s'ecartent. time 0 : deroule d'un coup.
func unroll(time: float) -> void:
	if time <= 0.0:
		_set_open(1.0)
		return
	_set_open(0.0)
	create_tween().tween_method(_set_open, 0.0, 1.0, time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _set_open(value: float) -> void:
	_open = value
	# Mise a l'echelle depuis le centre : le contenu reste lisible, il se deplie.
	pivot_offset = size / 2
	scale = Vector2(1.0, maxf(value, 0.01)) if vertical else Vector2(maxf(value, 0.01), 1.0)
	queue_redraw()


func _draw() -> void:
	var height: float = get_theme_constant(&"rod_height", &"ScrollPanel")
	var overhang: float = get_theme_constant(&"rod_overhang", &"ScrollPanel")
	# Les baguettes ne s'ecrasent pas avec le papier : on annule l'echelle pour leur epaisseur.
	var thickness := height / maxf(scale.y if vertical else scale.x, 0.01)
	if vertical:
		_draw_rod(Rect2(-overhang, -thickness / 2, size.x + overhang * 2, thickness), true)
		_draw_rod(Rect2(-overhang, size.y - thickness / 2, size.x + overhang * 2, thickness), true)
	else:
		_draw_rod(Rect2(-thickness / 2, -overhang, thickness, size.y + overhang * 2), false)
		_draw_rod(Rect2(size.x - thickness / 2, -overhang, thickness, size.y + overhang * 2), false)


func _draw_rod(rect: Rect2, horizontal: bool) -> void:
	var cap: float = get_theme_constant(&"cap_size", &"ScrollPanel")
	draw_rect(rect, get_theme_color(&"rod_color", &"ScrollPanel"))
	# Reflet du bois sur la moitie haute (ou gauche).
	var light := Rect2(rect.position, Vector2(rect.size.x, rect.size.y / 3)) if horizontal \
		else Rect2(rect.position, Vector2(rect.size.x / 3, rect.size.y))
	draw_rect(light, get_theme_color(&"rod_light", &"ScrollPanel"))
	var cap_color := get_theme_color(&"cap_color", &"ScrollPanel")
	if horizontal:
		draw_rect(Rect2(rect.position, Vector2(cap, rect.size.y)), cap_color)
		draw_rect(Rect2(rect.end - Vector2(cap, rect.size.y), Vector2(cap, rect.size.y)), cap_color)
	else:
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, cap)), cap_color)
		draw_rect(Rect2(rect.end - Vector2(rect.size.x, cap), Vector2(rect.size.x, cap)), cap_color)
