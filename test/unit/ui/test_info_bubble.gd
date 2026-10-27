extends GutTest
## Infobulles facon Balatro : valeurs et elements colores, badges, nom des cartes et des figures.

const Contrast := preload("res://test/helpers/contrast.gd")


func _owner() -> Control:
	return add_child_autofree(Control.new())


func test_valeurs_de_qi_et_comprehension_colorees() -> void:
	var owner := _owner()
	var text := InfoBubble.colorize(tr("ARTIFACT_CHAUDRON_ALCHIMIQUE_DESC"), owner)
	var qi := owner.get_theme_color(&"qi_color", &"InfoBubble").to_html(false)
	var comprehension := owner.get_theme_color(&"comprehension_color", &"InfoBubble").to_html(false)
	assert_string_contains(text, "[color=#%s]+5 %s[/color]" % [qi, tr("UI_SIDE_QI")])
	assert_string_contains(text, "[color=#%s]+0,5 %s[/color]" % [comprehension, tr("UI_SIDE_COMPREHENSION")])


func test_multiplicateur_et_element_colores() -> void:
	var text := InfoBubble.colorize(tr("ARTIFACT_TIGRE_BLANC_DESC"), _owner())
	assert_string_contains(text, "x1,2 %s[/color]" % tr("UI_SIDE_COMPREHENSION"))
	assert_string_contains(text, "]%s[/color]" % tr("ELEMENT_METAL"))


func test_crochets_du_texte_neutralises() -> void:
	assert_eq(InfoBubble.colorize("a [b] c", _owner()), "a [lb]b] c")


## Les couleurs posees sur le papier de l'infobulle restent lisibles.
func test_couleurs_lisibles_sur_le_papier() -> void:
	var owner := _owner()
	var paper := (owner.get_theme_stylebox(&"panel", &"InfoPaper") as StyleBoxFlat).bg_color
	var darken: float = owner.get_theme_constant(&"element_darken_percent", &"InfoBubble") / 100.0
	var colors: Array[Color] = [owner.get_theme_color(&"qi_color", &"InfoBubble"),
		owner.get_theme_color(&"comprehension_color", &"InfoBubble"),
		owner.get_theme_color(&"default_color", &"InfoText")]
	for element: int in Element.Type.values():
		colors.append(ElementStyles.of(element as Element.Type).color.darkened(darken))
	for color: Color in colors:
		assert_gte(Contrast.ratio(color, paper), 3.0, "contraste de %s" % color)


func test_infobulle_d_un_artefact() -> void:
	var slot: ItemSlot = add_child_autofree(ItemSlot.new())
	slot.set_info("Epee", "+15 Qi.")
	assert_eq(slot.tooltip_text, "Epee")
	var bubble: InfoBubble = autofree(slot._make_custom_tooltip(""))
	var labels := bubble.find_children("*", "Label", true, false).map(func(label: Label) -> String: return label.text)
	assert_has(labels, "Epee")
	assert_has(labels, tr("UI_KIND_ARTIFACT"))
	assert_eq(bubble.find_children("*", "RichTextLabel", true, false).size(), 1)


func test_infobulle_d_une_figure() -> void:
	var view := CardView.new()
	view.card = CardInstance.new(0, CardData.create(&"c", Element.Type.FEU, 10), load("res://content/rules/rangs.tres"))
	add_child_autofree(view)
	assert_eq(view.tooltip_text, tr("CARD_RANK_10"))
	var bubble: InfoBubble = autofree(view._make_custom_tooltip(""))
	var text: RichTextLabel = bubble.find_children("*", "RichTextLabel", true, false)[0]
	assert_string_contains(text.text, "+10 %s" % tr("UI_SIDE_QI"))
