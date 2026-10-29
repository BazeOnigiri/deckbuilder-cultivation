extends GutTest

const COPYRIGHTS: Array[Dictionary] = [
	{"name": "Alpha", "parts": [{"license": "Zlib"}, {"license": "MIT"}, {"license": "Zlib"}]},
	{"name": "Beta", "parts": [{"license": "MIT"}]},
	{"name": "Gamma", "parts": [{"license": "Inconnue"}]},
]
const LICENSES := {"MIT": "texte mit", "Zlib": "texte zlib", "Autre": "jamais cite"}


func test_une_ligne_par_composant_avec_licences_uniques() -> void:
	var text := ThirdPartyCredits.build(COPYRIGHTS, LICENSES)
	assert_string_contains(text, "Alpha : Zlib, MIT\nBeta : MIT\nGamma : Inconnue")


func test_texte_complet_des_licences_citees_seulement() -> void:
	var text := ThirdPartyCredits.build(COPYRIGHTS, LICENSES)
	assert_string_contains(text, "MIT\n\ntexte mit")
	assert_string_contains(text, "Zlib\n\ntexte zlib")
	assert_false("jamais cite" in text)


func test_moteur_reel_donne_des_composants() -> void:
	var text := ThirdPartyCredits.build(Engine.get_copyright_info(), Engine.get_license_info())
	assert_gt(text.length(), 1000)
