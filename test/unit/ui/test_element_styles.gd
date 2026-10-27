extends GutTest

const Contrast := preload("res://test/helpers/contrast.gd")
const THEME_PATH := "res://ui/theme/lavis_de_nuit.tres"
const DECK_PATH := "res://content/decks/paquet_depart.tres"
const CARD_STYLES := ["card", "card_hover", "card_selected"]
const CARD_TYPE := "CardButton"


func test_un_style_avec_icone_par_element() -> void:
	for element: Element.Type in Element.Type.values():
		var style := ElementStyles.of(element)
		assert_not_null(style, "style manquant : %s" % Element.to_id(element))
		if style != null:
			assert_not_null(style.icon, "icone manquante : %s" % Element.to_id(element))


func test_rang_et_couleurs_lisibles_sur_la_carte() -> void:
	var theme: Theme = load(THEME_PATH)
	var rank: Color = theme.get_color("rank_color", CARD_TYPE)
	for state: String in CARD_STYLES:
		var fond: Color = (theme.get_stylebox(state, CARD_TYPE) as StyleBoxFlat).bg_color
		assert_gt(Contrast.ratio(rank, fond), 4.5, "rang sur %s" % state)
		for element: Element.Type in Element.Type.values():
			var style := ElementStyles.of(element)
			if style != null:
				assert_gt(Contrast.ratio(style.color, fond), 4.5, "%s sur %s" % [Element.to_id(element), state])


func test_sceau_lisible() -> void:
	var theme: Theme = load(THEME_PATH)
	var font: Font = theme.get_font("seal_font", CARD_TYPE)
	assert_true(font.has_char(CardView.SEAL_GLYPH.unicode_at(0)), "caractere du sceau absent de la police")
	var ratio: float = Contrast.ratio(theme.get_color("seal_text_color", CARD_TYPE), theme.get_color("seal_color", CARD_TYPE))
	assert_gt(ratio, 4.5, "texte du sceau")


func test_chaque_rang_du_paquet_a_un_centre() -> void:
	var deck: DeckDefinition = load(DECK_PATH)
	for card: CardData in deck.cards:
		assert_true(CardView.PIPS.has(card.rank) or CardView.FIGURES.has(card.rank), "rien au centre du rang %d" % card.rank)
