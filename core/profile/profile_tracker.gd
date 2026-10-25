class_name ProfileTracker
extends RefCounted
## Met a jour les statistiques en ecoutant une run. Ne sauvegarde pas : l'appelant ecoute changed.

signal changed

var _stats: ProfileStats


func _init(stats: ProfileStats) -> void:
	_stats = stats


## A appeler avant run.start(). is_new : faux pour une run reprise, deja comptee a son lancement.
func track(run: RunState, is_new: bool = true) -> void:
	if is_new:
		_stats.runs_started += 1
	run.round_started.connect(_on_round_started.bind(run))
	run.finished.connect(_on_finished)
	changed.emit()


func _on_round_started(round_state: RoundState, run: RunState) -> void:
	round_state.hand_played.connect(_on_hand_played)
	_stats.best_realm = maxi(_stats.best_realm, run.progress.current_realm().order)
	changed.emit()


func _on_hand_played(result: HandResult, score: ScoreContext) -> void:
	_stats.best_hand_score = maxi(_stats.best_hand_score, score.total())
	_stats.hands.record(result.definition.id)


func _on_finished(won: bool) -> void:
	if won:
		_stats.runs_won += 1
	changed.emit()