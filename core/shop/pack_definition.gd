class_name PackDefinition
extends Resource
## Sceau-tresor (les paquets de Balatro) : on l'achete en boutique, on l'ouvre, on garde picks objets parmi
## choices tires au hasard. Prix en donnee : l'equilibrage ne le mesure pas (docs/equilibrage.md).

## Ce que le sceau contient.
enum Kind {ARTIFACT, MANUAL, PILL, CARD}

@export var id: StringName = &""
@export var name_key: String = ""
@export var description_key: String = ""
## Caractere dessine sur le sceau (police des sceaux).
@export var glyph: String = ""
@export var kind: Kind = Kind.ARTIFACT
## Objets montres a l'ouverture, et combien on peut en garder.
@export var choices: int = 3
@export var picks: int = 1
@export var price: int = 0
## Sceau de cartes : chance que chaque carte proposee porte une amelioration, une aura, un talisman.
@export_range(0.0, 1.0) var enhancement_chance: float = 0.0
@export_range(0.0, 1.0) var edition_chance: float = 0.0
@export_range(0.0, 1.0) var talisman_chance: float = 0.0


func is_valid() -> bool:
	return (not id.is_empty() and not name_key.is_empty() and not description_key.is_empty()
		and picks > 0 and choices >= picks and price > 0)
