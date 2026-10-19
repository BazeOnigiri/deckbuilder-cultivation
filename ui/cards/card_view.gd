class_name CardView
extends Button
## Une carte de la main, selectionnable. Couleur ET nom d'element : lisible sans distinguer les couleurs.

const SIZE := Vector2(90, 130)
const ELEMENT_COLORS := {
	Element.Type.BOIS: Color("5cb85c"),
	Element.Type.FEU: Color("e05a47"),
	Element.Type.TERRE: Color("c9a227"),
	Element.Type.METAL: Color("b0bec5"),
	Element.Type.EAU: Color("4a90e2"),
}
const FONT_STATES := ["font_color", "font_pressed_color", "font_hover_color",
	"font_hover_pressed_color", "font_focus_color"]

var card: CardInstance


func _ready() -> void:
	toggle_mode = true
	custom_minimum_size = SIZE
	text = "%d\n%s" % [card.data.rank, tr("ELEMENT_" + Element.to_id(card.data.element).to_upper())]
	for state: String in FONT_STATES:
		add_theme_color_override(state, ELEMENT_COLORS[card.data.element])