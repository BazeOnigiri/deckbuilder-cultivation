class_name ElementOrbit
extends Control
## Les cinq phases (Wu Xing) tournent lentement autour du meditant, dans l'ordre du cycle d'engendrement
## (bois > feu > terre > metal > eau), reliees par un cercle d'or. Apparence dans le Theme (type ElementOrbit).

var reduce_motion: bool = false
## Rotation du cercle, en radians.
var angle: float = 0.0
var _meditant := TextureRect.new()


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	var radius: float = get_theme_constant(&"radius", &"ElementOrbit")
	var icon_size: float = get_theme_constant(&"icon_size", &"ElementOrbit")
	custom_minimum_size = Vector2.ONE * (radius + icon_size) * 2
	# Le meditant du round, rempli de qi et l'aura allumee : la cultivation accomplie.
	var side: float = get_theme_constant(&"meditant_size", &"ElementOrbit")
	_meditant.texture = SideColumn.MEDITANT
	_meditant.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_meditant.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_meditant.mouse_filter = MOUSE_FILTER_IGNORE
	_meditant.size = Vector2.ONE * side
	_meditant.position = (custom_minimum_size - _meditant.size) / 2
	var shader := ShaderMaterial.new()
	shader.shader = SideColumn.MEDITANT_SHADER
	shader.set_shader_parameter(&"fill", 1.0)
	for color: StringName in [&"empty_color", &"qi_color", &"aura_color"]:
		shader.set_shader_parameter(color, get_theme_color(color, &"Meditant"))
	_meditant.material = shader
	add_child(_meditant)


func _process(delta: float) -> void:
	if reduce_motion:
		return
	angle = wrapf(angle + deg_to_rad(get_theme_constant(&"speed_deg", &"ElementOrbit")) * delta, 0.0, TAU)
	queue_redraw()


func _draw() -> void:
	var center := size / 2
	var radius: float = get_theme_constant(&"radius", &"ElementOrbit")
	var icon_size: float = get_theme_constant(&"icon_size", &"ElementOrbit")
	draw_arc(center, radius, 0.0, TAU, 96, get_theme_color(&"ring_color", &"ElementOrbit"), 1.5, true)
	var elements := Element.Type.values()
	for i: int in elements.size():
		# Le bois en haut, puis les phases suivantes dans le sens des aiguilles d'une montre.
		var at := center + Vector2.UP.rotated(angle + TAU * i / elements.size()) * radius
		var style := ElementStyles.of(elements[i])
		draw_circle(at, icon_size * 0.7, get_theme_color(&"disc_color", &"ElementOrbit"))
		draw_arc(at, icon_size * 0.7, 0.0, TAU, 48, Color(style.color, 0.8), 1.5, true)
		draw_texture_rect(style.icon, Rect2(at - Vector2.ONE * icon_size / 2, Vector2.ONE * icon_size), false, style.color)
