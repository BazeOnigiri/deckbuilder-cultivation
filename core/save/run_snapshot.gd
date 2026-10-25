class_name RunSnapshot
extends RefCounted
## Sauvegarde d'une run entre deux goulots : capture vers un Dictionary JSON, et restauration.
## Tout est reference par id ; un contenu retire du jeu est ignore a la restauration.

const VERSION := 1
const DEFAULT_PATH := "user://run.json"


## On ne sauvegarde qu'entre deux goulots : main et defausse n'y comptent pas, le round suivant remelange.
static func can_capture(run: RunState) -> bool:
	return run.status == RunState.Status.BETWEEN_ROUNDS


static func capture(run: RunState, shop: ShopState, rng: RandomNumberGenerator) -> Dictionary:
	assert(can_capture(run), "capture() seulement entre deux goulots")
	var cards: Array = []
	for card: CardInstance in run.cards():
		cards.append({"uid": card.uid, "card": String(card.data.id), "element": card.element, "rank": card.rank})
	return {
		"version": VERSION,
		# En texte : un entier 64 bits perdrait sa precision en nombre JSON (float).
		"rng_state": str(rng.state),
		"stones": run.stones,
		"progress": run.progress.to_dict(),
		"cards": cards,
		"artifacts": _ids(run.artifacts),
		"pills": _ids(run.pills),
		"hand_levels": run.hand_levels.to_dict(),
		"stats": run.stats.to_dict(),
		"shop": shop.to_dict(),
	}


## Renvoie null si la sauvegarde est vide, d'une version inconnue, ou incoherente.
## La run restauree est entre deux goulots : next_round() lance le goulot sauvegarde.
static func restore(data: Dictionary, content: GameContent, rng: RandomNumberGenerator) -> RunState:
	var save := SaveMigrator.migrate(data, VERSION, {})
	if save.is_empty():
		return null
	var rng_state: Variant = save.get("rng_state")
	if not rng_state is String or not rng_state.is_valid_int():
		return null
	var cards := _restore_cards(save.get("cards"), content)
	if cards.is_empty():
		return null
	var progress := RunProgress.new(content.realms)
	if not progress.restore(save.get("progress")):
		return null
	rng.state = rng_state.to_int()
	var run := RunState.new(DeckState.from_cards(cards, rng), content.round_rules, HandEvaluator.new(content.hands), progress, content.economy)
	run.status = RunState.Status.BETWEEN_ROUNDS
	run.stones = maxi(0, SaveData.int_of(save, "stones"))
	for id: String in SaveData.string_list(save.get("artifacts")):
		var artifact := content.artifact_by_id(StringName(id))
		if artifact != null:
			run.artifacts.append(artifact)
	for id: String in SaveData.string_list(save.get("pills")):
		var pill := content.pill_by_id(StringName(id))
		if pill != null:
			run.pills.append(pill)
	run.hand_levels = HandLevels.from_dict(save.get("hand_levels"))
	run.stats = RunStats.from_dict(save.get("stats"))
	return run


## La boutique sauvegardee de cette run, avec ses offres d'origine.
static func restore_shop(data: Dictionary, run: RunState, content: GameContent, rng: RandomNumberGenerator) -> ShopState:
	var saved: Variant = data.get("shop", {})
	return content.new_shop(run, rng, saved if saved is Dictionary else {})


static func _restore_cards(data: Variant, content: GameContent) -> Array[CardInstance]:
	var cards: Array[CardInstance] = []
	if not data is Array:
		return cards
	for entry: Variant in data:
		if not entry is Dictionary:
			continue
		var card_data := content.card_by_id(StringName(str(entry.get("card", ""))))
		if card_data == null:
			continue
		var card := CardInstance.new(SaveData.int_of(entry, "uid"), card_data)
		card.element = clampi(SaveData.int_of(entry, "element"), 0, Element.Type.size() - 1) as Element.Type
		card.rank = maxi(1, SaveData.int_of(entry, "rank", card_data.rank))
		cards.append(card)
	return cards


static func _ids(list: Array) -> Array[String]:
	var ids: Array[String] = []
	for item: Resource in list:
		ids.append(String(item.id))
	return ids