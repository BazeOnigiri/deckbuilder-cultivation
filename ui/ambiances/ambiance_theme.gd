class_name AmbianceTheme
extends Resource
## Ambiance d'un ecran : couleurs et vitesse du lavis, vignette du papier, meteo optionnelle.
## id = id du goulot (ex. tribulation_flammes) ou id special (nuit, boutique). Un fichier par ambiance dans ui/ambiances/.

@export var id: StringName = &""
@export var base_color: Color
@export var deep_color: Color
@export var ink_color: Color
@export var speed: float = 0.02
@export var vignette: float = 0.45
## Amplitude de la vignette qui respire (0 = fixe). Coupee par « Reduire les animations ».
@export var vignette_breath: float = 0.0
@export var breath_speed: float = 1.0
## Particules posees par-dessus le fond. Vide : pas de meteo.
@export var weather: PackedScene
