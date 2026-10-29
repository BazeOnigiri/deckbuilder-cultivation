class_name RunEventEffect
extends EventEffect
## Effet immediat d'un presage reutilise tel quel (pierres, niveau de la main la plus jouee, copie amelioree d'une
## carte). Seuls les effets immediats : un effet differe passe par un presage (OmenEventEffect), sauvegarde par id.

@export var effect: OmenEffect


func is_valid() -> bool:
	return effect != null and effect.timing() == OmenEffect.Timing.NOW


func apply(run: RunState, rng: RandomNumberGenerator) -> void:
	effect.apply_now(run, rng)


func describe() -> String:
	if effect is StonesOmenEffect:
		return tr("EVENT_FX_STONES") % (effect as StonesOmenEffect).amount
	if effect is LevelHandOmenEffect:
		return tr("EVENT_FX_LEVEL") % (effect as LevelHandOmenEffect).amount
	if effect is CardOmenEffect:
		return tr("EVENT_FX_CARD_COPY")
	return ""
