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
