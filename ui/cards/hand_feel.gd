class_name HandFeel
extends Resource
## Reglages du mouvement de la main : eventail, ressort, flottement, inclinaison. Valeurs dans hand_feel.tres.

## Espace entre deux cartes voisines, negatif = elles se chevauchent.
@export var gap: float = -8.0
## Angle des cartes aux deux bouts de l'eventail, en degres.
@export var fan_angle: float = 6.0
## Les cartes des bouts descendent de cette hauteur, en pixels : dessine un arc.
@export var arc_height: float = 12.0
@export var hover_scale: float = 1.06
## Inclinaison maximale vers la souris, en degres.
@export var tilt_max: float = 12.0
## Raideur et amortissement du ressort : sous 2 * sqrt(raideur), la carte rebondit un peu.
@export var stiffness: float = 300.0
@export var damping: float = 24.0
@export var idle_amplitude: float = 2.0
@export var idle_rotation: float = 0.6
## Vitesse du flottement, en radians par seconde.
@export var idle_speed: float = 1.5
## Point de depart d'une carte piochee, par rapport a sa place.
@export var deal_offset: Vector2 = Vector2(480, 80)
## Hauteur de la rangee des cartes jouees au-dessus de la main, en pixels.
@export var play_rise: float = 190.0
## Elan donne a l'echelle quand une carte compte : le ressort la fait rebondir.
@export var pulse_kick: float = 6.0
## Duree de la dissolution d'une carte qui quitte la main, en secondes.
@export var dissolve_time: float = 0.6
## Une carte qui se dissout monte doucement, comme de la fumee, en pixels par seconde.
@export var dissolve_drift: float = 30.0
