class_name Unlocks
extends RefCounted
## Deblocages et succes : quels contenus sont ouverts pour un profil, et ce qu'un evenement vient de gagner.
## Un deblocage ou un succes obtenu reste acquis (profil) meme si la condition ne tient plus.

var _rules: Dictionary = {}
var _achievements: Array[AchievementDefinition]


func _init(rules: Array[UnlockRule], achievements: Array[AchievementDefinition]) -> void:
	for rule: UnlockRule in rules:
		_rules[rule.content_id] = rule.condition
	_achievements = achievements


func achievements() -> Array[AchievementDefinition]:
	return _achievements


## Sans regle : toujours ouvert. Avec regle : ouvert une fois enregistre dans le profil.
func is_locked(id: StringName, profile: ProfileStats) -> bool:
	return _rules.has(id) and not profile.has_unlocked(id)


## Condition de deblocage d'un contenu, null s'il n'en a pas.
func condition_of(id: StringName) -> UnlockCondition:
	return _rules.get(id)


## Les contenus ouverts de la liste, dans le meme ordre : la boutique ne tire que dans ceux-la.
func open(list: Array, profile: ProfileStats) -> Array:
	return list.filter(func(item: Resource) -> bool: return not is_locked(item.id, profile))


## Enregistre dans le profil ce que le contexte debloque ou fait obtenir, et le renvoie :
## {"unlocked": Array[StringName], "achieved": Array[AchievementDefinition]}. Rien de neuf : deux listes vides.
func evaluate(ctx: UnlockContext) -> Dictionary:
	var unlocked: Array[StringName] = []
	var ids: Array = _rules.keys()
	ids.sort()
	for id: StringName in ids:
		if is_locked(id, ctx.profile) and _rules[id].is_met(ctx) and ctx.profile.unlock(id):
			unlocked.append(id)
	var achieved: Array[AchievementDefinition] = []
	for achievement: AchievementDefinition in _achievements:
		if not ctx.profile.has_achievement(achievement.id) and achievement.condition.is_met(ctx) and ctx.profile.achieve(achievement.id):
			achieved.append(achievement)
	return {"unlocked": unlocked, "achieved": achieved}
