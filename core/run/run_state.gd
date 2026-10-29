class_name RunState
extends RefCounted
## Une run : enchaine les goulots des royaumes jusqu'a la victoire ou la defaite. Logique pure.

signal round_started(round_state: RoundState)
signal round_won(reward: RoundReward)
signal finished(won: bool)
## Le goulot en cours est annonce : le joueur choisit de l'affronter ou de le passer.
signal announced
## Le goulot vient d'etre passe ; omen : le presage gagne (null si aucun).
signal skipped(omen: OmenDefinition)
## Une rencontre commence ou reprend (current_event), et son choix vient d'etre fait (event_outcome tire).
signal encountered
signal event_resolved

## BETWEEN_ROUNDS : goulot franchi, la boutique est ouverte. ANNOUNCING : goulot annonce, ni round ni boutique.
## ENCOUNTER : rencontre entre la boutique et l'annonce.
enum Status {IN_ROUND, BETWEEN_ROUNDS, WON, LOST, ANNOUNCING, ENCOUNTER}

var status: Status = Status.IN_ROUND
var progress: RunProgress
var current_round: RoundState
var stones: int = 0
## Partage avec chaque round : un artefact ajoute agit des la main suivante.
var artifacts: Array[ArtifactDefinition] = []
## Crans des artefacts qui grandissent, par id (sauvegardes). Partages avec chaque round.
var artifact_stacks: Dictionary = {}
## Aura de chaque artefact possede, par id (sauvegardee). Par id comme les crans : un artefact n'est jamais possede
## deux fois, et une vente ou un ajout ne decale rien, contrairement a un index.
var artifact_editions: Dictionary = {}
var hand_levels := HandLevels.new()
var pills: Array[PillDefinition] = []
var stats := RunStats.new()
## Graine de la RNG de la run, 0 si inconnue (sauvegarde ancienne). Posee par l'ecran de run, sauvegardee.
var seed_value: int = 0
## Heritages achetes : leurs modificateurs changent les regles de base pour le reste de la run.
var legacies: Array[LegacyDefinition] = []
## Heritage propose en boutique pendant ce royaume (null : achete ou aucun), et le royaume ou il a ete tire.
var legacy_offer: LegacyDefinition
var legacy_offer_realm: int = 0
## Pilules qu'un talisman d'alchimie peut creer, et regles de boutique de base (nombre d'emplacements). Poses par
## GameContent ; vides, aucun talisman ne cree de pilule.
var pill_pool: Array[PillDefinition] = []
var shop_base: ShopRules
## Options de la partie (graine, difficulte, defi) : sauvegardees, affichees dans la Voie de cultivation.
var setup := RunSetup.new()
## Modificateurs de la difficulte et du defi (GameContent.modifiers_for), appliques avant ceux des heritages.
var modifiers: Array[RuleModifier] = []
## Vrai des que le joueur continue apres la victoire au dernier royaume.
var endless: bool = false
## Presages que la run peut proposer, et catalogue des ameliorations (presage de carte). Poses par GameContent.
var omen_pool: Array[OmenDefinition] = []
var card_modifiers: CardModifierCatalog
## Presage propose pour chaque goulot du royaume en cours (null : tribulation, qu'on ne passe pas), tires a la
## premiere annonce du royaume omen_offers_realm. Sauvegardes.
var omen_offers: Array[OmenDefinition] = []
var omen_offers_realm: int = 0
## Presages gagnes dont l'effet attend la prochaine boutique ou la prochaine recompense. Sauvegardes.
var pending_omens: Array[OmenDefinition] = []
## Rencontres possibles, leurs regles, et les artefacts qu'une rencontre peut donner (debloques). Poses par GameContent.
var event_pool: Array[EventDefinition] = []
var event_rules: EventRules
var artifact_pool: Array[ArtifactDefinition] = []
## Rencontres deja vecues dans cette partie (jamais deux fois), royaume de la derniere. Sauvegardes.
var seen_events: Array[StringName] = []
var event_realm: int = 0
## Mains de moins au prochain goulot (cout d'une rencontre). Sauvegarde.
var hand_penalty: int = 0
## Rencontre en cours (statut ENCOUNTER), choix fait et issue tiree (-1 : pas encore). Sauvegardes.
var current_event: EventDefinition
var event_choice: int = -1
var event_outcome: int = -1

