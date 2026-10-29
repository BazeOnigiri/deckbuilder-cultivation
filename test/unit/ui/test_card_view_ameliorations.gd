extends GutTest
## Textes d'infobulle des cartes ameliorees et des artefacts a aura.


func test_texte_d_une_carte_cite_ses_ameliorations() -> void:
	var modifiers := CardModifierCatalog.load_default()
	var card := CardInstance.new(0, CardData.create(&"test", Element.Type.FEU, 5))
	assert_eq(CardView.modifiers_text(card), "")
	card.enhancement = modifiers.enhancements[0]
	card.talisman = modifiers.talismans[0]
	var text := CardView.tip_text(card)
	assert_string_contains(text, tr(card.enhancement.name_key))
	assert_string_contains(text, tr(card.talisman.description_key))


func test_carte_sans_rang_porte_le_nom_de_son_amelioration() -> void:
	var rock := EnhancementDefinition.new()
	rock.name_key = "ENH_ROC"
	rock.rankless = true
	var card := CardInstance.new(0, CardData.create(&"test", Element.Type.FEU, 5))
	card.enhancement = rock
	assert_eq(CardView.name_of(card), tr("ENH_ROC"))


func test_aura_d_artefact_dans_l_infobulle() -> void:
	var owner := Control.new()
	add_child_autofree(owner)
	assert_eq(ItemRow.edition_text(null, owner), "")
	var edition := EditionDefinition.new()
	edition.name_key = "AURA_VIDE"
	edition.description_key = "AURA_VIDE_DESC"
	assert_string_contains(ItemRow.edition_text(edition, owner), tr("AURA_VIDE_DESC"))
