class_name ProfileTracker
extends RefCounted
## Met a jour les statistiques en ecoutant une run. Ne sauvegarde pas : l'appelant ecoute changed.

signal changed
## Un contenu verrouille vient de s'ouvrir, un succes vient d'etre obtenu.
signal unlocked(id: StringName)
signal achieved(achievement: AchievementDefinition)

## Date des parties, en secondes Unix. Remplacee par les tests.
var clock: Callable = func() -> float: return Time.get_unix_time_from_system()

## Deblocages et succes gagnes depuis le dernier bilan, dans l'ordre : le bilan de fin de partie les montre puis les vide.
var pending_unlocks: Array[StringName] = []
var pending_achievements: Array[AchievementDefinition] = []

var _stats: ProfileStats
var _rules: ProfileRules
## null : pas de deblocages ni de succes (tests, outils).
var _unlocks: Unlocks
var _run: RunState
var _purchases: int = 0
var _one_hand_clears: int = 0
var _round_hands: int = 0


func _init(stats: ProfileStats, rules: ProfileRules = null, unlocks: Unlocks = null) -> void:
	_stats = stats
	_rules = rules if rules != null else ProfileRules.new()
	_unlocks = unlocks


## A appeler avant run.start(). is_new : faux pour une run reprise, deja comptee a son lancement.
func track(run: RunState, is_new: bool = true) -> void:
	if is_new:
		_stats.runs_started += 1
	run.round_started.connect(_on_round_started.bind(run))
	run.finished.connect(_on_finished.bind(run))
	_run = run
	_one_hand_clears = 0
	# Run reprise : les achats d'avant la sauvegarde sont inconnus, on suppose le pire pour « sans achat ».
	_purchases = 0 if is_new else 1
	_mark_owned(run)
	_evaluate()
	changed.emit()


## A appeler pour chaque boutique ouverte : ce qu'elle montre est vu, ses achats d'artefacts sont comptes.
func track_shop(shop: ShopState) -> void:
	shop.artifact_bought.connect(_on_artifact_bought)
	shop.offers_changed.connect(func() -> void: _mark_all(shop.offered()))
	_mark_all(shop.offered())


func _on_round_started(round_state: RoundState, run: RunState) -> void:
	round_state.hand_played.connect(_on_hand_played)
	_stats.best_realm = maxi(_stats.best_realm, run.progress.current_realm().order)
	_round_hands = 0
	var bottleneck := run.progress.current_bottleneck()
	_mark(bottleneck)
	# Le goulot est retenu maintenant : la run avance des la fin du round, avant ce signal.
	round_state.finished.connect(_on_round_finished.bind(bottleneck))
	_mark_owned(run)
	_evaluate()
	changed.emit()


func _on_hand_played(result: HandResult, score: ScoreContext) -> void:
	_stats.best_hand_score = maxi(_stats.best_hand_score, score.total())
	_stats.hands.record(result.definition.id)
	_round_hands += 1
	_evaluate()
	changed.emit()


func _on_round_finished(won: bool, bottleneck: BottleneckDefinition) -> void:
	if bottleneck.constraint != null:
		_stats.record_tribulation(bottleneck.id, won)
	if won and _round_hands == 1:
		_one_hand_clears += 1
	_evaluate()


func _on_artifact_bought(artifact: ArtifactDefinition) -> void:
	_stats.record_purchase(artifact.id)
	_purchases += 1
	_evaluate()
	changed.emit()


func _on_finished(won: bool, run: RunState) -> void:
	if won:
		_stats.runs_won += 1
	_stats.add_game(_record_of(run, won), _rules.history_size)
	_evaluate(won)
	changed.emit()


## Cherche ce que l'etat actuel de la partie et du profil debloque ou fait obtenir.
func _evaluate(won: bool = false) -> void:
	if _unlocks == null:
		return
	var ctx := UnlockContext.new(_stats, _run)
	ctx.won = won
	ctx.purchases = _purchases
	ctx.one_hand_clears = _one_hand_clears
	var found := _unlocks.evaluate(ctx)
	for id: StringName in found["unlocked"]:
		pending_unlocks.append(id)
		unlocked.emit(id)
	for achievement: AchievementDefinition in found["achieved"]:
		pending_achievements.append(achievement)
		achieved.emit(achievement)


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
