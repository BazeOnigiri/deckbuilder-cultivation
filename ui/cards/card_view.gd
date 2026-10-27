class_name CardView
extends Button
## Une carte de la main, selectionnable, dessinee dans _draw(). Apparence dans le Theme (type CardButton).
## Couleur ET forme du symbole : lisible sans distinguer les couleurs.
## Placee, levee et inclinee par HandView.

const CARD_SIZE := Vector2(92, 132)
## Chaque carte a son inclinaison : une copie du materiau par carte.
const TILT_MATERIAL := preload("res://ui/cards/carte_inclinee.tres")
const FRAME_INSET := 5.0
## Coin : colonne centree en CORNER_X, ligne de base du rang, centre du symbole.
const CORNER_X := 15.0
const RANK_BASELINE := 21.0
const CORNER_ICON_Y := 33.0
const CORNER_ICON_SIZE := 14.0
const PIP_SIZE := 17.0
const PIP_AREA := Rect2(24, 22, 44, 88)
## Points des rangs 1 a 6, en pourcentage de PIP_AREA.
const PIPS := {
	1: [Vector2(50, 50)],
	2: [Vector2(50, 28), Vector2(50, 72)],
	3: [Vector2(50, 20), Vector2(50, 50), Vector2(50, 80)],
	4: [Vector2(25, 26), Vector2(75, 26), Vector2(25, 74), Vector2(75, 74)],
	5: [Vector2(25, 22), Vector2(75, 22), Vector2(50, 50), Vector2(25, 78), Vector2(75, 78)],
	6: [Vector2(25, 20), Vector2(75, 20), Vector2(25, 50), Vector2(75, 50), Vector2(25, 80), Vector2(75, 80)],
}
const FIGURE_AREA := Rect2(20, 31, 52, 70)
## Figures des rangs 7 a 9 : [fond blanc teinte par l'element, trait couleur papier].
const FIGURES := {
	7: [preload("res://ui/cards/figures/disciple_fond.svg"), preload("res://ui/cards/figures/disciple_trait.svg")],
	8: [preload("res://ui/cards/figures/maitre_fond.svg"), preload("res://ui/cards/figures/maitre_trait.svg")],
	9: [preload("res://ui/cards/figures/immortel_fond.svg"), preload("res://ui/cards/figures/immortel_trait.svg")],
}
const SEAL_SIZE := 24.0
## Le sceau deborde de la carte en haut et a droite.
const SEAL_OVERFLOW := 7.0
## Sceaux decoratifs, identiques dans toutes les langues : selectionnee, scellee par la tribulation.
const SEAL_GLYPH := "选"
const SEALED_GLYPH := "封"

var card: CardInstance
var _glow: StyleBoxFlat
var _sealed: bool = false


func _ready() -> void:
	theme_type_variation = &"CardButton"
	toggle_mode = true
	# shortcut: pas de focus (souris seule), a revoir avec la navigation clavier/manette via InputMap
	focus_mode = FOCUS_NONE
	size = CARD_SIZE
	pivot_offset = CARD_SIZE / 2
	material = TILT_MATERIAL.duplicate()
	refresh()


## A rappeler quand une pilule change l'element ou le rang de la carte.
func refresh() -> void:
	var style := ElementStyles.of(card.element)
	tooltip_text = tr("ELEMENT_" + Element.to_id(card.element).to_upper())
	(material as ShaderMaterial).set_shader_parameter(&"edge_color", style.color)
	# Lueur de la couleur de l'element, gardee par carte : le Theme ne donne que sa forme.
	_glow = (get_theme_stylebox(&"card_glow") as StyleBoxFlat).duplicate()
	_glow.shadow_color = Color(style.color, _glow.shadow_color.a)
	queue_redraw()


## Inclinaison en radians autour des axes x et y.
func set_tilt(tilt: Vector2) -> void:
	(material as ShaderMaterial).set_shader_parameter(&"tilt", tilt)


## Scellee : la tribulation l'empeche de compter. Flammes (shader) et sceau 封.
func is_sealed() -> bool:
	return _sealed


