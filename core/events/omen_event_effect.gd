class_name OmenEventEffect
extends EventEffect
## Un presage de content/omens gagne comme en passant un goulot : immediat, ou en attente de son moment.

@export var omen: OmenDefinition


func is_valid() -> bool:
	return omen != null and omen.is_valid()


func apply(run: RunState, _rng: RandomNumberGenerator) -> void:
	run.take_omen(omen)


func describe() -> String:
	return tr("EVENT_FX_OMEN") % tr(omen.name_key)
