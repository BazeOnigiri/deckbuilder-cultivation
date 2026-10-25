extends GutTest

const THEME_PATH := "res://ui/theme/lavis_de_nuit.tres"
const BOLD_PATH := "res://ui/fonts/noto_serif_bold_tnum.tres"


func test_theme_applique_au_projet() -> void:
	var setting: String = ProjectSettings.get_setting("gui/theme/custom", "")
	assert_ne(setting, "", "aucun theme projet")
	if setting != "":
		# load() accepte res:// et uid://, on compare donc le chemin resolu
		assert_eq(load(setting).resource_path, THEME_PATH)


func test_police_par_defaut_a_chiffres_tabulaires() -> void:
	var theme: Theme = load(THEME_PATH)
	_assert_tnum(theme.default_font)


func test_variation_bold_a_chiffres_tabulaires() -> void:
	_assert_tnum(load(BOLD_PATH))


func _assert_tnum(font: Font) -> void:
	assert_true(font is FontVariation, "pas une FontVariation : %s" % font)
	if not font is FontVariation:
		return
	var tnum: int = TextServerManager.get_primary_interface().name_to_tag("tnum")
	assert_eq((font as FontVariation).opentype_features.get(tnum), 1, "tnum absent")