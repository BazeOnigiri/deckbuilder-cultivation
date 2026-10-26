class_name ItemSlot
extends Button
## Emplacement d'artefact ou de pilule, dessine dans _draw() : cadre et glyphe du contenu.
## Une icone (artefacts) remplace le glyphe. Sans glyphe ni icone, c'est un emplacement libre en pointilles. Apparence dans le Theme (type ItemSlot).

enum Kind {ARTIFACT, PILL}

var kind: Kind = Kind.ARTIFACT
## Vide : emplacement libre.
var glyph: String = ""
var picture: Texture2D


func _ready() -> void:
	theme_type_variation = &"ItemSlot"
	# shortcut: pas de focus (souris seule), a revoir avec la navigation clavier/manette via InputMap
	focus_mode = FOCUS_NONE
	if kind == Kind.PILL:
		custom_minimum_size = Vector2.ONE * get_theme_constant(&"pill_size")
	else:
		custom_minimum_size = Vector2(get_theme_constant(&"artifact_width"), get_theme_constant(&"artifact_height"))
	pivot_offset = custom_minimum_size / 2
	if is_empty():
		mouse_filter = MOUSE_FILTER_IGNORE


## Bondit puis revient : l'artefact se declenche.
func pulse(peak: float, time: float) -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * peak, time / 2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, time / 2)


func is_empty() -> bool:
	return glyph.is_empty() and picture == null


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if is_empty():
		_draw_dashed(rect)
		return
	var box: String = "pill_slot" if kind == Kind.PILL else "slot"
	if is_hovered() and not disabled:
		box += "_hover"
	draw_style_box(get_theme_stylebox(StringName(box)), rect)
	var font := get_theme_font(&"font")
	var font_size := get_theme_font_size(&"pill_font_size" if kind == Kind.PILL else &"font_size")
	var color := get_theme_color(&"pill_color" if kind == Kind.PILL else &"artifact_color")
	if disabled:
		color = get_theme_color(&"disabled_color")
	if picture != null:
		var side := Vector2.ONE * get_theme_constant(&"icon_size")
		draw_texture_rect(picture, Rect2((size - side) / 2, side), false, color)
		return
	# Ligne de base qui centre le caractere en hauteur.
	var baseline: float = (size.y + font.get_ascent(font_size) - font.get_descent(font_size)) / 2
	draw_string(font, Vector2(0, baseline), glyph, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, color)


func _draw_dashed(rect: Rect2) -> void:
	var color := get_theme_color(&"empty_color")
	var dash: float = get_theme_constant(&"dash")
	var corners: Array[Vector2] = [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for i: int in corners.size():
		draw_dashed_line(corners[i], corners[(i + 1) % corners.size()], color, 1.0, dash)
