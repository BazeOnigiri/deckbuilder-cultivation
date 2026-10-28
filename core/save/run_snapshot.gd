class_name RunSnapshot
extends RefCounted
## Sauvegarde d'une run, a tout moment jouable : pendant un round (piles exactes) ou dans la boutique.
## Tout est reference par id ; un contenu retire du jeu est ignore a la restauration.

const VERSION := 1
const DEFAULT_PATH := "user://run.json"


## Sauvegardable pendant un round en cours, ou entre deux goulots. Pas une run terminee.
static func can_capture(run: RunState) -> bool:
	if run.status == RunState.Status.BETWEEN_ROUNDS:
		return true
	return (run.status == RunState.Status.IN_ROUND and run.current_round != null
		and run.current_round.status == RoundState.Status.PLAYING)


## shop : la boutique ouverte entre deux goulots. Ignoree (peut etre null) pendant un round.
static func capture(run: RunState, shop: ShopState, rng: RandomNumberGenerator) -> Dictionary:
	assert(can_capture(run), "capture() d'une run terminee")
	var cards: Array = []
	for card: CardInstance in run.cards():
		cards.append({"uid": card.uid, "card": String(card.data.id), "element": card.element, "rank": card.rank})
	var data := {
		"version": VERSION,
		# En texte : un entier 64 bits perdrait sa precision en nombre JSON (float).
		"rng_state": str(rng.state),
		"stones": run.stones,
		"progress": run.progress.to_dict(),
		"cards": cards,
		"piles": run.piles(),
		"artifacts": _ids(run.artifacts),
		"pills": _ids(run.pills),
		"hand_levels": run.hand_levels.to_dict(),
		"stats": run.stats.to_dict(),
	}
	if run.status == RunState.Status.IN_ROUND:
		var round_state := run.current_round
		data["round"] = {
			"score": round_state.score,
			"hands_left": round_state.hands_left,
			"discards_left": round_state.discards_left,
		}
	else:
		assert(shop != null, "capture() entre deux goulots demande la boutique")
		data["shop"] = shop.to_dict()
	return data


## Renvoie null si la sauvegarde est vide, d'une version inconnue, ou incoherente.
## La run revient entre deux goulots : appeler ensuite resume_round(), apres avoir branche ses signaux.
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
	var deck := _restore_deck(save.get("piles"), cards, rng)
	var run := RunState.new(deck, content.round_rules, HandEvaluator.new(content.hands), progress, content.economy)
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


## Reprend le round sauvegarde, s'il y en avait un. A appeler apres avoir branche les signaux de la run.
## Faux : la sauvegarde etait prise dans la boutique.
static func resume_round(data: Dictionary, run: RunState) -> bool:
	var saved: Variant = data.get("round")
	if not saved is Dictionary:
		return false
	run.resume_round(SaveData.int_of(saved, "score"), SaveData.int_of(saved, "hands_left", 1), SaveData.int_of(saved, "discards_left"))
	return true


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
		var card := CardInstance.new(SaveData.int_of(entry, "uid"), card_data, content.starter_deck.ranks)
		card.element = clampi(SaveData.int_of(entry, "element"), 0, Element.Type.size() - 1) as Element.Type
		card.rank = maxi(1, SaveData.int_of(entry, "rank", card_data.rank))
		cards.append(card)
	return cards


static func _restore_deck(piles: Variant, cards: Array[CardInstance], rng: RandomNumberGenerator) -> DeckState:
	var by_uid: Dictionary = {}
	for card: CardInstance in cards:
		by_uid[card.uid] = card
	var saved: Dictionary = piles if piles is Dictionary else {}
	var draw := _take(saved.get("draw"), by_uid)
	var hand := _take(saved.get("hand"), by_uid)
	var discard := _take(saved.get("discard"), by_uid)
	# Cartes absentes des piles (sauvegarde abimee) : remises dans la pioche, aucune carte perdue.
	for card: CardInstance in by_uid.values():
		draw.append(card)
	return DeckState.from_piles(draw, hand, discard, rng)


## Prend dans by_uid les cartes listees, dans l'ordre, et les en retire : un uid inconnu ou en double est ignore.
static func _take(uids: Variant, by_uid: Dictionary) -> Array[CardInstance]:
	var pile: Array[CardInstance] = []
	if not uids is Array:
		return pile
	for value: Variant in uids:
		if not (value is int or value is float):
			continue
		var uid: int = int(value)
		if by_uid.has(uid):
			pile.append(by_uid[uid])
			by_uid.erase(uid)
	return pile


static func _ids(list: Array) -> Array[String]:
	var ids: Array[String] = []
	for item: Resource in list:
		ids.append(String(item.id))
	return ids