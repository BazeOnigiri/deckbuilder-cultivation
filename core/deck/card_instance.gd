class_name CardInstance
extends RefCounted
## Une carte dans une partie. Pointe vers une CardData immuable et portera l'etat en jeu
## (ameliorations, editions) dans les features suivantes.

var uid: int
var data: CardData


func _init(p_uid: int, p_data: CardData) -> void:
	uid = p_uid
	data = p_data