class_name LegacyDefinition
extends Resource
## Heritage 传承 (les bons de Balatro) : amelioration permanente de la run, un propose par royaume en boutique.
## Ses modificateurs s'appliquent aux regles de base (RunState.round_rules, shop_rules, economy).
## Prix en donnee : l'equilibrage ne le mesure pas (docs/equilibrage.md).

@export var id: StringName = &""
@export var name_key: String = ""
@export var description_key: String = ""
## Caractere dessine dans son emplacement (police des sceaux).
@export var glyph: String = ""
@export var price: int = 0
## Heritage a posseder avant celui-ci (amelioration d'une paire). Vide : aucun.
@export var requires: StringName = &""
@export var modifiers: Array[RuleModifier] = []


func is_valid() -> bool:
	return (not id.is_empty() and not name_key.is_empty() and not description_key.is_empty() and price > 0
		and not modifiers.is_empty() and modifiers.all(func(modifier: RuleModifier) -> bool:
			return modifier != null and not modifier.property.is_empty() and modifier.amount != 0))
