class_name ScoreFeel
extends Resource
## Rythme et intensite de la sequence de score. Valeurs dans score_feel.tres.

## Temps laisse aux cartes jouees pour monter avant la premiere etape, en secondes.
@export var start_delay: float = 0.35
## Temps entre deux etapes du calcul.
@export var step_delay: float = 0.4
## Pause sur le total avant de rendre la main.
@export var end_delay: float = 0.9
## Duree du compteur qui defile d'une valeur a la suivante.
@export var roll_time: float = 0.25
@export var popup_rise: float = 40.0
@export var popup_time: float = 0.8
@export var popup_font_size: int = 22
@export var qi_color: Color = Color(0.372549, 0.658824, 0.541176, 1)
@export var comprehension_color: Color = Color(0.788235, 0.635294, 0.305882, 1)
## Tremblement maximal, en pixels, quand la main atteint a elle seule l'objectif du goulot.
@export var shake_max: float = 8.0
@export var shake_time: float = 0.35
## Le fond se teinte de la couleur de l'element dominant de la main, puis revient.
@export var pulse_strength: float = 0.25
@export var pulse_time: float = 1.2
## Gerbe de qi lachee par chaque carte qui compte.
@export var particle_amount: int = 18
@export var particle_lifetime: float = 0.7
## Vitesse de depart des particules, en pixels par seconde.
@export var particle_speed: float = 120.0
## Bond de l'emplacement d'un artefact qui se declenche : echelle au sommet, duree aller-retour.
@export var slot_pulse_scale: float = 1.15
@export var slot_pulse_time: float = 0.3
## Nom de la main annonce en grand sur un sceau avant le calcul : duree totale (apparition, pause, fondu), inclinaison en degres.
@export var announce_time: float = 0.8
@export var announce_tilt: float = -4.0
## Eclair du ciel quand le total tombe : opacite maximale quand la main atteint a elle seule l'objectif.
@export var flash_max: float = 0.18
@export var flash_time: float = 0.4
@export var flash_color: Color = Color(0.9098, 0.8824, 0.8157, 1)
