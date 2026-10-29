extends GutTest
## Rencontres : tirage apres la boutique (deterministe, sans doublon, une par royaume), conditions, couts, effets
## des choix et issue aleatoire.

var _content: GameContent


func before_all() -> void:
	_content = GameContent.load_default()


## Run du vrai contenu, entre deux goulots (boutique quittee), rencontres a la chance donnee.
func _run(chance: float = 1.0, seed_text: String = "RENCONTRE") -> RunState:
	var run := _content.new_run(RandomNumberGenerator.new(), RunSetup.custom(seed_text, 1, false, ""))
	run.status = RunState.Status.BETWEEN_ROUNDS
	var rules := EventRules.new()
	rules.id = &"test"
	rules.chance = chance
	run.event_rules = rules
	return run


func _outcome(effects: Array[EventEffect], weight: float = 1.0) -> EventOutcome:
	var outcome := EventOutcome.new()
	outcome.weight = weight
	outcome.text_key = "TEST"
	outcome.effects = effects
	return outcome


func _choice(outcomes: Array[EventOutcome], cost: EventCost = null) -> EventChoice:
	var choice := EventChoice.new()
	choice.label_key = "TEST"
	choice.cost = cost
	choice.outcomes = outcomes
	return choice


func _cost(kind: EventCost.Kind, amount: int) -> EventCost:
	var cost := EventCost.new()
	cost.kind = kind
	cost.amount = amount
	return cost


## Rencontre d'un seul choix (plus un second sans effet), ouverte sur la run.
func _open(run: RunState, choice: EventChoice) -> void:
	var event := EventDefinition.new()
	event.id = &"evenement_test"
	event.title_key = "TEST"
	event.text_key = "TEST"
	event.choices = [choice, _choice([_outcome([])])]
	assert_true(event.is_valid())
	run.start_event(event)


func _stones(amount: int) -> RunEventEffect:
	var stones := StonesOmenEffect.new()
	stones.amount = amount
	var effect := RunEventEffect.new()
	effect.effect = stones
	return effect


func test_tirage_deterministe_par_graine() -> void:
	var first := _run(1.0, "GRAINE")
	var second := _run(1.0, "GRAINE")
	assert_true(first.leave_shop())
	assert_true(second.leave_shop())
	assert_eq(first.status, RunState.Status.ENCOUNTER)
	assert_eq(first.current_event.id, second.current_event.id, "meme graine, meme rencontre")


func test_sans_doublon_puis_plus_rien() -> void:
	var run := _run()
	var seen: Array[StringName] = []
	for i: int in _content.events.size():
		run.status = RunState.Status.BETWEEN_ROUNDS
		run.event_realm = 0
		run.leave_shop()
		if run.status != RunState.Status.ENCOUNTER:
			break
		assert_does_not_have(seen, run.current_event.id, "jamais deux fois la meme rencontre")
		seen.append(run.current_event.id)
		assert_true(run.choose(run.current_event.choices.size() - 1))
		assert_true(run.end_event())
	assert_true(run.open_events().is_empty())
	run.status = RunState.Status.BETWEEN_ROUNDS
	run.event_realm = 0
	run.leave_shop()
	assert_eq(run.status, RunState.Status.ANNOUNCING, "plus aucune rencontre possible : l'annonce suit")


func test_une_seule_rencontre_par_royaume() -> void:
	var run := _run()
	run.leave_shop()
	assert_eq(run.status, RunState.Status.ENCOUNTER)
	run.choose(run.current_event.choices.size() - 1)
	run.end_event()
	run.status = RunState.Status.BETWEEN_ROUNDS
	run.leave_shop()
	assert_eq(run.status, RunState.Status.ANNOUNCING)


func test_probabilite_des_regles() -> void:
	var never := _run(0.0)
	never.leave_shop()
	assert_eq(never.status, RunState.Status.ANNOUNCING)
	var run := _run(_content.event_rules.chance)
	var count := 0
	var tries := 2000
	for i: int in tries:
		run.status = RunState.Status.BETWEEN_ROUNDS
		run.event_realm = 0
		run.seen_events.clear()
		run.leave_shop()
		if run.status == RunState.Status.ENCOUNTER:
			count += 1
	assert_almost_eq(float(count) / tries, _content.event_rules.chance, 0.04)


