class_name RngUtils
extends RefCounted
## Utilitaires aleatoires qui utilisent toujours une RNG injectee.


## Melange Fisher-Yates. Ne pas utiliser Array.shuffle() : il passe par la RNG globale.
static func shuffle(array: Array, rng: RandomNumberGenerator) -> void:
	for i: int in range(array.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Variant = array[i]
		array[i] = array[j]
		array[j] = tmp