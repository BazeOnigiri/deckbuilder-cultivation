class_name SoundCue
extends Resource
## Un son du jeu, appele par son ID (Sons.play). Fiches generees par tools/sons/generate_sounds.py dans content/sons/.

@export var id: StringName
@export var stream: AudioStream
@export var volume_db: float = 0.0
@export var bus: StringName = &"Effets"
## Variation de hauteur au hasard a chaque lecture (0.05 = plus ou moins 5 %), pour que les repetitions lassent moins.
@export var pitch_variance: float = 0.03
## Gamme en demi-tons pour play(id, step) : step 0, 1, 2... monte dans la gamme puis a l'octave. Vide : pas de gamme.
@export var scale: PackedInt32Array = []


## Rapport de hauteur de la note numero step (1 sans gamme).
func pitch_for(step: int) -> float:
	if scale.is_empty() or step <= 0:
		return 1.0
	var semitones: int = scale[step % scale.size()] + 12 * (step / scale.size())
	return pow(2.0, semitones / 12.0)
