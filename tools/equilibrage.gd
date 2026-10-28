extends SceneTree
## Equilibrage : mesure la rarete exacte des mains et le joueur de reference, applique les formules de
## BalanceModel et ecrit les valeurs dans le contenu (Qi, Comprehension, niveaux et priorite des mains, prix des
## artefacts et manuels, goulots, scores de base des royaumes), plus un rapport.
## Lancer apres tout changement de mains, de paquet, d'objets ou de royaumes (une quinzaine de minutes) :
##   godot --headless --path . -s tools/equilibrage.gd
## Parametres : content/rules/equilibrage.tres. Explications : docs/equilibrage.md.

const RULES_PATH := "res://content/rules/equilibrage.tres"
const MEASURES_PATH := "res://content/rules/mesures_equilibrage.tres"
const REPORT_PATH := "res://docs/equilibrage-rapport.md"


func _initialize() -> void:
	var start := Time.get_ticks_msec()
	var rules: BalanceRules = load(RULES_PATH)
	var content := GameContent.load_default()
	var measures := BalanceMeasures.new()
	# Les mains d'abord : le joueur de reference est mesure avec leurs nouvelles valeurs.
	measures.hand_rarities.assign(HandRarity.exact(content.starter_deck, content.hands, rules.hand_draw_size))
	print("Rarete des mains mesuree en %.1f s" % ((Time.get_ticks_msec() - start) / 1000.0))
	var hand_values := BalanceModel.solve_hands(rules, measures, content.hands)
	for hand: HandDefinition in content.hands:
		if not hand_values.has(hand.id):
			continue
		var values: Dictionary = hand_values[hand.id]
		hand.priority = values["priority"]
		hand.base_qi = values["qi"]
		hand.base_comprehension = values["comprehension"]
		hand.level_qi = values["level_qi"]
		hand.level_comprehension = values["level_comprehension"]
		for key: String in ["priority", "base_qi", "base_comprehension", "level_qi", "level_comprehension"]:
			_set_value(hand.resource_path, key, str(hand.get(key)))
	var player := ReferencePlayer.new(content.starter_deck, content.round_rules, content.hands)
	@warning_ignore("integer_division")
	var rounds: int = maxi(1, rules.samples / content.round_rules.hands_per_round)

	var counts := {}
	var base := player.round_scores(rounds, rules.random_seed, [], HandLevels.new(), counts)
	var base_mean := _mean(base)
	base.sort()
	measures.round_scores = base
	measures.mean_hand_score = base_mean / content.round_rules.hands_per_round
	for hand_id: String in counts:
		measures.hand_frequencies[hand_id] = counts[hand_id] / float(rounds * content.round_rules.hands_per_round)
	for artifact: ArtifactDefinition in content.artifacts:
		var with_artifact: Array[ArtifactDefinition] = [artifact]
		measures.gains[artifact.id] = _mean(player.round_scores(rounds, rules.random_seed, with_artifact)) / base_mean - 1.0
		print("%-32s %+.3f" % [artifact.id, measures.gains[artifact.id]])
	for manual: ManualDefinition in content.manuals:
		var levels := HandLevels.new()
		levels.level_up(manual.hand.id)
		measures.gains[manual.id] = _mean(player.round_scores(rounds, rules.random_seed, [], levels)) / base_mean - 1.0
		print("%-32s %+.3f" % [manual.id, measures.gains[manual.id]])
	measures.content_signature = BalanceModel.content_signature(content, rules)
	_save(measures, MEASURES_PATH)

	var realms := content.realms.duplicate()
	realms.sort_custom(func(a: RealmDefinition, b: RealmDefinition) -> bool: return a.order < b.order)
	var solved := BalanceModel.solve(rules, measures, content.economy, realms, content.artifacts, content.manuals)
	for artifact: ArtifactDefinition in content.artifacts:
		_set_value(artifact.resource_path, "price", str(solved["prices"][artifact.id]))
	for manual: ManualDefinition in content.manuals:
		_set_value(manual.resource_path, "price", str(solved["prices"][manual.id]))
	for r: int in realms.size():
		for b: int in realms[r].bottlenecks.size():
			var path: String = realms[r].bottlenecks[b].resource_path
			_set_value(path, "score_multiplier", str(float(solved["bottlenecks"][r][b][0])))
			_set_value(path, "reward", str(solved["bottlenecks"][r][b][1]))
		_set_value(realms[r].resource_path, "base_score", str(solved["realms"][r]))
	_write_report(rules, measures, solved, content, realms, hand_values)
	print("Equilibrage ecrit en %.1f s" % ((Time.get_ticks_msec() - start) / 1000.0))
	quit()


