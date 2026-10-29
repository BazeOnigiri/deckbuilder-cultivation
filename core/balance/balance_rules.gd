class_name BalanceRules
extends Resource
## Parametres de l'equilibrage : chacun a un sens de jeu, aucun n'est un resultat.
## Les objectifs, prix et recompenses en decoulent par les formules de BalanceModel (docs/equilibrage.md).

@export var id: StringName = &""

@export_group("Joueur de reference")
## Mains simulees par mesure. Plus il y en a, moins le hasard pese sur les mesures (erreur en 1 / racine de n).
@export var samples: int = 2000
## Graine de la simulation : memes mesures a chaque lancement.
@export var random_seed: int = 1
## Mains qu'il lui reste en moyenne quand il franchit un goulot (pierres de mains restantes).
@export var reference_hands_left: int = 1
## Pierres qu'il garde d'une boutique a l'autre (elles rapportent des interets).
@export var reference_savings: int = 10
## Tribulations seulement : il defausse quand sa meilleure main a au plus cette priorite (20 : Souffle et Paire),
## pour que les contraintes sur les defausses (karma, foudre) pesent dans la mesure.
@export var reference_discard_priority: int = 20

@export_group("Objectifs")
## Part des joueurs de reference qui franchissent le premier goulot sans objet ni defausse.
@export_range(0.5, 0.99) var first_bottleneck_success: float = 0.9
## Combien la difficulte va plus vite que la puissance du joueur, a chaque royaume (1 = au meme rythme).
@export var pressure: float = 1.25
## Chaque goulot d'un royaume demande ce surplus de plus que le premier (0.5 : x1, x1.5, x2).
@export var bottleneck_step: float = 0.5
## Chiffres gardes dans les objectifs, pour la lisibilite (1 117 devient 1 100).
@export var significant_digits: int = 2

@export_group("Prix et recompenses")
## Puissance du joueur apres avoir depense les pierres d'un royaume (2 = il double son score) :
## fixe la valeur d'une pierre, donc tous les prix, sans dependre de la liste des objets.
@export var power_per_realm: float = 2.0
@export var min_price: int = 1
## Recompense d'un goulot = base + par_difficulte x multiplicateur du goulot.
@export var reward_base: float = 1.0
@export var reward_per_difficulty: float = 2.0

@export_group("Artefacts a pierres et qui grandissent")
## Goulots pendant lesquels le joueur garde un artefact en moyenne : un artefact a pierres vaut ce qu'il rapporte
## sur cette duree.
@export var yield_bottlenecks: int = 3
## Cartes defaussees par goulot en moyenne (le joueur de reference ne defausse pas).
@export var reference_discarded_cards: int = 4
## Crans d'un artefact qui grandit, en moyenne sur la duree ou on le garde : il est mesure avec ces crans.
@export var reference_growth_stacks: int = 6

@export_group("Raretes des artefacts")
## Part des artefacts dans chaque rarete, du gain le plus faible au plus fort (Mortel, Spirituel, Celeste, Divin).
@export var rarity_shares: PackedFloat32Array = [0.5, 0.3, 0.15, 0.05]

@export_group("Mains")
## Cartes d'un tirage pour mesurer la rarete d'une main : la taille d'une main jouee.
@export var hand_draw_size: int = 5
## Force de base (Qi x Comprehension) de la main la plus commune et de la plus rare : les autres s'etalent
## entre les deux selon leur rarete.
@export var weakest_hand_strength: float = 5.0
@export var strongest_hand_strength: float = 1800.0
## Part de la force portee par la Comprehension : C = (force / force la plus faible)^exposant.
## 0 : tout en Qi ; 0.5 : Qi et Comprehension grandissent autant.
@export_range(0.0, 1.0) var comprehension_exponent: float = 0.4
## Un niveau de main ajoute cette part de sa base, en Qi et en Comprehension.
@export var level_fraction: float = 0.3
## Ecart entre deux priorites de main (la plus forte gagne quand une main en remplit plusieurs).
@export var priority_step: int = 10


func is_valid() -> bool:
	return (not id.is_empty() and samples > 0 and reference_hands_left >= 0 and reference_savings >= 0
		and first_bottleneck_success > 0.0 and first_bottleneck_success < 1.0 and pressure > 0.0
		and bottleneck_step >= 0.0 and significant_digits > 0 and power_per_realm > 1.0 and min_price > 0
		and hand_draw_size > 0 and weakest_hand_strength > 0.0 and strongest_hand_strength > weakest_hand_strength
		and level_fraction >= 0.0 and priority_step > 0 and not rarity_shares.is_empty()
		and is_equal_approx(Array(rarity_shares).reduce(func(sum: float, share: float) -> float: return sum + share, 0.0), 1.0))
