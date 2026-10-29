class_name CardModifierCatalog
extends RefCounted
## Ameliorations, auras et talismans charges depuis content/ ; tirage au hasard (RNG injectee) et sauvegarde par id.

const ENHANCEMENTS_DIR := "res://content/enhancements"
const EDITIONS_DIR := "res://content/editions"
const TALISMANS_DIR := "res://content/talismans"

var enhancements: Array[EnhancementDefinition] = []
var editions: Array[EditionDefinition] = []
var talismans: Array[TalismanDefinition] = []


static func load_default() -> CardModifierCatalog:
	var catalog := CardModifierCatalog.new()
	for res: Resource in ContentLoader.load_all(ENHANCEMENTS_DIR):
		if res is EnhancementDefinition:
			catalog.enhancements.append(res)
	for res: Resource in ContentLoader.load_all(EDITIONS_DIR):
		if res is EditionDefinition:
			catalog.editions.append(res)
	for res: Resource in ContentLoader.load_all(TALISMANS_DIR):
		if res is TalismanDefinition:
			catalog.talismans.append(res)
	return catalog


func card_editions() -> Array[EditionDefinition]:
	var result: Array[EditionDefinition] = []
	result.assign(editions.filter(func(edition: EditionDefinition) -> bool: return edition.for_cards))
	return result


func artifact_editions() -> Array[EditionDefinition]:
	var result: Array[EditionDefinition] = []
	result.assign(editions.filter(func(edition: EditionDefinition) -> bool: return edition.for_artifacts))
	return result


## Une aura tiree selon les poids. null si la liste est vide.
static func pick_edition(pool: Array[EditionDefinition], rng: RandomNumberGenerator) -> EditionDefinition:
	if pool.is_empty():
		return null
	var weights := PackedFloat32Array()
	for edition: EditionDefinition in pool:
		weights.append(edition.weight)
	return pool[rng.rand_weighted(weights)]


## Pose sur la carte, chacun avec sa chance, une amelioration, une aura et un talisman tires au hasard.
## Une chance nulle ne tire rien : la RNG ne bouge pas.
func roll_onto(card: CardInstance, rng: RandomNumberGenerator, enhancement_chance: float, edition_chance: float,
		talisman_chance: float) -> void:
	if enhancement_chance > 0.0 and not enhancements.is_empty() and rng.randf() < enhancement_chance:
		card.enhancement = enhancements[rng.randi_range(0, enhancements.size() - 1)]
	if edition_chance > 0.0 and rng.randf() < edition_chance:
		card.edition = pick_edition(card_editions(), rng)
	if talisman_chance > 0.0 and not talismans.is_empty() and rng.randf() < talisman_chance:
		card.talisman = talismans[rng.randi_range(0, talismans.size() - 1)]


## Ids des modificateurs d'une carte, "" pour aucun.
static func to_dict(card: CardInstance) -> Dictionary:
	return {"enhancement": _id(card.enhancement), "edition": _id(card.edition), "talisman": _id(card.talisman)}


## Modificateurs sauvegardes ; un id inconnu (contenu retire) laisse la carte sans ce modificateur.
func apply_dict(card: CardInstance, data: Dictionary) -> void:
	card.enhancement = _find(enhancements, data.get("enhancement")) as EnhancementDefinition
	var edition := _find(editions, data.get("edition")) as EditionDefinition
	card.edition = edition if edition != null and edition.for_cards else null
	card.talisman = _find(talismans, data.get("talisman")) as TalismanDefinition


func edition_by_id(id: Variant) -> EditionDefinition:
	return _find(editions, id) as EditionDefinition


static func _id(modifier: CardModifier) -> String:
	return "" if modifier == null else String(modifier.id)


static func _find(list: Array, id: Variant) -> Resource:
	if not id is String or id.is_empty():
		return null
	for item: Resource in list:
		if String(item.id) == id:
			return item
	return null
