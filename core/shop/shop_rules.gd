class_name ShopRules
extends Resource
## Regles de la boutique en donnees.

@export var id: StringName = &""
@export var offer_count: int = 0
@export var manual_offer_count: int = 0
@export var pill_offer_count: int = 0
@export var max_pills: int = 0
@export var reroll_base_cost: int = 0
## Le cout de relance augmente de ce montant a chaque relance, et repart de la base a chaque visite.
@export var reroll_cost_step: int = 0
@export var max_artifacts: int = 0
## Poids de tirage de chaque rarete d'artefact (ArtifactDefinition.rarity), comme Balatro : la boutique tire une
## rarete puis un artefact de cette rarete. Vide : tous les artefacts ont la meme chance.
@export var rarity_weights: PackedFloat32Array = []


func is_valid() -> bool:
	return (not id.is_empty() and offer_count > 0 and manual_offer_count >= 0 and pill_offer_count >= 0
		and max_pills >= 0 and reroll_base_cost >= 0 and reroll_cost_step >= 0
		and max_artifacts > 0 and Array(rarity_weights).all(func(weight: float) -> bool: return weight >= 0.0))