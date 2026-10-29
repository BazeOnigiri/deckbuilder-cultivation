class_name GameContent
extends RefCounted
## Tout le contenu du jeu, charge une fois : paquet de depart, regles, catalogues.
## Possede par main et injecte dans les ecrans, puis dans la sauvegarde.

const DECK_PATH := "res://content/decks/paquet_depart.tres"
const ROUND_RULES_PATH := "res://content/rules/regles_base.tres"
const ECONOMY_PATH := "res://content/rules/economie_base.tres"
const SHOP_RULES_PATH := "res://content/rules/boutique_base.tres"
const PROFILE_RULES_PATH := "res://content/rules/profil_base.tres"
const BALANCE_PATH := "res://content/rules/equilibrage.tres"
const BOTTLENECKS_DIR := "res://content/bottlenecks"
const DIFFICULTIES_DIR := "res://content/difficulties"
const CHALLENGES_DIR := "res://content/challenges"
const OMENS_DIR := "res://content/omens"
const EVENTS_DIR := "res://content/events"
const EVENT_RULES_PATH := "res://content/rules/rencontres.tres"

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
## Goulots a contrainte de content/bottlenecks : le pool ou chaque royaume tire sa tribulation.
var tribulations: Array[BottleneckDefinition]
## Tries par niveau.
var difficulties: Array[DifficultyDefinition]
var challenges: Array[ChallengeDefinition]
## Presages gagnes en passant un goulot.
var omens: Array[OmenDefinition]
## Rencontres entre la boutique et le goulot suivant, et leurs regles.
var events: Array[EventDefinition]
var event_rules: EventRules
var balance: BalanceRules
## Croissance de l'objectif d'un royaume genere au suivant (mode sans fin).
var endless_growth: float = 1.0


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
	content.balance = load(BALANCE_PATH)
	content.tribulations.assign(ContentLoader.load_all(BOTTLENECKS_DIR).filter(func(res: Resource) -> bool:
		return res is BottleneckDefinition and (res as BottleneckDefinition).constraint != null))
	content.difficulties.assign(ContentLoader.load_all(DIFFICULTIES_DIR).filter(func(res: Resource) -> bool:
		return res is DifficultyDefinition))
	content.difficulties.sort_custom(func(a: DifficultyDefinition, b: DifficultyDefinition) -> bool: return a.level < b.level)
	content.challenges.assign(ContentLoader.load_all(CHALLENGES_DIR).filter(func(res: Resource) -> bool:
		return res is ChallengeDefinition))
	content.omens.assign(ContentLoader.load_all(OMENS_DIR).filter(func(res: Resource) -> bool:
		return res is OmenDefinition))
	content.events.assign(ContentLoader.load_all(EVENTS_DIR).filter(func(res: Resource) -> bool:
		return res is EventDefinition))
	content.event_rules = load(EVENT_RULES_PATH)
	content.endless_growth = content.compute_endless_growth()
	return content


## Graine vide (tests, anciennes sauvegardes) : la RNG garde son etat. Sinon elle est semee par la graine : meme
## graine et memes options, meme partie.
func new_run(rng: RandomNumberGenerator, setup: RunSetup = RunSetup.new()) -> RunState:
	if not setup.seed_text.is_empty():
		rng.seed = setup.seed_value()
	var progress := new_progress()
	var run := RunState.new(DeckState.new(deck_for(setup), rng), round_rules, HandEvaluator.new(hands), progress, economy)
	if setup.random_tribulations:
		progress.draw_tribulations(tribulations, rng)
	apply_setup(run, setup)
	var challenge := setup.challenge
	if challenge != null:
		run.artifacts.append_array(challenge.artifacts)
		run.pills.append_array(challenge.pills)
		run.legacies.append_array(challenge.legacies)
	# Apres les modificateurs : une difficulte ou un heritage de depart peut changer les pierres de depart.
	run.stones = run.economy().starting_stones
	return equip(run)


## Donne a la run le contenu qu'elle tire elle-meme (pilules creees par un talisman).
func equip(run: RunState) -> RunState:
	run.pill_pool = pills
	run.shop_base = shop_rules
	run.omen_pool = omens
	run.card_modifiers = modifiers
	run.event_pool = events
	run.event_rules = event_rules
	run.artifact_pool = artifacts
	return run