func test_conditions_d_apparition() -> void:
	var run := _run()
	var ids := run.open_events().map(func(event: EventDefinition) -> StringName: return event.id)
	assert_does_not_have(ids, &"evenement_grotte_immortel", "royaume 2 minimum")
	assert_does_not_have(ids, &"evenement_renarde_des_brumes", "demande un artefact")
	assert_has(ids, &"evenement_ermite")
	run.add_artifact(_content.artifacts[0])
	assert_true(_content.event_by_id(&"evenement_renarde_des_brumes").can_appear(run))
	run.progress.advance()
	run.progress.advance()
	run.progress.advance()
	assert_eq(run.progress.realm_number(), 2)
	assert_true(_content.event_by_id(&"evenement_grotte_immortel").can_appear(run))


func test_cout_en_pierres_paye_ou_refuse() -> void:
	var run := _run()
	_open(run, _choice([_outcome([_stones(10)])], _cost(EventCost.Kind.STONES, 5)))
	run.stones = 4
	assert_false(run.can_choose(0))
	assert_eq(run.event_blocked_reason(0), "EVENT_BLOCK_STONES")
	assert_false(run.choose(0))
	assert_eq(run.stones, 4, "rien n'est paye")
	run.stones = 5
	assert_true(run.choose(0))
	assert_eq(run.stones, 10)
	assert_false(run.choose(1), "un seul choix par rencontre")


func test_cout_d_une_carte() -> void:
	var run := _run()
	var size := run.cards().size()
	_open(run, _choice([_outcome([])], _cost(EventCost.Kind.CARDS, 1)))
	assert_true(run.choose(0))
	assert_eq(run.cards().size(), size - 1)
	var small := _run()
	small.remove_cards(small.cards().slice(small.round_rules().hand_size))
	_open(small, _choice([_outcome([])], _cost(EventCost.Kind.CARDS, 1)))
	assert_eq(small.event_blocked_reason(0), "EVENT_BLOCK_CARDS", "le paquet garde une main pleine")


func test_cout_d_un_artefact() -> void:
	var run := _run()
	_open(run, _choice([_outcome([])], _cost(EventCost.Kind.ARTIFACT, 1)))
	assert_eq(run.event_blocked_reason(0), "EVENT_BLOCK_ARTIFACT")
	run.add_artifact(_content.artifacts[0], _content.modifiers.artifact_editions()[0])
	var stones := run.stones
	assert_true(run.choose(0))
	assert_true(run.artifacts.is_empty())
	assert_true(run.artifact_editions.is_empty(), "son aura part avec lui")
	assert_eq(run.stones, stones, "perdu, pas vendu")


func test_cout_d_une_main_au_prochain_goulot() -> void:
	var run := _run()
	_open(run, _choice([_outcome([])], _cost(EventCost.Kind.HANDS, 1)))
	assert_true(run.choose(0))
	assert_true(run.end_event())
	assert_true(run.fight())
	assert_eq(run.current_round.hands_left, run.round_rules().hands_per_round - 1)
	assert_eq(run.hand_penalty, 0, "payee une seule fois")


func test_effets_des_presages_reutilises() -> void:
	var run := _run()
	var level := LevelHandOmenEffect.new()
	level.amount = 2
	level.fallback_hand = &"main_paire"
	var level_effect := RunEventEffect.new()
	level_effect.effect = level
	var copy_effect := RunEventEffect.new()
	copy_effect.effect = CardOmenEffect.new()
	var omen := OmenEventEffect.new()
	omen.omen = _content.omen_by_id(&"presage_don_celeste")
	var size := run.cards().size()
	var stones := run.stones
	_open(run, _choice([_outcome([_stones(3), level_effect, copy_effect, omen])]))
	assert_true(run.choose(0))
	assert_eq(run.stones, stones + 3)
	assert_eq(run.hand_levels.level_of("main_paire"), 3)
	assert_eq(run.cards().size(), size + 1)
	assert_eq(run.pending_omens.size(), 1, "presage differe : attend la prochaine boutique")
	assert_eq(run.pending_omens[0], omen.omen)