var _deck: DeckState
var _rules: RoundRules
var _evaluator: HandEvaluator
var _economy: EconomyRules


func _init(deck: DeckState, rules: RoundRules, evaluator: HandEvaluator, p_progress: RunProgress, economy: EconomyRules) -> void:
	_deck = deck
	_rules = rules
	_evaluator = evaluator
	progress = p_progress
	_economy = economy
	stones = economy.starting_stones


func start() -> void:
	_start_round()


## Lance le goulot suivant. Refuse si on n'est pas entre deux goulots.
func next_round() -> bool:
	if status != Status.BETWEEN_ROUNDS:
		return false
	_start_round()
	return true

## Annonce le goulot en cours : au depart, apres la boutique ou apres un goulot passe. Tire les presages du
## royaume a sa premiere annonce. Faux pendant un round ou une fois la run terminee.
func announce() -> bool:
	if status == Status.WON or status == Status.LOST or (status == Status.IN_ROUND and current_round != null):
		return false
	status = Status.ANNOUNCING
	if omen_offers_realm != progress.realm_number():
		_draw_omens()
	announced.emit()
	return true


## Affronte le goulot annonce.
func fight() -> bool:
	if status != Status.ANNOUNCING:
		return false
	_start_round()
	return true


## Presage gagne en passant le goulot en cours, null si aucun.
func current_omen() -> OmenDefinition:
	var index := progress.bottleneck_number() - 1
	return omen_offers[index] if index < omen_offers.size() else null


## Une tribulation ne se passe pas.
func can_skip() -> bool:
	return status == Status.ANNOUNCING and progress.current_bottleneck().constraint == null


## Passe le goulot annonce : ni round ni recompense, mais son presage. Il compte comme franchi pour la progression,
## pas dans stats.bottlenecks_cleared (goulots vaincus) : il a son propre compteur.
func skip() -> bool:
	if not can_skip():
		return false
	var omen := current_omen()
	stats.bottlenecks_skipped += 1
	if omen != null:
		take_omen(omen)
	skipped.emit(omen)
	if progress.advance():
		announce()
	else:
		status = Status.WON
		finished.emit(true)
	return true


## Effet immediat applique tout de suite, sinon le presage attend son moment.
func take_omen(omen: OmenDefinition) -> void:
	if omen.effect.timing() == OmenEffect.Timing.NOW:
		omen.effect.apply_now(self, _deck.rng())
	else:
		pending_omens.append(omen)


## Retire et renvoie les presages en attente de ce moment.
func take_pending_omens(timing: OmenEffect.Timing) -> Array[OmenDefinition]:
	var taken: Array[OmenDefinition] = []
	for omen: OmenDefinition in pending_omens.duplicate():
		if omen.effect.timing() == timing:
			taken.append(omen)
			pending_omens.erase(omen)
	return taken


## Quitte la boutique : une rencontre tiree avec la RNG de la run (EventRules.chance), sinon l'annonce du goulot.
func leave_shop() -> bool:
	if status != Status.BETWEEN_ROUNDS:
		return false
	var event := _draw_event()
	if event == null:
		return announce()
	start_event(event)
	return true


## Rencontres qui peuvent encore apparaitre : pas deja vecues, conditions remplies.
func open_events() -> Array[EventDefinition]:
	var open: Array[EventDefinition] = []
	for event: EventDefinition in event_pool:
		if not seen_events.has(event.id) and event.can_appear(self):
			open.append(event)
	return open


