extends GutTest

const ARTIFACTS_DIR := "res://content/artifacts"

var _artifacts: Array[ArtifactDefinition]


func before_all() -> void:
	_artifacts = ArtifactCatalog.load_definitions(ARTIFACTS_DIR)


func test_chaque_fichier_donne_un_artefact() -> void:
	var count: int = 0
	for file_name: String in DirAccess.get_files_at(ARTIFACTS_DIR):
		if file_name.ends_with(".tres"):
			count += 1
	assert_gt(_artifacts.size(), 0)
	assert_eq(_artifacts.size(), count)


func test_tous_les_artefacts_valides() -> void:
	for artifact: ArtifactDefinition in _artifacts:
		assert_true(artifact.is_valid(), "artefact invalide : %s" % artifact.resource_path)


func test_ids_uniques() -> void:
	var ids: Dictionary = {}
	for artifact: ArtifactDefinition in _artifacts:
		assert_false(ids.has(artifact.id), "id en double : %s" % artifact.id)
		ids[artifact.id] = true


## Une faute de frappe dans hand_ids rendrait l'artefact silencieusement inutile.
func test_mains_referencees_existent() -> void:
	var hand_ids: Array[String] = []
	for hand: HandDefinition in HandCatalog.load_definitions():
		hand_ids.append(hand.id)
	for artifact: ArtifactDefinition in _artifacts:
		for effect: ArtifactEffect in artifact.effects:
			var condition := effect.condition as HandIsCondition
			if condition == null:
				continue
			for hand_id: String in condition.hand_ids:
				assert_true(hand_ids.has(hand_id), "%s : main inconnue %s" % [artifact.id, hand_id])

## Le glyphe est dessine dans l'emplacement : un seul caractere, present dans la police des sceaux, distinct des autres.
func test_glyphe_unique_et_dans_la_police() -> void:
	var font: FontFile = load("res://ui/fonts/MaShanZheng-Sceaux.ttf")
	var seen: Dictionary = {}
	for item: ArtifactDefinition in _artifacts:
		assert_eq(item.glyph.length(), 1, "glyphe d'un caractere : %s" % item.id)
		if item.glyph.length() == 1:
			assert_true(font.has_char(item.glyph.unicode_at(0)), "glyphe absent de la police : %s" % item.id)
		assert_false(seen.has(item.glyph), "glyphe en double : %s" % item.id)
		seen[item.glyph] = true
