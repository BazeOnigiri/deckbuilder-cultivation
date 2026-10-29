class_name CardsEventEffect
extends EventEffect
## Effet de pilule reutilise sur count cartes distinctes du paquet tirees au hasard : amelioration, aura ou talisman
## (ImbuePillEffect), carte detruite (DestroyPillEffect), copiee (CopyPillEffect), rang change (AddRankPillEffect).

@export var effect: PillEffect
@export var count: int = 1


func is_valid() -> bool:
	return effect != null and count > 0


func apply(run: RunState, rng: RandomNumberGenerator) -> void:
	var cards := run.cards()
	RngUtils.shuffle(cards, rng)
	var picked: Array[CardInstance] = []
	picked.assign(cards.slice(0, count))
	effect.apply(picked, run.deck(), run)


func describe() -> String:
	if effect is ImbuePillEffect:
		var imbue := effect as ImbuePillEffect
		var names: Array[String] = []
		for modifier: CardModifier in [imbue.enhancement, imbue.edition, imbue.talisman]:
			if modifier != null:
				names.append(tr(modifier.name_key))
		return tr("EVENT_FX_IMBUE") % [", ".join(PackedStringArray(names)), count]
	if effect is DestroyPillEffect:
		return tr("EVENT_FX_DESTROY") % count
	if effect is CopyPillEffect:
		return tr("EVENT_FX_COPY") % count
	if effect is AddRankPillEffect:
		return tr("EVENT_FX_RANK") % [(effect as AddRankPillEffect).amount, count]
	return ""
