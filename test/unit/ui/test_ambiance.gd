extends GutTest
## Fond lavis et papier : charges pour tout le jeu, ne captent pas la souris, texte lisible par-dessus.

const Contrast := preload("res://test/helpers/contrast.gd")
const SCENE := preload("res://ui/theme/ambiance.tscn")
const THEME_PATH := "res://ui/theme/lavis_de_nuit.tres"
const LAVIS_COLORS := ["base_color", "deep_color", "ink_color"]


func test_ambiance_chargee_pour_tout_le_jeu() -> void:
	assert_eq(ProjectSettings.get_setting("autoload/Ambiance", ""), "*res://ui/theme/ambiance.tscn")


func test_fond_derriere_et_papier_devant() -> void:
	var ambiance: Node = add_child_autofree(SCENE.instantiate())
	assert_lt((ambiance.get_node("Fond") as CanvasLayer).layer, 0)
	assert_gt((ambiance.get_node("Dessus") as CanvasLayer).layer, 0)
	for path: String in ["Fond/Lavis", "Dessus/Papier"]:
		var rect := ambiance.get_node(path) as ColorRect
		assert_true(rect.material is ShaderMaterial, "%s sans shader" % path)
		assert_eq(rect.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s capte la souris" % path)


func test_texte_lisible_sur_le_lavis() -> void:
	var theme: Theme = load(THEME_PATH)
	var texte: Color = theme.get_color("font_color", "Label")
	var material: ShaderMaterial = load("res://ui/theme/lavis.tres")
	for uniform: String in LAVIS_COLORS:
		var fond: Color = material.get_shader_parameter(uniform)
		assert_gt(Contrast.ratio(texte, fond), 4.5, "texte sur %s" % uniform)


func test_texte_lisible_quand_le_fond_prend_la_couleur_d_un_element() -> void:
	var theme: Theme = load(THEME_PATH)
	var texte: Color = theme.get_color("font_color", "Label")
	var material: ShaderMaterial = load("res://ui/theme/lavis.tres")
	var ink: Color = material.get_shader_parameter("ink_color")
	var strength: float = (load("res://ui/round/score_feel.tres") as ScoreFeel).pulse_strength
	for element: Element.Type in Element.Type.values():
		# Pire cas du shader : la zone d'encre la plus dense, au plus fort de la teinte.
		var fond := ink.lerp(ElementStyles.of(element).color, strength)
		assert_gt(Contrast.ratio(texte, fond), 4.5, "texte sur le lavis teinte %s" % Element.to_id(element))
