class_name GameContent
extends RefCounted
## Tout le contenu du jeu, charge une fois : paquet de depart, regles, catalogues.
## Possede par main et injecte dans les ecrans, puis dans la sauvegarde.

const DECK_PATH := "res://content/decks/paquet_depart.tres"
const ROUND_RULES_PATH := "res://content/rules/regles_base.tres"
const ECONOMY_PATH := "res://content/rules/economie_base.tres"
const SHOP_RULES_PATH := "res://content/rules/boutique_base.tres"
const PROFILE_RULES_PATH := "res://content/rules/profil_base.tres"

var starter_deck: DeckDefinition
var round_rules: RoundRules
var economy: EconomyRules
var shop_rules: ShopRules
var profile_rules: ProfileRules
var hands: Array[HandDefinition]
var realms: Array[RealmDefinition]
var artifacts: Array[ArtifactDefinition]
var manuals: Array[ManualDefinition]
var pills: Array[PillDefinition]
var packs: Array[PackDefinition]
var legacies: Array[LegacyDefinition]
## Ameliorations, auras et talismans des cartes.
var modifiers := CardModifierCatalog.new()
var unlocks: Unlocks


static func load_default() -> GameContent:
	var content := GameContent.new()
	content.starter_deck = load(DECK_PATH)
	content.round_rules = load(ROUND_RULES_PATH)
	content.economy = load(ECONOMY_PATH)
	content.shop_rules = load(SHOP_RULES_PATH)
	content.profile_rules = load(PROFILE_RULES_PATH)
	content.hands = HandCatalog.load_definitions()
	content.realms = RealmCatalog.load_definitions()
	content.artifacts = ArtifactCatalog.load_definitions()
	content.manuals = ManualCatalog.load_definitions()
	content.pills = PillCatalog.load_definitions()
	content.packs = PackCatalog.load_definitions()
	content.legacies = LegacyCatalog.load_definitions()
	content.modifiers = CardModifierCatalog.load_default()
	content.unlocks = Unlocks.new(UnlockCatalog.load_rules(), UnlockCatalog.load_achievements())
	return content


func new_run(rng: RandomNumberGenerator) -> RunState:
	return equip(RunState.new(DeckState.new(starter_deck, rng), round_rules, HandEvaluator.new(hands), RunProgress.new(realms),
		economy))


## Donne a la run le contenu qu'elle tire elle-meme (pilules creees par un talisman).
func equip(run: RunState) -> RunState:
	run.pill_pool = pills
	run.shop_base = shop_rules
	return run


## saved : offres d'une boutique sauvegardee. Vide : nouvelles offres tirees au hasard.
## profile : la boutique ne propose que le contenu que ce profil a debloque (null : tout le contenu). Meme profil et
## meme graine donnent les memes offres : le filtre garde l'ordre des catalogues.
func new_shop(run: RunState, rng: RandomNumberGenerator, saved: Dictionary = {}, profile: ProfileStats = null) -> ShopState:
	if profile == null:
		return ShopState.new(run, artifacts, manuals, pills, packs, legacies, starter_deck, shop_rules, rng, saved, modifiers)
	var open_artifacts: Array[ArtifactDefinition] = []
	open_artifacts.assign(unlocks.open(artifacts, profile))
	var open_pills: Array[PillDefinition] = []
	open_pills.assign(unlocks.open(pills, profile))
	var open_packs: Array[PackDefinition] = []
	open_packs.assign(unlocks.open(packs, profile))
	var open_legacies: Array[LegacyDefinition] = []
	open_legacies.assign(unlocks.open(legacies, profile))
	return ShopState.new(run, open_artifacts, manuals, open_pills, open_packs, open_legacies, starter_deck, shop_rules, rng, saved, modifiers)


## Recherches par id pour la sauvegarde. Contenu retire du jeu : null.
func card_by_id(id: StringName) -> CardData:
	return _find(starter_deck.cards, id) as CardData


func artifact_by_id(id: StringName) -> ArtifactDefinition:
	return _find(artifacts, id) as ArtifactDefinition


func legacy_by_id(id: StringName) -> LegacyDefinition:
	return _find(legacies, id) as LegacyDefinition


func pill_by_id(id: StringName) -> PillDefinition:
	return _find(pills, id) as PillDefinition


## Artefact, pilule, heritage ou sceau de cet id (le contenu qui peut etre verrouille). null s'il n'existe pas.
func item_by_id(id: StringName) -> Resource:
	for list: Array in [artifacts, pills, legacies, packs]:
		var found := _find(list, id)
		if found != null:
			return found
	return null


static func _find(list: Array, id: StringName) -> Resource:
	for item: Resource in list:
		if item.id == id:
			return item
	return null