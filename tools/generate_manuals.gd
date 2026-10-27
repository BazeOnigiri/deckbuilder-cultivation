extends SceneTree
## Genere un manuel par main dans content/manuals/, avec sa couverture : sinogramme, couleur selon la rarete de la
## main (rang de priorite), motif. Un manuel deja la garde son prix ; un nouveau prend un prix provisoire.
## Lancer : godot --headless --path . -s tools/generate_manuals.gd, puis tools/equilibrage.gd qui fixe les prix.

const OUTPUT_DIR := "res://content/manuals"
const BALANCE_PATH := "res://content/rules/equilibrage.tres"
## Couleurs de couverture (ManualCover/colors/tier_N dans le Theme) : des plus communes aux plus rares.
const COVER_TIERS := 4
## Sinogramme de l'etiquette par main : souffle, double, couple, harmonie, trois, monter, plein, pur, quatre,
## gravir, engendrer, souverain.
const GLYPHS := {
	"main_souffle": "息", "main_paire": "双", "main_double_paire": "偶", "main_harmonie": "和",
	"main_brelan": "三", "main_ascension": "升", "main_full": "满", "main_purete": "纯", "main_carre": "四",
	"main_ascension_pure": "登", "main_cycle_engendrement": "生", "main_cinq_souverains": "尊",
}
const FALLBACK_GLYPH := "法"


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	var hands := HandCatalog.load_definitions()
	hands.sort_custom(func(a: HandDefinition, b: HandDefinition) -> bool: return a.priority < b.priority)
	for index: int in hands.size():
		var hand := hands[index]
		var suffix: String = hand.id.trim_prefix("main_")
		var path: String = OUTPUT_DIR.path_join("manuel_%s.tres" % suffix)
		var manual := ManualDefinition.new()
		manual.id = StringName("manuel_" + suffix)
		manual.hand = hand
		# Un nouveau manuel prend un prix provisoire valide : tools/equilibrage.gd le remplace par le prix mesure.
		var existing: ManualDefinition = load(path) if ResourceLoader.exists(path) else null
		manual.price = existing.price if existing != null else (load(BALANCE_PATH) as BalanceRules).min_price
		if not GLYPHS.has(hand.id):
			push_error("Pas de sinogramme pour %s : ajouter a GLYPHS (sinon %s)" % [hand.id, FALLBACK_GLYPH])
		manual.glyph = GLYPHS.get(hand.id, FALLBACK_GLYPH)
		@warning_ignore("integer_division")
		manual.tier = index * COVER_TIERS / hands.size()
		# Motifs differents d'un manuel a l'autre dans une meme couleur.
		manual.pattern = (index % ManualDefinition.Pattern.size()) as ManualDefinition.Pattern
		var error := ResourceSaver.save(manual, path)
		if error != OK:
			push_error("Echec de l'ecriture de %s : %s" % [path, error_string(error)])
	quit()