func test_effets_de_pilule_sur_des_cartes_au_hasard() -> void:
	var run := _run()
	var imbue := ImbuePillEffect.new()
	imbue.talisman = _content.modifiers.talismans[0]
	var on_cards := CardsEventEffect.new()
	on_cards.effect = imbue
	on_cards.count = 2
	var destroy := CardsEventEffect.new()
	destroy.effect = DestroyPillEffect.new()
	var size := run.cards().size()
	_open(run, _choice([_outcome([on_cards, destroy])]))
	assert_true(run.choose(0))
	assert_eq(run.cards().filter(func(card: CardInstance) -> bool: return card.talisman != null).size(), 2)
	assert_eq(run.cards().size(), size - 1, "carte detruite hors d'un round")
	var ranks := CardsEventEffect.new()
	ranks.effect = AddRankPillEffect.new()
	ranks.count = 3
	var other := _run()
	var before: int = _rank_total(other)
	_open(other, _choice([_outcome([ranks])]))
	assert_true(other.choose(0))
	assert_gt(_rank_total(other), before, "rangs montes")


func _rank_total(run: RunState) -> int:
	return run.cards().reduce(func(total: int, card: CardInstance) -> int: return total + card.rank, 0)


func test_artefact_selon_rarete_et_emplacements() -> void:
	var run := _run()
	_open(run, _choice([_outcome([ArtifactEventEffect.new()])]))
	assert_true(run.choose(0))
	assert_eq(run.artifacts.size(), 1)
	var full := _run()
	while full.artifact_slots_used() < full.max_artifacts():
		full.add_artifact(_content.artifacts[full.artifacts.size()])
	_open(full, _choice([_outcome([ArtifactEventEffect.new()])]))
	assert_eq(full.event_blocked_reason(0), "EVENT_BLOCK_ARTIFACT_SLOT")
	var none := _run()
	var pool: Array[ArtifactDefinition] = [_content.artifacts[0]]
	none.artifact_pool = pool
	none.add_artifact(_content.artifacts[0])
	_open(none, _choice([_outcome([ArtifactEventEffect.new()])]))
	assert_eq(none.event_blocked_reason(0), "EVENT_BLOCK_NO_ARTIFACT", "jamais un artefact deja possede")


func test_pilule_et_emplacements() -> void:
	var run := _run()
	_open(run, _choice([_outcome([PillEventEffect.new()])]))
	assert_true(run.choose(0))
	assert_eq(run.pills.size(), 1)
	while run.pills.size() < run.max_pills():
		run.pills.append(_content.pills[0])
	_open(run, _choice([_outcome([PillEventEffect.new()])]))
	assert_eq(run.event_blocked_reason(0), "EVENT_BLOCK_PILL_SLOT")


## Une issue aleatoire bloquee bloque le choix : le hasard ne tombe jamais sur une issue vide.
func test_issue_aleatoire_deterministe() -> void:
	var picks: Array[int] = []
	for attempt: int in 2:
		var run := _run(1.0, "HASARD")
		_open(run, _choice([_outcome([_stones(1)], 3.0), _outcome([_stones(2)], 1.0)]))
		run.choose(0)
		picks.append(run.event_outcome)
	assert_eq(picks[0], picks[1], "meme graine, meme issue")
	var choice := _choice([_outcome([], 3.0), _outcome([], 1.0)])
	assert_eq(choice.percent_of(0), 75)
	assert_eq(choice.percent_of(1), 25)
	var counts := [0, 0]
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i: int in 1000:
		counts[choice.roll(rng)] += 1
	assert_almost_eq(counts[0] / 1000.0, 0.75, 0.05)


func test_textes_des_effets() -> void:
	assert_eq(_stones(4).describe(), tr("EVENT_FX_STONES") % 4)
	assert_eq(_outcome([]).describe(), tr("EVENT_FX_NOTHING"))
	assert_eq(_cost(EventCost.Kind.HANDS, 1).describe(), tr("EVENT_COST_HANDS") % 1)
	for event: EventDefinition in _content.events:
		for choice: EventChoice in event.choices:
			for outcome: EventOutcome in choice.outcomes:
				for effect: EventEffect in outcome.effects:
					assert_false(effect.describe().is_empty(), "%s : effet sans texte" % event.id)
