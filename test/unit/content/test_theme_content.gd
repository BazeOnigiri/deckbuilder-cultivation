extends GutTest

const THEME_PATH := "res://ui/theme/lavis_de_nuit.tres"
const BOLD_PATH := "res://ui/fonts/noto_serif_bold_tnum.tres"
const Contrast := preload("res://test/helpers/contrast.gd")

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


func test_contraste_texte_suffisant() -> void:
	var theme: Theme = load(THEME_PATH)
	var fond: Color = ProjectSettings.get_setting("rendering/environment/defaults/default_clear_color")
	var bouton: StyleBoxFlat = theme.get_stylebox("normal", "Button")
	assert_gt(Contrast.ratio(theme.get_color("font_color", "Label"), fond), 4.5, "texte sur fond")
	assert_gt(Contrast.ratio(theme.get_color("font_color", "Button"), bouton.bg_color), 4.5, "texte de bouton")

func test_polices_noto_ont_les_sceaux_en_secours() -> void:
	for path: String in ["res://ui/fonts/noto_serif_regular_tnum.tres", BOLD_PATH]:
		var font: FontVariation = load(path)
		assert_eq(font.fallbacks.size(), 1, "pas de police de secours : %s" % path)
		if font.fallbacks.size() == 1:
			assert_eq(font.fallbacks[0].resource_path, "res://ui/fonts/MaShanZheng-Sceaux.ttf")


func test_chaque_sinogramme_des_textes_est_dans_la_police_des_sceaux() -> void:
	var seals: FontFile = load("res://ui/fonts/MaShanZheng-Sceaux.ttf")
	var file := FileAccess.open("res://localization/textes.csv", FileAccess.READ)
	var missing := {}
	while not file.eof_reached():
		var line := file.get_csv_line()
		for column in range(1, mini(line.size(), 3)):
			for character in line[column]:
				# 0x2E80 : debut des blocs CJK, tout ce qui est en dessous est du latin
				if character.unicode_at(0) >= 0x2E80 and not seals.has_char(character.unicode_at(0)):
					missing[character] = true
	assert_eq(missing.keys(), [], "sinogrammes absents de la police des sceaux")