## Ce que la run tire hors de la boutique (rencontres, pilules creees) restreint au contenu debloque par ce profil.
## Listes neuves : equip() partage celles du contenu, qu'un assign() modifierait.
func restrict_to_unlocked(run: RunState, profile: ProfileStats) -> void:
	var open_artifacts: Array[ArtifactDefinition] = []
	open_artifacts.assign(unlocks.open(artifacts, profile))
	run.artifact_pool = open_artifacts
	var open_pills: Array[PillDefinition] = []
	open_pills.assign(unlocks.open(pills, profile))
	run.pill_pool = open_pills
	var open_events: Array[EventDefinition] = []
	open_events.assign(unlocks.open(events, profile))
	run.event_pool = open_events


## Options et modificateurs de la partie poses sur la run (nouvelle ou restauree).
func apply_setup(run: RunState, setup: RunSetup) -> void:
	run.setup = setup
	run.modifiers = modifiers_for(setup)


## Modificateurs cumules de tous les niveaux de difficulte jusqu'a celui de la partie, puis ceux du defi.
func modifiers_for(setup: RunSetup) -> Array[RuleModifier]:
	var result: Array[RuleModifier] = []
	for difficulty: DifficultyDefinition in difficulties:
		if difficulty.level <= setup.difficulty:
			result.append_array(difficulty.modifiers)
	if setup.challenge != null:
		result.append_array(setup.challenge.modifiers)
	return result


func new_progress() -> RunProgress:
	var progress := RunProgress.new(realms)
	progress.endless_growth = endless_growth
	progress.significant_digits = balance.significant_digits
	return progress


func deck_for(setup: RunSetup) -> DeckDefinition:
	return setup.challenge.deck if setup.challenge != null and setup.challenge.deck != null else starter_deck


## Meme formule que l'equilibrage (BalanceModel.solve) : la pierre se regle sur le premier royaume, la croissance
## sur les recompenses du dernier.
func compute_endless_growth() -> float:
	if realms.is_empty() or balance == null:
		return 1.0
	var sorted := realms.duplicate()
	sorted.sort_custom(func(a: RealmDefinition, b: RealmDefinition) -> bool: return a.order < b.order)
	var stone := BalanceModel.stone_value(balance, economy, _rewards(sorted[0]))
	return BalanceModel.realm_growth(balance, economy, stone, _rewards(sorted[-1]))


static func _rewards(realm: RealmDefinition) -> Array[int]:
	var rewards: Array[int] = []
	for bottleneck: BottleneckDefinition in realm.bottlenecks:
		rewards.append(bottleneck.reward)
	return rewards


## saved : offres d'une boutique sauvegardee. Vide : nouvelles offres tirees au hasard.
## profile : la boutique ne propose que le contenu que ce profil a debloque (null : tout le contenu). Meme profil et
## meme graine donnent les memes offres : le filtre garde l'ordre des catalogues.
func new_shop(run: RunState, rng: RandomNumberGenerator, saved: Dictionary = {}, profile: ProfileStats = null) -> ShopState:
	if profile == null:
		return ShopState.new(run, artifacts, manuals, pills, packs, legacies, deck_for(run.setup), shop_rules, rng, saved, modifiers)
	var open_artifacts: Array[ArtifactDefinition] = []
	open_artifacts.assign(unlocks.open(artifacts, profile))
	var open_pills: Array[PillDefinition] = []
	open_pills.assign(unlocks.open(pills, profile))
	var open_packs: Array[PackDefinition] = []
	open_packs.assign(unlocks.open(packs, profile))
	var open_legacies: Array[LegacyDefinition] = []
	open_legacies.assign(unlocks.open(legacies, profile))
	return ShopState.new(run, open_artifacts, manuals, open_pills, open_packs, open_legacies, deck_for(run.setup), shop_rules, rng, saved, modifiers)


func difficulty_of(level: int) -> DifficultyDefinition:
	for difficulty: DifficultyDefinition in difficulties:
		if difficulty.level == level:
			return difficulty
	return null


func challenge_by_id(id: StringName) -> ChallengeDefinition:
	return _find(challenges, id) as ChallengeDefinition

## Recherches par id pour la sauvegarde. Contenu retire du jeu : null.
func card_by_id(id: StringName) -> CardData:
	return _find(starter_deck.cards, id) as CardData


func artifact_by_id(id: StringName) -> ArtifactDefinition:
	return _find(artifacts, id) as ArtifactDefinition


func legacy_by_id(id: StringName) -> LegacyDefinition:
	return _find(legacies, id) as LegacyDefinition


func pill_by_id(id: StringName) -> PillDefinition:
	return _find(pills, id) as PillDefinition


func omen_by_id(id: StringName) -> OmenDefinition:
	return _find(omens, id) as OmenDefinition


func event_by_id(id: StringName) -> EventDefinition:
	return _find(events, id) as EventDefinition


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