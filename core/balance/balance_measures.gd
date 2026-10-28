class_name BalanceMeasures
extends Resource
## Mesures du joueur de reference, ecrites par tools/equilibrage.gd (content/rules/mesures_equilibrage.tres).
## Ne pas modifier a la main : relancer l'outil apres tout changement de mains, de paquet ou d'objets.

## Scores d'un round au depart (sans objet), tries : sert aux quantiles.
@export var round_scores: PackedFloat32Array = []
## Score moyen d'une main au depart.
@export var mean_hand_score: float = 0.0
## Gain moyen relatif de chaque objet seul : E[score avec] / E[score sans] - 1, par id.
@export var gains: Dictionary[StringName, float] = {}
## Part des mains jouees par type de main, par id (rapport, aide a regler les mains).
@export var hand_frequencies: Dictionary[String, float] = {}
## Empreinte du contenu mesure (BalanceModel.content_signature) : un contenu different rend ces mesures perimees.
@export var content_signature: String = ""
## Pierres que rapporte chaque artefact a pierres sur yield_bottlenecks goulots, par id (BalanceModel.stone_yield).
@export var stone_yields: Dictionary = {}
## Rarete exacte de chaque main, par id : part des tirages de hand_draw_size cartes qui la contiennent.
@export var hand_rarities: Dictionary[String, float] = {}


## Score d'un round atteint par la part success des joueurs (quantile 1 - success).
func round_score_reached_by(success: float) -> float:
	if round_scores.is_empty():
		return 0.0
	# Marge : 1 - 0.9 vaut 0.0999... en flottant, l'indice tomberait un cran trop bas.
	var index := clampi(floori((1.0 - success) * round_scores.size() + 1e-6), 0, round_scores.size() - 1)
	return round_scores[index]


func has_gain(id: StringName) -> bool:
	return gains.has(id)
