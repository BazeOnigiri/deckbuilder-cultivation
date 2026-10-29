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
## Au plus une amelioration, une aura et un talisman (null : aucun).
var enhancement: EnhancementDefinition
var edition: EditionDefinition
var talisman: TalismanDefinition


func _init(p_uid: int, p_data: CardData, p_ranks: RankRules = null) -> void:
	uid = p_uid
	ranks = p_ranks
	data = p_data
	element = p_data.element
	rank = p_data.rank


## Vrai si une pilule ou un effet a change l'element ou le rang depuis la definition.
func is_altered() -> bool:
	return element != data.element or rank != data.rank


## Qi apporte quand la carte compte : suit le rang, meme change par une pilule, sauf Qi fixe de l'amelioration.
func qi() -> int:
	if enhancement != null and enhancement.fixed_qi >= 0:
		return enhancement.fixed_qi
	return ranks.qi_of(rank) if ranks != null else rank


## Sans rang : ne forme aucune combinaison, compte toujours.
func is_rankless() -> bool:
	return enhancement != null and enhancement.rankless


## Compte pour tous les elements.
func is_wild() -> bool:
	return enhancement != null and enhancement.any_element


func has_element(type: Element.Type) -> bool:
	return is_wild() or element == type


## Nombre de fois que la carte compte quand elle est jouee : une, plus les recomptes de son talisman.
func triggers() -> int:
	return 1 + (talisman.retriggers if talisman != null else 0)


## Amelioration, aura et talisman poses, dans cet ordre.
func modifiers() -> Array[CardModifier]:
	var result: Array[CardModifier] = []
	for modifier: CardModifier in [enhancement, edition, talisman]:
		if modifier != null:
			result.append(modifier)
	return result


func copy_modifiers_from(other: CardInstance) -> void:
	enhancement = other.enhancement
	edition = other.edition
	talisman = other.talisman
