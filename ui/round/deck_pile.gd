class_name DeckPile
extends HBoxContainer
## Pioche de l'ecran de round : trois dos de carte empiles, marques du sceau 道, et le compteur pioche/paquet.
## Apparence dans le Theme (type DeckPile). Un clic emet pressed (vue du paquet).

signal pressed

## Sceau decoratif, identique dans toutes les langues.
const BACK_GLYPH := "道"

var _backs := Backs.new()
var _count := SideColumn.make_label(&"SideValue")
## Faux pendant la sequence de score : le clic ne fait rien.
var enabled: bool = true


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	mouse_default_cursor_shape = CURSOR_POINTING_HAND
	tooltip_text = "UI_DECK_VIEW"
	add_child(_backs)
	var text := VBoxContainer.new()
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.add_child(SideColumn.make_label(&"SideCaption", "UI_DECK"))
	text.add_child(_count)
	add_child(text)


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if enabled and click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		pressed.emit()


func show_count(draw_count: int, deck_size: int) -> void:
	_count.text = tr("UI_SIDE_OF") % [draw_count, deck_size]
	# Pioche vide : plus de dos a montrer.
	_backs.visible = draw_count > 0


## Les dos de carte, decales en diagonale. Le dernier dessine est celui du dessus.
class Backs extends Control:
	const LAYERS := 3

	func _ready() -> void:
		var offset: float = get_theme_constant(&"offset", &"DeckPile")
		custom_minimum_size = _back_size() + Vector2.ONE * offset * (LAYERS - 1)

	func _back_size() -> Vector2:
		return Vector2(get_theme_constant(&"back_width", &"DeckPile"), get_theme_constant(&"back_height", &"DeckPile"))

	func _draw() -> void:
		var offset: float = get_theme_constant(&"offset", &"DeckPile")
		var back := get_theme_stylebox(&"back", &"DeckPile")
		var rect := Rect2(Vector2.ZERO, _back_size())
		for i: int in LAYERS:
			rect.position = Vector2.ONE * offset * (LAYERS - 1 - i)
			draw_style_box(back, rect)
		var font := get_theme_font(&"font", &"DeckPile")
		var font_size := get_theme_font_size(&"font_size", &"DeckPile")
		var baseline: float = rect.position.y + (rect.size.y + font.get_ascent(font_size) - font.get_descent(font_size)) / 2
		draw_string(font, Vector2(rect.position.x, baseline), BACK_GLYPH, HORIZONTAL_ALIGNMENT_CENTER,
			rect.size.x, font_size, get_theme_color(&"glyph_color", &"DeckPile"))
