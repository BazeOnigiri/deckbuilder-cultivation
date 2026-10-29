class_name RuleModifier
extends Resource
## Change une regle de la run : ajoute amount a la propriete property des regles qui l'ont (RoundRules, ShopRules
## ou EconomyRules), sans descendre sous 0. Ex : hands_per_round +1, reroll_base_cost -2.

@export var property: StringName = &""
@export var amount: int = 0


func apply_to(rules: Resource) -> void:
	if property in rules:
		var current: Variant = rules.get(property)
		# Une propriete decimale (ex : sell_fraction) garde sa partie decimale.
		rules.set(property, maxf(0.0, current + amount) if current is float else maxi(0, current + amount))
