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
## Prix d'un artefact typique (gain median) : fixe la valeur d'une pierre (score qu'elle achete), commune a tous les objets.
@export var mean_artifact_price: float = 6.0
@export var min_price: int = 1
## Recompense d'un goulot = base + par_difficulte x multiplicateur du goulot.
@export var reward_base: float = 1.0
@export var reward_per_difficulty: float = 2.0


func is_valid() -> bool:
	return (not id.is_empty() and samples > 0 and reference_hands_left >= 0 and reference_savings >= 0
		and first_bottleneck_success > 0.0 and first_bottleneck_success < 1.0 and pressure > 0.0
		and bottleneck_step >= 0.0 and significant_digits > 0 and mean_artifact_price > 0.0 and min_price > 0)
