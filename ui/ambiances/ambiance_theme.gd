class_name AmbianceTheme
extends Resource
## Ambiance d'un ecran : couleurs et vitesse du lavis, vignette du papier, meteo optionnelle.
## id = id du goulot (ex. tribulation_flammes) ou id special (nuit, boutique). Un fichier par ambiance dans ui/ambiances/.

@export var id: StringName = &""
@export var base_color: Color
@export var deep_color: Color
@export var ink_color: Color
@export var speed: float = 0.02
## Forme du lavis : taille des volutes (plus grand = plus petites), deformation, force de l'encre.
@export var scale: float = 2.5
@export var warp: float = 1.5
@export var strength: float = 0.7
@export var vignette: float = 0.45
## Couleur du bord de l'ecran (noir = papier ordinaire).
@export var vignette_color: Color = Color.BLACK
## Amplitude de la vignette qui respire (0 = fixe). Coupee par « Reduire les animations ».
@export var vignette_breath: float = 0.0
@export var breath_speed: float = 1.0
## Particules posees par-dessus le fond. Vide : pas de meteo.
@export var weather: PackedScene
