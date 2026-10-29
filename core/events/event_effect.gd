class_name EventEffect
extends Resource
## Effet d'une issue de rencontre. Les sous-classes enveloppent les effets existants (presages, pilules) ou tirent un
## contenu de la run (artefact, pilule).


func is_valid() -> bool:
	return true


## Cle du texte qui dit pourquoi l'effet ne peut pas agir (emplacements pleins...), "" s'il le peut.
func blocked_reason(_run: RunState) -> String:
	return ""


func apply(_run: RunState, _rng: RandomNumberGenerator) -> void:
	pass


## Ce que fait l'effet, pour le joueur.
func describe() -> String:
	return ""
