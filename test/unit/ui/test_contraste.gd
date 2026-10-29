extends GutTest
## Mode contraste eleve : le Theme de surcharge change les couleurs sans toucher aux polices.

const CONTRAST := preload("res://ui/theme/contraste.tres")


func test_couleur_de_qi_renforcee_sans_perdre_la_taille() -> void:
	var root := Control.new()
	var label := Label.new()
	label.theme_type_variation = &"QiValue"
	root.add_child(label)
	add_child_autofree(root)
	var normal := label.get_theme_color(&"font_color")
	var size := label.get_theme_font_size(&"font_size")
	root.theme = CONTRAST
	assert_ne(label.get_theme_color(&"font_color"), normal)
	assert_eq(label.get_theme_font_size(&"font_size"), size)
