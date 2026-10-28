class_name InfoBubble
extends VBoxContainer
## Infobulle facon Balatro : titre, encart papier avec la description (valeurs de Qi en jade, de Comprehension en or,
## noms d'elements dans leur couleur), puis des badges (type d'objet, element...).
## Renvoyee par _make_custom_tooltip des cartes et des emplacements. Apparence dans le Theme (types Info*).


## badges : liste de [texte, couleur de fond].
static func build(title: String, description: String, badges: Array = []) -> InfoBubble:
	var bubble := InfoBubble.new()
	bubble.theme_type_variation = &"InfoBubble"
	var heading := Label.new()
	heading.theme_type_variation = &"InfoTitle"
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bubble.add_child(heading)
	if not description.is_empty():
		var paper := PanelContainer.new()
		paper.theme_type_variation = &"InfoPaper"
		var text := RichTextLabel.new()
		text.theme_type_variation = &"InfoText"
		text.bbcode_enabled = true
		text.fit_content = true
		text.scroll_active = false
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.custom_minimum_size.x = bubble.get_theme_constant(&"width", &"InfoBubble")
		text.text = colorize(description, bubble)
		paper.add_child(text)
		bubble.add_child(paper)
	if not badges.is_empty():
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		for badge: Array in badges:
			row.add_child(_badge(badge[0], badge[1]))
		bubble.add_child(row)
	return bubble


## Description en BBCode : « +5 Qi », « x2 Comprehension » et les noms d'elements colores, le reste tel quel.
## Les mots sont pris dans les traductions : marche dans toutes les langues.
static func colorize(description: String, owner: Control) -> String:
	var text := description.replace("[", "[lb]")
	var number := "([+x×]?\\s?\\d+(?:[.,]\\d+)?)\\s"
	for pair: Array in [[owner.tr("UI_SIDE_QI"), &"qi_color"], [owner.tr("UI_SIDE_COMPREHENSION"), &"comprehension_color"]]:
		var color := owner.get_theme_color(pair[1], &"InfoBubble")
		var regex := RegEx.create_from_string(number + "(" + _escape(pair[0]) + ")")
		text = regex.sub(text, "[b][color=#%s]$1 $2[/color][/b]" % color.to_html(false), true)
	var darken: float = owner.get_theme_constant(&"element_darken_percent", &"InfoBubble") / 100.0
	for element: int in Element.Type.values():
		var name := owner.tr("ELEMENT_" + Element.to_id(element).to_upper())
		var color := ElementStyles.of(element as Element.Type).color.darkened(darken)
		var regex := RegEx.create_from_string("\\b(" + _escape(name) + ")\\b")
		text = regex.sub(text, "[b][color=#%s]$1[/color][/b]" % color.to_html(false), true)
	return text


static func _badge(label: String, color: Color) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.theme_type_variation = &"InfoBadge"
	var style := badge.get_theme_stylebox(&"panel", &"InfoBadge").duplicate() as StyleBoxFlat
	style.bg_color = color
	badge.add_theme_stylebox_override(&"panel", style)
	var text := Label.new()
	text.theme_type_variation = &"InfoBadgeText"
	text.text = label
	badge.add_child(text)
	return badge


static func _escape(word: String) -> String:
	var escaped := ""
	for character: String in word:
		escaped += "\\" + character if "\\^$.|?*+()[]{}".contains(character) else character
	return escaped