## Au plus une rencontre par royaume. Aucune possible : la RNG ne bouge pas.
func _draw_event() -> EventDefinition:
	if event_rules == null or event_realm == progress.realm_number():
		return null
	var open := open_events()
	if open.is_empty() or _deck.rng().randf() >= event_rules.chance:
		return null
	return open[_deck.rng().randi_range(0, open.size() - 1)]


## Ouvre la rencontre ; choice et outcome : reprise d'une sauvegarde ou le choix etait deja fait.
func start_event(event: EventDefinition, choice: int = -1, outcome: int = -1) -> void:
	current_event = event
	event_choice = choice
	event_outcome = outcome
	status = Status.ENCOUNTER
	if not seen_events.has(event.id):
		seen_events.append(event.id)
	event_realm = progress.realm_number()
	encountered.emit()


## Cle de la raison qui rend ce choix indisponible, "" s'il est possible.
func event_blocked_reason(index: int) -> String:
	return current_event.choices[index].blocked_reason(self)


func can_choose(index: int) -> bool:
	return (status == Status.ENCOUNTER and event_choice < 0 and index >= 0 and index < current_event.choices.size()
		and event_blocked_reason(index).is_empty())


## Paie le cout, tire l'issue avec la RNG de la run et applique ses effets.
func choose(index: int) -> bool:
	if not can_choose(index):
		return false
	var choice: EventChoice = current_event.choices[index]
	if choice.cost != null:
		choice.cost.pay(self, _deck.rng())
	event_choice = index
	event_outcome = choice.roll(_deck.rng())
	choice.outcomes[event_outcome].apply(self, _deck.rng())
	event_resolved.emit()
	return true


## Issue tiree de la rencontre en cours, null avant le choix.
func current_outcome() -> EventOutcome:
	if current_event == null or event_choice < 0:
		return null
	return current_event.choices[event_choice].outcomes[event_outcome]


## Ferme la rencontre resolue : le goulot suivant s'annonce.
func end_event() -> bool:
	if status != Status.ENCOUNTER or event_choice < 0:
		return false
	current_event = null
	event_choice = -1
	event_outcome = -1
	return announce()


## Un presage par goulot passable du royaume, sans remise tant que le pool suffit.
func _draw_omens() -> void:
	omen_offers.clear()
	omen_offers_realm = progress.realm_number()
	var bag: Array[OmenDefinition] = []
	for bottleneck: BottleneckDefinition in progress.current_realm().bottlenecks:
		if bottleneck.constraint != null or omen_pool.is_empty():
			omen_offers.append(null)
			continue
		if bag.is_empty():
			bag = omen_pool.duplicate()
			RngUtils.shuffle(bag, _deck.rng())
		omen_offers.append(bag.pop_back())


## Regles du round avec les heritages : le round, la boutique et l'economie lisent celles-ci, jamais les heritages.
func round_rules() -> RoundRules:
	return _with_legacies(_rules) as RoundRules


func economy() -> EconomyRules:
	return _with_legacies(_economy) as EconomyRules


func shop_rules(base: ShopRules) -> ShopRules:
	return _with_legacies(base) as ShopRules


## Copie des regles de base : modificateurs de la partie, puis ceux de chaque heritage dans l'ordre d'achat.
func _with_legacies(base: Resource) -> Resource:
	if legacies.is_empty() and modifiers.is_empty():
		return base
	var rules := base.duplicate()
	for modifier: RuleModifier in modifiers:
		modifier.apply_to(rules)
	for legacy: LegacyDefinition in legacies:
		for modifier: RuleModifier in legacy.modifiers:
			modifier.apply_to(rules)
	return rules


## Objectif d'un goulot, avec le pourcentage des regles (difficulte).
func target_for(realm: RealmDefinition, bottleneck: BottleneckDefinition) -> int:
	return roundi(RunProgress.target_for(realm, bottleneck) * round_rules().target_percent / 100.0)


