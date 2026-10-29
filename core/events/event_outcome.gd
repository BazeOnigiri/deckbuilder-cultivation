class_name EventOutcome
extends Resource
## Une issue possible d'un choix : sa chance (poids relatif), son recit montre apres coup et ses effets.

@export var weight: float = 1.0
@export var text_key: String = ""
@export var effects: Array[EventEffect] = []


func is_valid() -> bool:
	return weight > 0.0 and not text_key.is_empty() and effects.all(func(effect: EventEffect) -> bool:
		return effect != null and effect.is_valid())


func apply(run: RunState, rng: RandomNumberGenerator) -> void:
	for effect: EventEffect in effects:
		effect.apply(run, rng)


## Les effets en une ligne, « Rien » sans effet.
func describe() -> String:
	if effects.is_empty():
		return tr("EVENT_FX_NOTHING")
	return ", ".join(PackedStringArray(effects.map(func(effect: EventEffect) -> String: return effect.describe())))
