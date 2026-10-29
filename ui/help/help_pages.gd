class_name HelpPages
extends RefCounted
## Aide « Comment jouer » : des sections courtes, les nombres lus dans le contenu (jamais ecrits dans les textes).
## Posee dans un rouleau par le menu et dans la Voie de cultivation.

const CYCLE_PATH := "res://content/cycles/cycle_engendrement.tres"
const CYCLE_SEPARATOR := " > "


## Titre et corps de chaque section, deja traduits et remplis.
static func sections(content: GameContent) -> Array[PackedStringArray]:
	var round_rules := content.round_rules
	var economy := content.economy
	var shop := content.shop_rules
	var ranks := content.starter_deck.ranks
	var cycle: ElementCycle = load(CYCLE_PATH)
	var elements: Array[String] = []
	for element: Element.Type in cycle.order:
		elements.append(TranslationServer.translate("ELEMENT_" + Element.to_id(element).to_upper()))
	var list: Array[PackedStringArray] = []
	_add(list, "HELP_GOAL", [content.realms.size()])
	_add(list, "HELP_PLAY", [round_rules.hands_per_round, round_rules.discards_per_round, round_rules.max_selected_cards,
		round_rules.hand_size])
	# Figures et Souverain : les deux derniers rangs du paquet.
	_add(list, "HELP_SCORE", [ranks.qi_of(ranks.max_rank - 1), ranks.qi_of(ranks.max_rank)])
	_add(list, "HELP_HANDS", [Keys.name_of(&"show_path")])
	_add(list, "HELP_CYCLE", [CYCLE_SEPARATOR.join(elements)])
	_add(list, "HELP_STONES", [economy.stones_per_hand_left, economy.interest_step, economy.interest_cap])
	_add(list, "HELP_SHOP", [shop.max_artifacts, shop.max_pills, roundi(economy.sell_fraction * 100.0)])
	_add(list, "HELP_TRIBULATION", [])
	return list


## Les sections empilees : titre en legende, corps en texte, a la largeur du rouleau.
static func build(content: GameContent) -> VBoxContainer:
	var column := VBoxContainer.new()
	for section: PackedStringArray in sections(content):
		var title := SideColumn.make_label(&"ScrollCaption", section[0])
		title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		column.add_child(title)
		var body := SideColumn.make_label(&"ScrollText", section[1])
		body.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_child(body)
		var gap := Control.new()
		gap.custom_minimum_size.y = column.get_theme_constant(&"separation", &"ScrollPanel")
		column.add_child(gap)
	return column


## Le rouleau complet : les sections dans un cadre qui defile.
static func scroll(content: GameContent) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var body := build(content)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	scroll.custom_minimum_size = Vector2(scroll.get_theme_constant(&"info_width", &"ScrollPanel"),
		scroll.get_theme_constant(&"tab_height", &"ScrollPanel"))
	return scroll


static func _add(list: Array[PackedStringArray], prefix: String, values: Array) -> void:
	var body := TranslationServer.translate(prefix + "_BODY")
	list.append(PackedStringArray([TranslationServer.translate(prefix + "_TITLE"), body % values if not values.is_empty() else body]))