func set_sealed(on: bool) -> void:
	_sealed = on
	var shader := material as ShaderMaterial
	shader.set_shader_parameter(&"sealed", 1.0 if on else 0.0)
	shader.set_shader_parameter(&"flame_color", get_theme_color(&"flame_color"))
	queue_redraw()


## 0 = carte entiere, 1 = disparue.
func set_dissolve(amount: float) -> void:
	(material as ShaderMaterial).set_shader_parameter(&"dissolve", amount)


func _draw() -> void:
	var style := ElementStyles.of(card.element)
	# Une carte modifiee par une pilule luit : le joueur la reconnait dans sa main.
	if card.is_altered():
		draw_style_box(_glow, Rect2(Vector2.ZERO, CARD_SIZE))
	var box: StringName = &"card_selected" if button_pressed else (&"card_hover" if is_hovered() else &"card")
	draw_style_box(get_theme_stylebox(box), Rect2(Vector2.ZERO, CARD_SIZE))
	# +0.5 : le trait de 1 px est centre sur le bord du rectangle, on le cale sur une colonne de pixels.
	var inset := Vector2.ONE * (FRAME_INSET + 0.5)
	draw_rect(Rect2(inset, CARD_SIZE - 2 * inset), get_theme_color(&"frame_color"), false, 1.0)
	_draw_corner(style)
	_draw_center(style)
	if button_pressed:
		_draw_seal()
	if _sealed:
		# Coin bas gauche : libre, le coin bas droit porte le rang retourne.
		var stamp := Rect2(-SEAL_OVERFLOW, CARD_SIZE.y - SEAL_SIZE + SEAL_OVERFLOW, SEAL_SIZE, SEAL_SIZE)
		_draw_stamp(stamp, SEALED_GLYPH, get_theme_color(&"sealed_color"), get_theme_color(&"sealed_text_color"))
	# Coin bas droit : le meme coin, tourne d'un demi-tour autour du coin oppose.
	draw_set_transform(CARD_SIZE, PI)
	_draw_corner(style)
	draw_set_transform(Vector2.ZERO)


func _draw_corner(style: ElementStyle) -> void:
	draw_string(get_theme_font(&"font"), Vector2(0, RANK_BASELINE), str(card.rank), HORIZONTAL_ALIGNMENT_CENTER,
		CORNER_X * 2, get_theme_font_size(&"font_size"), get_theme_color(&"rank_color"))
	_draw_icon(style, Vector2(CORNER_X, CORNER_ICON_Y), CORNER_ICON_SIZE)


func _draw_center(style: ElementStyle) -> void:
	if FIGURES.has(card.rank):
		var layers: Array = FIGURES[card.rank]
		draw_texture_rect(layers[0], FIGURE_AREA, false, style.color)
		draw_texture_rect(layers[1], FIGURE_AREA, false)
		return
	for percent: Vector2 in PIPS.get(card.rank, []):
		_draw_icon(style, PIP_AREA.position + PIP_AREA.size * percent / 100.0, PIP_SIZE)


func _draw_icon(style: ElementStyle, center: Vector2, side: float) -> void:
	draw_texture_rect(style.icon, Rect2(center - Vector2.ONE * side / 2, Vector2.ONE * side), false, style.color)


func _draw_seal() -> void:
	var seal := Rect2(CARD_SIZE.x - SEAL_SIZE + SEAL_OVERFLOW, -SEAL_OVERFLOW, SEAL_SIZE, SEAL_SIZE)
	_draw_stamp(seal, SEAL_GLYPH, get_theme_color(&"seal_color"), get_theme_color(&"seal_text_color"))


func _draw_stamp(seal: Rect2, glyph: String, color: Color, text_color: Color) -> void:
	draw_rect(seal, color)
	var font := get_theme_font(&"seal_font")
	var font_size := get_theme_font_size(&"seal_font_size")
	# Ligne de base qui centre le caractere en hauteur dans le sceau.
	var baseline: float = seal.position.y + (SEAL_SIZE + font.get_ascent(font_size) - font.get_descent(font_size)) / 2
	draw_string(font, Vector2(seal.position.x, baseline), glyph, HORIZONTAL_ALIGNMENT_CENTER,
		SEAL_SIZE, font_size, text_color)