## Mode sans fin, apres la victoire : un royaume genere (tribulation tiree dans pool) s'ajoute et la run revient
## entre deux goulots, boutique comprise. Faux si la run n'est pas gagnee.
func continue_endless(pool: Array[BottleneckDefinition], rng: RandomNumberGenerator) -> bool:
	if status != Status.WON:
		return false
	progress.add_endless_realm(pool, rng)
	endless = true
	status = Status.BETWEEN_ROUNDS
	return true


## Prix de vente d'un artefact : la part sell_fraction de son prix, arrondie en dessous.
func sell_price(artifact: ArtifactDefinition) -> int:
	return floori(artifact.price * economy().sell_fraction)


## Vend l'artefact a cet index : rend ses pierres et libere l'emplacement, des la main suivante. Faux si
## l'index n'existe pas.
func sell_artifact(index: int) -> bool:
	if index < 0 or index >= artifacts.size():
		return false
	stones += sell_price(artifacts[index])
	lose_artifact(index)
	return true


## Retire l'artefact sans rien rendre (cout d'une rencontre), crans et aura compris.
func lose_artifact(index: int) -> void:
	artifact_stacks.erase(artifacts[index].id)
	artifact_editions.erase(artifacts[index].id)
	artifacts.remove_at(index)


## Ajoute un artefact, avec son aura (null : aucune). Il agit des la main suivante.
func add_artifact(artifact: ArtifactDefinition, edition: EditionDefinition = null) -> void:
	artifacts.append(artifact)
	if edition != null:
		artifact_editions[artifact.id] = edition


## Emplacements d'artefact occupes : un artefact dont l'aura ne prend pas d'emplacement n'en occupe pas.
func artifact_slots_used() -> int:
	var used: int = 0
	for artifact: ArtifactDefinition in artifacts:
		var edition: EditionDefinition = artifact_editions.get(artifact.id)
		if edition == null or edition.takes_slot:
			used += 1
	return used


## Emplacements de pilule, heritages compris. 0 sans regles de boutique.
func max_pills() -> int:
	return 0 if shop_base == null else shop_rules(shop_base).max_pills


## Emplacements d'artefact, heritages compris. 0 sans regles de boutique.
func max_artifacts() -> int:
	return 0 if shop_base == null else shop_rules(shop_base).max_artifacts


## Prix de vente d'une pilule : meme part sell_fraction de son prix que pour un artefact.
func sell_pill_price(pill: PillDefinition) -> int:
	return floori(pill.price * economy().sell_fraction)


## Vend la pilule a cet index, en round comme en boutique. Faux si l'index n'existe pas.
func sell_pill(index: int) -> bool:
	if index < 0 or index >= pills.size():
		return false
	stones += sell_pill_price(pills[index])
	pills.remove_at(index)
	return true


## Ajoute une carte au paquet de la run (sceau de disciples), avec un uid neuf, a une place tiree de la pioche
## (pas la prochaine carte piochee) ; le melange du prochain round la replace.
func add_card(data: CardData, ranks: RankRules) -> CardInstance:
	var uid := 0
	for card: CardInstance in _deck.all_cards():
		uid = maxi(uid, card.uid + 1)
	var card := CardInstance.new(uid, data, ranks)
	_deck.insert_into_draw_pile(card)
	return card


## Main que formeraient ces cartes (pilule d'illumination). null si aucune.
func evaluate(cards: Array[CardInstance]) -> HandResult:
	return _evaluator.evaluate(cards)


## Une pilule s'utilise pendant un round, sur des cartes de la main, en nombre autorise par la pilule.
func can_use_pill(index: int, selected: Array[CardInstance]) -> bool:
	if status != Status.IN_ROUND or index < 0 or index >= pills.size():
		return false
	var pill: PillDefinition = pills[index]
	return (selected.size() >= pill.min_cards and selected.size() <= pill.max_cards
		and _deck.all_in_hand(selected))


