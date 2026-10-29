class_name OmenEffect
extends Resource
## Effet d'un presage. Les sous-classes surchargent timing() et la methode du moment ou elles agissent.

enum Timing {
	NOW, ## des que le presage est gagne (apply_now)
	NEXT_SHOP, ## a la creation de la prochaine boutique (apply_to_shop)
	NEXT_REWARD, ## a la recompense du prochain goulot franchi (apply_to_reward)
}


func timing() -> Timing:
	return Timing.NOW


func apply_now(_run: RunState, _rng: RandomNumberGenerator) -> void:
	pass


func apply_to_shop(_shop: ShopState) -> void:
	pass


func apply_to_reward(_reward: RoundReward) -> void:
	pass
