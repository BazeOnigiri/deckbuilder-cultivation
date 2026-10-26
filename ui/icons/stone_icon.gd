class_name StoneIcon
extends TextureRect
## Pierre spirituelle : icone, couleur et taille dans le Theme (type StoneIcon).
## side > 0 remplace la taille du Theme (cristaux qui tombent).

var side: float = 0.0


func _ready() -> void:
	texture = get_theme_icon(&"icon", &"StoneIcon")
	modulate = get_theme_color(&"color", &"StoneIcon")
	expand_mode = EXPAND_IGNORE_SIZE
	stretch_mode = STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = MOUSE_FILTER_IGNORE
	var length: float = side if side > 0.0 else float(get_theme_constant(&"size", &"StoneIcon"))
	custom_minimum_size = Vector2.ONE * length
	size = custom_minimum_size
	pivot_offset = size / 2