func use_pill(index: int, selected: Array[CardInstance]) -> bool:
	if not can_use_pill(index, selected):
		return false
	pills[index].effect.apply(selected, _deck, self)
	pills.remove_at(index)
	current_round.ensure_playable()
	return true

## Toutes les cartes de la run (sauvegarde).
func cards() -> Array[CardInstance]:
	return _deck.all_cards()


## Paquet de la run, pour les effets de pilule appliques hors d'un round (rencontre).
func deck() -> DeckState:
	return _deck


## Retire definitivement ces cartes du paquet, quelle que soit leur pile.
func remove_cards(removed: Array[CardInstance]) -> void:
	_deck.remove(removed)

## Piles du paquet par uid (sauvegarde).
func piles() -> Dictionary:
	return _deck.pile_uids()


## Reprise d'un round sauvegarde : les piles sont deja restaurees, donc pas de start() (il remelangerait).
func resume_round(score: int, hands_left: int, discards_left: int) -> void:
	_create_round()
	current_round.score = maxi(0, score)
	current_round.hands_left = maxi(1, hands_left)
	current_round.discards_left = maxi(0, discards_left)
	round_started.emit(current_round)
	current_round.ensure_playable()

func _start_round() -> void:
	_create_round()
	# Cout d'une rencontre : un round repris l'a deja paye (mains sauvegardees).
	if hand_penalty > 0:
		current_round.hands_left = maxi(1, current_round.hands_left - hand_penalty)
		hand_penalty = 0
	# Emis avant start() : l'UI se branche sur le round avant la premiere pioche.
	round_started.emit(current_round)
	current_round.start()


func _create_round() -> void:
	status = Status.IN_ROUND
	var constraint: TribulationConstraint = progress.current_bottleneck().constraint
	if constraint == null:
		constraint = TribulationConstraint.new()
	current_round = RoundState.new(_deck, round_rules(), _evaluator, target_for(progress.current_realm(), progress.current_bottleneck()),
		artifacts, hand_levels, constraint, artifact_stacks, artifact_editions)
	current_round.finished.connect(_on_round_finished)
	current_round.hand_played.connect(_on_hand_played)
	current_round.discarded.connect(_on_discarded)


func _on_round_finished(won: bool) -> void:
	if not won:
		status = Status.LOST
		finished.emit(false)
		return
	# Recompense calculee avant advance() : elle depend du goulot qui vient d'etre franchi.
	var reward := RoundReward.compute(economy(), progress.current_bottleneck().reward, current_round.hands_left, stones)
	reward.artifacts = ArtifactResolver.after_round_won(artifacts, artifact_stacks, current_round.hands_left,
		current_round.discards_left)
	reward.cards = CardEffects.held_stones(_deck.hand)
	for omen: OmenDefinition in take_pending_omens(OmenEffect.Timing.NEXT_REWARD):
		omen.effect.apply_to_reward(reward)
	stones += reward.total()
	stats.stones_earned += reward.total()
	stats.bottlenecks_cleared += 1
	if progress.advance():
		status = Status.BETWEEN_ROUNDS
		round_won.emit(reward)
	else:
		status = Status.WON
		finished.emit(true)

func _on_hand_played(result: HandResult, score: ScoreContext) -> void:
	stats.record_hand(result.definition.id, score.total())
	stones += score.stones
	stats.stones_earned += score.stones


## Talisman d'alchimie : une pilule au hasard par carte, tant qu'il reste un emplacement.
func _on_discarded(gained: int, discarded: Array[CardInstance]) -> void:
	stats.discards_used += 1
	stones += gained
	stats.stones_earned += gained
	for i: int in CardEffects.pills_on_discard(discarded):
		if pill_pool.is_empty() or pills.size() >= max_pills():
			break
		pills.append(pill_pool[_deck.rng().randi_range(0, pill_pool.size() - 1)])