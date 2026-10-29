class_name ChallengeDefinition
extends Resource
## Defi : une partie aux regles fixes. Tout est en donnees : graine, difficulte, objets et heritages de depart,
## paquet, interdictions (modificateurs de regles, ex. offer_count -2 : boutique sans marchandise).

@export var id: StringName = &""
@export var name_key: String = ""
@export var description_key: String = ""
## Graine imposee, en texte. Vide : graine tiree au hasard.
@export var seed_text: String = ""
@export var difficulty: int = 1
## Faux : chaque royaume garde sa tribulation du contenu (ordre classique).
@export var random_tribulations: bool = true
@export var artifacts: Array[ArtifactDefinition] = []
@export var pills: Array[PillDefinition] = []
@export var legacies: Array[LegacyDefinition] = []
## Paquet de depart du defi, fait de cartes du paquet habituel (la sauvegarde les retrouve par id). Vide : le
## paquet habituel.
@export var deck: DeckDefinition
## Regles du defi, appliquees apres celles de la difficulte.
@export var modifiers: Array[RuleModifier] = []


func is_valid() -> bool:
	return (not id.is_empty() and not name_key.is_empty() and not description_key.is_empty() and difficulty >= 1
		and not artifacts.has(null) and not pills.has(null) and not legacies.has(null)
		and (deck == null or deck.is_valid())
		and modifiers.all(func(modifier: RuleModifier) -> bool:
			return modifier != null and not modifier.property.is_empty() and modifier.amount != 0))
