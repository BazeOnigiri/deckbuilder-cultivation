class_name ManualDefinition
extends Resource
## Manuel de technique : fait monter une main d'un niveau. Nom et description viennent de la main.

@export var id: StringName = &""
@export var hand: HandDefinition
@export var price: int = 0

## Motif imprime sur la couverture du livre.
enum Pattern {CLOUDS, WAVES, LATTICE, COINS}

@export_group("Couverture")
## Sinogramme de l'etiquette de titre : un caractere de la police des sceaux, distinct par manuel.
@export var glyph: String = ""
## Couleur de la couverture selon la rarete de la main (0 = la plus commune), couleurs dans le Theme.
@export var tier: int = 0
@export var pattern: Pattern = Pattern.CLOUDS


func is_valid() -> bool:
	return not id.is_empty() and hand != null and price > 0