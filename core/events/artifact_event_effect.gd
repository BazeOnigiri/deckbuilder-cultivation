class_name ArtifactEventEffect
extends EventEffect
## Un artefact pas encore possede, tire selon sa rarete comme en boutique (ShopRules.rarity_weights).


func blocked_reason(run: RunState) -> String:
	if run.artifact_slots_used() >= run.max_artifacts():
		return "EVENT_BLOCK_ARTIFACT_SLOT"
	return "" if not _pool(run).is_empty() else "EVENT_BLOCK_NO_ARTIFACT"


func apply(run: RunState, rng: RandomNumberGenerator) -> void:
	if not blocked_reason(run).is_empty():
		return
	var drawn := ShopState.draw_artifacts(_pool(run), 1, run.shop_rules(run.shop_base).rarity_weights, rng)
	run.add_artifact(drawn[0])


func describe() -> String:
	return tr("EVENT_FX_ARTIFACT")


static func _pool(run: RunState) -> Array[ArtifactDefinition]:
	var pool: Array[ArtifactDefinition] = []
	for artifact: ArtifactDefinition in run.artifact_pool:
		if not run.artifacts.any(func(owned: ArtifactDefinition) -> bool: return owned.id == artifact.id):
			pool.append(artifact)
	return pool
