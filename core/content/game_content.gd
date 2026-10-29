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
	return content


func new_run(rng: RandomNumberGenerator) -> RunState:
	return RunState.new(DeckState.new(starter_deck, rng), round_rules, HandEvaluator.new(hands), RunProgress.new(realms), economy)


## saved : offres d'une boutique sauvegardee. Vide : nouvelles offres tirees au hasard.
func new_shop(run: RunState, rng: RandomNumberGenerator, saved: Dictionary = {}) -> ShopState:
	return ShopState.new(run, artifacts, manuals, pills, packs, legacies, starter_deck, shop_rules, rng, saved)

## Recherches par id pour la sauvegarde. Contenu retire du jeu : null.
func card_by_id(id: StringName) -> CardData:
	return _find(starter_deck.cards, id) as CardData


func artifact_by_id(id: StringName) -> ArtifactDefinition:
	return _find(artifacts, id) as ArtifactDefinition


func legacy_by_id(id: StringName) -> LegacyDefinition:
	return _find(legacies, id) as LegacyDefinition


func pill_by_id(id: StringName) -> PillDefinition:
	return _find(pills, id) as PillDefinition


static func _find(list: Array, id: StringName) -> Resource:
	for item: Resource in list:
		if item.id == id:
			return item
	return null