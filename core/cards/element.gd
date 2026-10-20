# res://core/cards/element.gd
class_name Element
extends RefCounted
## Les cinq éléments du jeu.
## Ajouter de nouvelles valeurs à la fin uniquement, ne jamais réordonner :
## les fichiers .tres stockent l'index entier de l'enum, pas son nom.

enum Type {BOIS, FEU, TERRE, METAL, EAU}


## Identifiant texte stable d'un élément, utilisé dans les IDs de contenu
## (ex : "carte_bois_7") et dans les sauvegardes.
static func to_id(type: Type) -> StringName:
	match type:
		Type.BOIS:
			return &"bois"
		Type.FEU:
			return &"feu"
		Type.TERRE:
			return &"terre"
		Type.METAL:
			return &"metal"
		Type.EAU:
			return &"eau"
	push_error("Element.to_id : type inconnu %d" % type)
	return &""