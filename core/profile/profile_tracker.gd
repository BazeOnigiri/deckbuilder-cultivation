class_name ProfileTracker
extends RefCounted
## Met a jour les statistiques en ecoutant une run. Ne sauvegarde pas : l'appelant ecoute changed.

signal changed

## Date des parties, en secondes Unix. Remplacee par les tests.
var clock: Callable = func() -> float: return Time.get_unix_time_from_system()

var _stats: ProfileStats
var _rules: ProfileRules


func _init(stats: ProfileStats, rules: ProfileRules = null) -> void:
	_stats = stats
	_rules = rules if rules != null else ProfileRules.new()


## A appeler avant run.start(). is_new : faux pour une run reprise, deja comptee a son lancement.
func track(run: RunState, is_new: bool = true) -> void:
	if is_new:
		_stats.runs_started += 1
	run.round_started.connect(_on_round_started.bind(run))
	run.finished.connect(_on_finished.bind(run))
	_mark_owned(run)
	changed.emit()


## A appeler pour chaque boutique ouverte : ce qu'elle montre est vu, ses achats d'artefacts sont comptes.
func track_shop(shop: ShopState) -> void:
	shop.artifact_bought.connect(_on_artifact_bought)
	shop.offers_changed.connect(func() -> void: _mark_all(shop.offered()))
	_mark_all(shop.offered())


func _on_round_started(round_state: RoundState, run: RunState) -> void:
	round_state.hand_played.connect(_on_hand_played)
	_stats.best_realm = maxi(_stats.best_realm, run.progress.current_realm().order)
	var bottleneck := run.progress.current_bottleneck()
	_mark(bottleneck)
	# Le goulot est retenu maintenant : la run avance des la fin du round, avant ce signal.
	round_state.finished.connect(_on_round_finished.bind(bottleneck))
	_mark_owned(run)
	changed.emit()


func _on_hand_played(result: HandResult, score: ScoreContext) -> void:
	_stats.best_hand_score = maxi(_stats.best_hand_score, score.total())
	_stats.hands.record(result.definition.id)
	changed.emit()


func _on_round_finished(won: bool, bottleneck: BottleneckDefinition) -> void:
	if bottleneck.constraint != null:
		_stats.record_tribulation(bottleneck.id, won)


func _on_artifact_bought(artifact: ArtifactDefinition) -> void:
	_stats.record_purchase(artifact.id)
	changed.emit()


func _on_finished(won: bool, run: RunState) -> void:
	if won:
		_stats.runs_won += 1
	_stats.add_game(_record_of(run, won), _rules.history_size)
	changed.emit()


func _record_of(run: RunState, won: bool) -> GameRecord:
	var record := GameRecord.new()
	record.played_at = int(clock.call())
	record.won = won
	record.realm_id = String(run.progress.current_realm().id)
	record.bottleneck_id = String(run.progress.current_bottleneck().id)
	record.bottlenecks_cleared = run.stats.bottlenecks_cleared
	record.best_hand_score = run.stats.best_hand_score
	record.best_hand_id = run.stats.best_hand_id
	record.favorite_hand_id = run.stats.hands.most_played()
	record.artifacts = SaveData.ids(run.artifacts)
	record.legacies = SaveData.ids(run.legacies)
	record.seed_text = "" if run.seed_value == 0 else str(run.seed_value)
	return record


## Ce que la run possede a ete vu, meme sans passer par la boutique (run reprise, artefact de debug).
func _mark_owned(run: RunState) -> void:
	var owned: Array[Resource] = []
	owned.append_array(run.artifacts)
	owned.append_array(run.pills)
	owned.append_array(run.legacies)
	_mark_all(owned)


func _mark_all(items: Array[Resource]) -> void:
	var added := false
	for item: Resource in items:
		added = _mark(item) or added
	if added:
		changed.emit()


## Vrai si ce contenu n'avait jamais ete vu.
func _mark(item: Resource) -> bool:
	var kind := Compendium.kind_of(item)
	return kind >= 0 and _stats.mark_seen(Compendium.KEYS[kind], item.id)
