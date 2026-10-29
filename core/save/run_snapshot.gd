class_name RunSnapshot
extends RefCounted
## Sauvegarde d'une run, a tout moment jouable : pendant un round (piles exactes) ou dans la boutique.
## Tout est reference par id ; un contenu retire du jeu est ignore a la restauration.

## 2 : ameliorations, auras et talismans des cartes, auras des artefacts (v1.2.0).
const VERSION := 2
const DEFAULT_PATH := "user://run.json"
## migrations[n] : Callable qui fait passer une sauvegarde de la version n a n + 1 (SaveMigrator).
static var migrations: Dictionary = {1: func(save: Dictionary) -> Dictionary: return _v1_to_v2(save)}


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
		var entry := {"uid": card.uid, "card": String(card.data.id), "element": card.element, "rank": card.rank}
		entry.merge(CardModifierCatalog.to_dict(card))
		cards.append(entry)
	var data := {
		"version": VERSION,
		# En texte : un entier 64 bits perdrait sa precision en nombre JSON (float).
		"rng_state": str(rng.state),
		"seed": str(run.seed_value),
		"stones": run.stones,
		"progress": run.progress.to_dict(),
		"cards": cards,
		"piles": run.piles(),
		"artifacts": SaveData.ids(run.artifacts),
		"artifact_stacks": run.artifact_stacks.duplicate(),
		"artifact_editions": ShopState.edition_ids(run.artifact_editions),
		"pills": SaveData.ids(run.pills),
		"legacies": SaveData.ids(run.legacies),
		"legacy_offer": "" if run.legacy_offer == null else String(run.legacy_offer.id),
		"legacy_offer_realm": run.legacy_offer_realm,
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
	var save := migrate(data)
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
	var run := content.equip(RunState.new(deck, content.round_rules, HandEvaluator.new(content.hands), progress, content.economy))
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
	var stacks: Variant = save.get("artifact_stacks", {})
	if stacks is Dictionary:
		for artifact: ArtifactDefinition in run.artifacts:
			var count := SaveData.int_of(stacks, String(artifact.id))
			if count > 0:
				run.artifact_stacks[artifact.id] = count
	run.artifact_editions = ShopState.editions_of(save.get("artifact_editions"), run.artifacts, content.modifiers)
	for id: String in SaveData.string_list(save.get("legacies")):
		var legacy := content.legacy_by_id(StringName(id))
		if legacy != null:
			run.legacies.append(legacy)
	run.legacy_offer = content.legacy_by_id(StringName(str(save.get("legacy_offer", ""))))
	run.legacy_offer_realm = SaveData.int_of(save, "legacy_offer_realm")
	run.hand_levels = HandLevels.from_dict(save.get("hand_levels"))
	run.stats = RunStats.from_dict(save.get("stats"))
	# Champ ajoute apres la v1 des sauvegardes : absent, la graine reste inconnue (0).
	var seed_text := str(save.get("seed", ""))
	run.seed_value = seed_text.to_int() if seed_text.is_valid_int() else 0
	return run


## Reprend le round sauvegarde, s'il y en avait un. A appeler apres avoir branche les signaux de la run.
## Faux : la sauvegarde etait prise dans la boutique.
static func resume_round(data: Dictionary, run: RunState) -> bool:
	var saved: Variant = migrate(data).get("round")
	if not saved is Dictionary:
		return false
	run.resume_round(SaveData.int_of(saved, "score"), SaveData.int_of(saved, "hands_left", 1), SaveData.int_of(saved, "discards_left"))
	return true


## La boutique sauvegardee de cette run, avec ses offres d'origine.
static func restore_shop(data: Dictionary, run: RunState, content: GameContent, rng: RandomNumberGenerator, profile: ProfileStats = null) -> ShopState:
	var saved: Variant = migrate(data).get("shop", {})
	return content.new_shop(run, rng, saved if saved is Dictionary else {}, profile)


## La sauvegarde au format de VERSION. Chaque lecture passe par ici : aucune ne lit un ancien format. {} si inutilisable.
static func migrate(data: Dictionary) -> Dictionary:
	return SaveMigrator.migrate(data, VERSION, migrations)


## v1 -> v2 : les cartes et les artefacts n'avaient ni amelioration, ni aura, ni talisman.
static func _v1_to_v2(old: Dictionary) -> Dictionary:
	var save := old.duplicate(true)
	if save.get("cards") is Array:
		for entry: Variant in save["cards"]:
			if entry is Dictionary:
				entry.merge({"enhancement": "", "edition": "", "talisman": ""})
	save["artifact_editions"] = {}
	return save


static func _restore_cards(data: Variant, content: GameContent) -> Array[CardInstance]:
	var cards: Array[CardInstance] = []
	if not data is Array:
		return cards
	# uid en double (sauvegarde abimee) : la seconde carte en recoit un neuf, elle ne remplace pas la premiere.
	var seen: Dictionary = {}
	var next_uid := 0
	for entry: Variant in data:
		if entry is Dictionary:
			next_uid = maxi(next_uid, SaveData.int_of(entry, "uid") + 1)
	for entry: Variant in data:
		if not entry is Dictionary:
			continue
		var card_data := content.card_by_id(StringName(str(entry.get("card", ""))))
		if card_data == null:
			continue
		var uid := SaveData.int_of(entry, "uid")
		if seen.has(uid):
			uid = next_uid
			next_uid += 1
		seen[uid] = true
		var card := CardInstance.new(uid, card_data, content.starter_deck.ranks)
		card.element = clampi(SaveData.int_of(entry, "element"), 0, Element.Type.size() - 1) as Element.Type
		card.rank = clampi(SaveData.int_of(entry, "rank", card_data.rank), 1, content.starter_deck.ranks.max_rank)
		content.modifiers.apply_dict(card, entry)
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