func _mean(values: PackedFloat32Array) -> float:
	var total := 0.0
	for value: float in values:
		total += value
	return total / maxi(1, values.size())


## Remplace la ligne « key = ... » du bloc [resource] (le dernier du .tres), ou l'ajoute a la fin.
## Le reste du fichier ne bouge pas : ResourceSaver en headless retirerait les uid.
func _set_value(path: String, key: String, value: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	var line := RegEx.create_from_string("(?m)^%s = .*$" % key)
	if line.search(text) != null:
		text = line.sub(text, "%s = %s" % [key, value])
	else:
		text = text.rstrip("\n") + "\n%s = %s" % [key, value]
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)


func _save(resource: Resource, path: String) -> void:
	var error := ResourceSaver.save(resource, path)
	if error != OK:
		push_error("Echec de l'ecriture de %s : %s" % [path, error_string(error)])


## Rapport en Markdown pour relire les resultats sans ouvrir les .tres.
func _write_report(rules: BalanceRules, measures: BalanceMeasures, solved: Dictionary, content: GameContent,
		realms: Array, hand_values: Dictionary) -> void:
	var lines: PackedStringArray = ["# Rapport d'equilibrage", "",
		"Genere par tools/equilibrage.gd ; ne pas modifier a la main. Explications : equilibrage.md.", "",
		"## Joueur de reference au depart (%d mains, graine %d)" % [measures.round_scores.size() * content.round_rules.hands_per_round, rules.random_seed], "",
		"- Score moyen d'une main : %.0f" % measures.mean_hand_score,
		"- Score d'un round : 10 %% des joueurs sous %.0f, mediane %.0f, 90 %% sous %.0f" % [
			measures.round_score_reached_by(0.9), measures.round_score_reached_by(0.5), measures.round_score_reached_by(0.1)],
		"- Valeur d'une pierre k : +%.1f %% de score" % (solved["stone"] * 100.0), "",
		"## Objectifs", "", "| Royaume | Score de base | Goulots (objectif, pierres) | Croissance vers le suivant |",
		"| --- | --- | --- | --- |"]
	for r: int in realms.size():
		var cells: PackedStringArray = []
		for row: Array in solved["bottlenecks"][r]:
			cells.append("%d (%d)" % [roundi(solved["realms"][r] * row[0]), row[1]])
		lines.append("| %d | %d | %s | x%.2f |" % [realms[r].order, solved["realms"][r], ", ".join(cells), solved["growths"][r]])
	lines.append_array(["", "## Objets (gain mesure, prix)", "", "| Objet | Gain | Prix |", "| --- | --- | --- |"])
	for item: Resource in content.artifacts:
		lines.append("| %s | %+.1f %% | %d |" % [item.id, measures.gains[item.id] * 100.0, solved["prices"][item.id]])
	for item: Resource in content.manuals:
		lines.append("| %s | %+.1f %% | %d |" % [item.id, measures.gains[item.id] * 100.0, solved["prices"][item.id]])
	lines.append_array(["", "## Mains (rarete exacte sur %d cartes, valeurs ecrites)" % rules.hand_draw_size, "",
		"| Main | Rarete | Surprise | Qi x Comprehension | Niveau | Priorite |", "| --- | --- | --- | --- | --- | --- |"])
	var by_priority := content.hands.duplicate()
	by_priority.sort_custom(func(a: HandDefinition, b: HandDefinition) -> bool: return a.priority < b.priority)
	for hand: HandDefinition in by_priority:
		if hand_values.has(hand.id):
			var rarity: float = measures.hand_rarities[hand.id]
			lines.append("| %s | %s %% | %.2f | %d x %d | +%d / +%d | %d |" % [hand.id, String.num(rarity * 100.0, 6),
				absf(BalanceModel.surprise(rarity)), hand.base_qi, hand.base_comprehension, hand.level_qi,
				hand.level_comprehension, hand.priority])
	lines.append_array(["", "## Mains jouees par le joueur de reference", "", "| Main | Part des mains jouees |", "| --- | --- |"])
	var hands := measures.hand_frequencies.keys()
	hands.sort_custom(func(a: String, b: String) -> bool: return measures.hand_frequencies[a] > measures.hand_frequencies[b])
	for hand_id: String in hands:
		lines.append("| %s | %.1f %% |" % [hand_id, measures.hand_frequencies[hand_id] * 100.0])
	DirAccess.make_dir_recursive_absolute(REPORT_PATH.get_base_dir())
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
