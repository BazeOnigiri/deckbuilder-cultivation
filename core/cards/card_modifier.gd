class_name CardModifier
extends Resource
## Base des ameliorations, auras et talismans : un contenu pose sur une carte (une aura peut aussi luire sur un
## artefact). Une carte porte au plus un de chaque. Ajouter un modificateur = ajouter un .tres, sans code.

@export var id: StringName = &""
@export var name_key: String = ""
@export var description_key: String = ""
## Caractere dessine sur la carte (police des sceaux, ui/fonts/MaShanZheng-Sceaux.ttf).
@export var glyph: String = ""
## Teinte du dessin : motif d'une amelioration, lueur d'une aura, cachet d'un talisman.
@export var color: Color = Color.WHITE


func is_valid() -> bool:
	return not id.is_empty() and not name_key.is_empty() and not description_key.is_empty() and glyph.length() == 1
