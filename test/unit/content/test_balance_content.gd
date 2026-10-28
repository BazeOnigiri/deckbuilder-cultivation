extends GutTest
## Garde-fou de l'equilibrage : les valeurs ecrites dans le contenu sont celles des formules appliquees aux
## mesures. Un echec ici veut dire : relancer tools/equilibrage.gd (docs/equilibrage.md).

const RULES_PATH := "res://content/rules/equilibrage.tres"
const MEASURES_PATH := "res://content/rules/mesures_equilibrage.tres"
const HINT := " (lancer tools/equilibrage.gd)"

var _content: GameContent
var _rules: BalanceRules
var _measures: BalanceMeasures
var _realms: Array[RealmDefinition]
var _solved: Dictionary


func before_all() -> void:
	_content = GameContent.load_default()
	_rules = load(RULES_PATH)
	_measures = load(MEASURES_PATH)
	_realms = _content.realms.duplicate()
	_realms.sort_custom(func(a: RealmDefinition, b: RealmDefinition) -> bool: return a.order < b.order)
	_solved = BalanceModel.solve(_rules, _measures, _content.economy, _realms, _content.artifacts, _content.manuals)


func test_parametres_valides() -> void:
	assert_true(_rules.is_valid())
	assert_gt(_measures.round_scores.size(), 0, "mesures vides" + HINT)


## Bug : le paquet a change (45 puis 65 cartes) sans relancer l'outil, et les tests restaient verts.
func test_mesures_prises_sur_ce_contenu() -> void:
	assert_eq(_measures.content_signature, BalanceModel.content_signature(_content, _rules),
		"le contenu a change depuis la derniere mesure" + HINT)


func test_chaque_objet_est_mesure() -> void:
	for artifact: ArtifactDefinition in _content.artifacts:
		assert_true(_measures.has_gain(artifact.id), "artefact non mesure : %s%s" % [artifact.id, HINT])
	for manual: ManualDefinition in _content.manuals:
		assert_true(_measures.has_gain(manual.id), "manuel non mesure : %s%s" % [manual.id, HINT])


func test_prix_issus_de_la_courbe_de_cout() -> void:
	for artifact: ArtifactDefinition in _content.artifacts:
		assert_eq(artifact.price, _solved["prices"][artifact.id], "prix de %s%s" % [artifact.id, HINT])
	for manual: ManualDefinition in _content.manuals:
		assert_eq(manual.price, _solved["prices"][manual.id], "prix de %s%s" % [manual.id, HINT])


func test_goulots_et_royaumes_issus_des_formules() -> void:
	for r: int in _realms.size():
		assert_eq(_realms[r].base_score, _solved["realms"][r], "score de base de %s%s" % [_realms[r].id, HINT])
		for b: int in _realms[r].bottlenecks.size():
			var bottleneck := _realms[r].bottlenecks[b]
			assert_eq(bottleneck.score_multiplier, _solved["bottlenecks"][r][b][0], "multiplicateur de %s%s" % [bottleneck.id, HINT])
			assert_eq(bottleneck.reward, _solved["bottlenecks"][r][b][1], "recompense de %s%s" % [bottleneck.id, HINT])


func test_mains_issues_de_leur_rarete() -> void:
	var values := BalanceModel.solve_hands(_rules, _measures, _content.hands)
	for hand: HandDefinition in _content.hands:
		assert_true(values.has(hand.id), "main non mesuree : %s%s" % [hand.id, HINT])
		if not values.has(hand.id):
			continue
		var expected: Dictionary = values[hand.id]
		assert_eq([hand.priority, hand.base_qi, hand.base_comprehension, hand.level_qi, hand.level_comprehension],
			[expected["priority"], expected["qi"], expected["comprehension"], expected["level_qi"],
			expected["level_comprehension"]], "valeurs de %s%s" % [hand.id, HINT])


## Une main plus rare a une priorite plus haute et une base au moins aussi forte.
func test_mains_ordonnees_par_rarete() -> void:
	for a: HandDefinition in _content.hands:
		for b: HandDefinition in _content.hands:
			if _measures.hand_rarities.get(a.id, 0.0) < _measures.hand_rarities.get(b.id, 0.0):
				assert_gt(a.priority, b.priority, "%s plus rare que %s" % [a.id, b.id])
				assert_gte(a.base_qi * a.base_comprehension, b.base_qi * b.base_comprehension)


## Chaque royaume est plus dur que le precedent, meme son premier goulot face au dernier du royaume d'avant.
func test_progression_croissante() -> void:
	for r: int in range(1, _realms.size()):
		var previous := _realms[r - 1]
		var last := previous.base_score * previous.bottlenecks[-1].score_multiplier
		assert_gt(_realms[r].base_score * _realms[r].bottlenecks[0].score_multiplier, last, String(_realms[r].id))
