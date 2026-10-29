class_name Compendium
extends RefCounted
## Tout le contenu du jeu par categorie, et ce que le joueur en a deja vu (offert en boutique ou possede).
## Le contenu vient des catalogues de GameContent : ajouter un contenu l'ajoute ici sans rien declarer.

enum Kind {ARTIFACT, PILL, MANUAL, LEGACY, PACK, TRIBULATION}

## Cle de chaque categorie dans le profil (ProfileStats.seen), dans l'ordre de Kind.
const KEYS: Array[String] = ["artifact", "pill", "manual", "legacy", "pack", "tribulation"]

var _content: GameContent
var _profile: ProfileStats


func _init(content: GameContent, profile: ProfileStats) -> void:
	_content = content
	_profile = profile


## Categorie d'un contenu, -1 s'il n'en a pas. Un goulot est une tribulation s'il porte une contrainte.
static func kind_of(item: Resource) -> int:
	if item is ArtifactDefinition:
		return Kind.ARTIFACT
	if item is PillDefinition:
		return Kind.PILL
	if item is ManualDefinition:
		return Kind.MANUAL
	if item is LegacyDefinition:
		return Kind.LEGACY
	if item is PackDefinition:
		return Kind.PACK
	if item is BottleneckDefinition and item.constraint != null:
		return Kind.TRIBULATION
	return -1


## Tous les contenus de la categorie, dans l'ordre des catalogues.
func entries(kind: Kind) -> Array[Resource]:
	var list: Array[Resource] = []
	match kind:
		Kind.ARTIFACT:
			list.assign(_content.artifacts)
		Kind.PILL:
			list.assign(_content.pills)
		Kind.MANUAL:
			list.assign(_content.manuals)
		Kind.LEGACY:
			list.assign(_content.legacies)
		Kind.PACK:
			list.assign(_content.packs)
		Kind.TRIBULATION:
			var found: Dictionary = {}
			for realm: RealmDefinition in _content.realms:
				for bottleneck: BottleneckDefinition in realm.bottlenecks:
					if bottleneck.constraint != null and not found.has(bottleneck.id):
						found[bottleneck.id] = true
						list.append(bottleneck)
	return list


func total(kind: Kind) -> int:
	return entries(kind).size()


## Verrouille et pas encore debloque par ce profil (voir Unlocks). Un contenu sans regle n'est jamais verrouille.
func is_locked(item: Resource) -> bool:
	return _content.unlocks != null and _content.unlocks.is_locked(item.id, _profile)


## Condition de deblocage de ce contenu, null s'il n'en a pas.
func unlock_condition(item: Resource) -> UnlockCondition:
	return null if _content.unlocks == null else _content.unlocks.condition_of(item.id)


func is_seen(kind: Kind, item: Resource) -> bool:
	return _profile.is_seen(KEYS[kind], item.id)


## Contenus de la categorie deja vus (un contenu retire du jeu ne compte plus).
func seen_count(kind: Kind) -> int:
	return entries(kind).filter(func(item: Resource) -> bool: return is_seen(kind, item)).size()
