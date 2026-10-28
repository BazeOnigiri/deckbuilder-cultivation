class_name CardInstance
extends RefCounted
## Une carte dans une partie. Copie l'element et le rang de sa CardData immuable :
## pilules et effets modifient cette copie, jamais la definition partagee.

var uid: int
var data: CardData
var element: Element.Type
var rank: int
## Qi de chaque rang, pris du paquet. Absent : le Qi vaut le rang.
var ranks: RankRules


func _init(p_uid: int, p_data: CardData, p_ranks: RankRules = null) -> void:
	uid = p_uid
	ranks = p_ranks
	data = p_data
	element = p_data.element
	rank = p_data.rank


## Vrai si une pilule ou un effet a change l'element ou le rang depuis la definition.
func is_altered() -> bool:
	return element != data.element or rank != data.rank


## Qi apporte quand la carte compte : suit le rang, meme change par une pilule.
func qi() -> int:
	return ranks.qi_of(rank) if ranks != null else rank
