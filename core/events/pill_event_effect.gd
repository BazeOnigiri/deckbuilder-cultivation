class_name PillEventEffect
extends EventEffect
## Une pilule : celle-ci, ou (null) une tiree au hasard parmi celles que la run peut creer (RunState.pill_pool).

@export var pill: PillDefinition


func blocked_reason(run: RunState) -> String:
	if run.pills.size() >= run.max_pills():
		return "EVENT_BLOCK_PILL_SLOT"
	return "" if pill != null or not run.pill_pool.is_empty() else "EVENT_BLOCK_PILL_SLOT"


func apply(run: RunState, rng: RandomNumberGenerator) -> void:
	if not blocked_reason(run).is_empty():
		return
	run.pills.append(pill if pill != null else run.pill_pool[rng.randi_range(0, run.pill_pool.size() - 1)])


func describe() -> String:
	return tr("EVENT_FX_PILL") if pill == null else tr("EVENT_FX_PILL_NAMED") % tr(pill.name_key)
