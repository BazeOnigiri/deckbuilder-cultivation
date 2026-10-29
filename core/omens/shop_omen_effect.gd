class_name ShopOmenEffect
extends OmenEffect
## Prochaine boutique : ses regles changees par modifiers (ex : offer_count +1), et des achats ou relances gratuits.

@export var modifiers: Array[RuleModifier] = []
@export var free_artifacts: int = 0
@export var free_packs: int = 0
@export var free_rerolls: int = 0


func timing() -> Timing:
	return Timing.NEXT_SHOP


func apply_to_shop(shop: ShopState) -> void:
	shop.add_bonus(modifiers, free_artifacts, free_packs, free_rerolls)
