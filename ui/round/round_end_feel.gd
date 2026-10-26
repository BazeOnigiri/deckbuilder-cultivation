class_name RoundEndFeel
extends Resource
## Rythme de la fin d'un goulot : victoire (sceau 破, onde, pierres) et echec (fissures, encre). Valeurs dans round_end_feel.tres.

## Le sceau 破 tombe de seal_drop pixels, reste, puis s'efface : duree totale.
@export var seal_time: float = 1.1
@export var seal_drop: float = 120.0
@export var wave_time: float = 0.9
## Epaisseur de l'onde (hauteurs d'ecran) ; une seconde onde part wave_echo secondes apres.
@export var wave_width: float = 0.06
@export var wave_echo: float = 0.15
## Quand l'onde part : le ciel s'eclaire (alpha max) et le lavis se teinte d'or, puis reviennent.
@export var victory_color: Color = Color(0.7882, 0.651, 0.3529, 1)
@export var victory_flash: float = 0.3
@export var victory_flash_time: float = 0.6
@export var victory_pulse: float = 0.6
@export var victory_pulse_time: float = 1.6
## Cristaux de pierres qui tombent sur le compteur : un par pierre gagnee, au plus crystal_max.
@export var crystal_max: int = 10
@export var crystal_time: float = 0.5
@export var crystal_stagger: float = 0.05
@export var crystal_size: float = 10.0
## Hauteur de depart des cristaux au-dessus du compteur, en pixels.
@export var crystal_fall: float = 160.0
## Bond du compteur de pierres quand les cristaux arrivent.
@export var stones_bump: float = 1.25
@export var defeat_time: float = 2.4
