extends GutTest
## Deblocages et succes : chaque type de condition, filtre des catalogues, evenements enregistres une seule fois.

const PATH := "user://test_profil_deblocages.json"

var _content: GameContent
var _profile: ProfileStats


func before_all() -> void:
	_content = GameContent.load_default()


func before_each() -> void:
	_profile = ProfileStats.new()


func after_each() -> void:
	DirAccess.remove_absolute(PATH)


func _condition(kind: UnlockCondition.Kind, count: int = 1, target: StringName = &"") -> UnlockCondition:
	var condition := UnlockCondition.new()
	condition.kind = kind
	condition.count = count
	condition.target = target
	return condition


func _run() -> RunState:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	return _content.new_run(rng)


func test_parties_gagnees() -> void:
	var condition := _condition(UnlockCondition.Kind.WINS, 2)
	_profile.runs_won = 1
	assert_false(condition.is_met(UnlockContext.new(_profile)))
	_profile.runs_won = 2
	assert_true(condition.is_met(UnlockContext.new(_profile)))


func test_royaume_atteint() -> void:
	var condition := _condition(UnlockCondition.Kind.REALM, 3)
	_profile.best_realm = 2
	assert_false(condition.is_met(UnlockContext.new(_profile)))
	_profile.best_realm = 3
	assert_true(condition.is_met(UnlockContext.new(_profile)))


func test_main_jouee_n_fois() -> void:
	var condition := _condition(UnlockCondition.Kind.HAND_PLAYED, 2, &"main_paire")
	_profile.hands.record("main_paire")
	_profile.hands.record("main_brelan")
	assert_false(condition.is_met(UnlockContext.new(_profile)))
	_profile.hands.record("main_paire")
	assert_true(condition.is_met(UnlockContext.new(_profile)))


func test_artefacts_achetes_toutes_parties() -> void:
	var condition := _condition(UnlockCondition.Kind.ARTIFACTS_BOUGHT, 3)
	_profile.record_purchase(&"a")
	_profile.record_purchase(&"a")
	assert_false(condition.is_met(UnlockContext.new(_profile)))
	_profile.record_purchase(&"b")
	assert_true(condition.is_met(UnlockContext.new(_profile)))


func test_tribulations_vaincues() -> void:
	var condition := _condition(UnlockCondition.Kind.TRIBULATIONS_WON, 2)
	_profile.record_tribulation(&"x", true)
	_profile.record_tribulation(&"y", false)
	assert_false(condition.is_met(UnlockContext.new(_profile)))
	_profile.record_tribulation(&"y", true)
	assert_true(condition.is_met(UnlockContext.new(_profile)))


func test_meilleur_coup_et_parties_commencees() -> void:
	_profile.best_hand_score = 99
	_profile.runs_started = 4
	assert_false(_condition(UnlockCondition.Kind.BEST_SCORE, 100).is_met(UnlockContext.new(_profile)))
	assert_true(_condition(UnlockCondition.Kind.BEST_SCORE, 99).is_met(UnlockContext.new(_profile)))
	assert_false(_condition(UnlockCondition.Kind.GAMES, 5).is_met(UnlockContext.new(_profile)))
	assert_true(_condition(UnlockCondition.Kind.GAMES, 4).is_met(UnlockContext.new(_profile)))


func test_conditions_de_partie_fausses_hors_d_une_run() -> void:
	var ctx := UnlockContext.new(_profile)
	ctx.won = true
	ctx.one_hand_clears = 9
	for kind: UnlockCondition.Kind in [UnlockCondition.Kind.WIN_NO_PURCHASE, UnlockCondition.Kind.ONE_HAND_CLEARS,
			UnlockCondition.Kind.ARTIFACTS_OWNED, UnlockCondition.Kind.LEGACIES_OWNED]:
		assert_false(_condition(kind, 1).is_met(ctx), "kind %d" % kind)


func test_gagner_sans_acheter() -> void:
	var condition := _condition(UnlockCondition.Kind.WIN_NO_PURCHASE)
	var ctx := UnlockContext.new(_profile, _run())
	assert_false(condition.is_met(ctx), "pas encore gagne")
	ctx.won = true
	assert_true(condition.is_met(ctx))
	ctx.purchases = 1
	assert_false(condition.is_met(ctx))


func test_goulots_franchis_en_une_main() -> void:
	var condition := _condition(UnlockCondition.Kind.ONE_HAND_CLEARS, 2)
	var ctx := UnlockContext.new(_profile, _run())
	ctx.one_hand_clears = 1
	assert_false(condition.is_met(ctx))
	ctx.one_hand_clears = 2
	assert_true(condition.is_met(ctx))


func test_artefacts_et_heritages_possedes() -> void:
	var run := _run()
	var ctx := UnlockContext.new(_profile, run)
	var artifacts := _condition(UnlockCondition.Kind.ARTIFACTS_OWNED, 2)
	var legacies := _condition(UnlockCondition.Kind.LEGACIES_OWNED, 1)
	run.artifacts.append(_content.artifacts[0])
	assert_false(artifacts.is_met(ctx))
	run.artifacts.append(_content.artifacts[1])
	assert_true(artifacts.is_met(ctx))
	assert_false(legacies.is_met(ctx))
	run.legacies.append(_content.legacies[0])
	assert_true(legacies.is_met(ctx))


func test_description_nomme_la_main() -> void:
	var text := _condition(UnlockCondition.Kind.HAND_PLAYED, 5, &"main_brelan").describe(_content.hands)
	assert_string_contains(text, "5")
	assert_false(text.contains("main_brelan"), "la main est nommee, pas son id")


func test_le_filtre_retire_le_verrouille_et_garde_l_ordre() -> void:
	var open: Array = _content.unlocks.open(_content.artifacts, _profile)
	assert_lt(open.size(), _content.artifacts.size())
	var last := -1
	for artifact: ArtifactDefinition in open:
		assert_false(_content.unlocks.is_locked(artifact.id, _profile))
		var index := _content.artifacts.find(artifact)
		assert_gt(index, last, "ordre du catalogue garde")
		last = index


func test_debloquer_rouvre_le_contenu() -> void:
	var locked: ArtifactDefinition = _content.artifacts.filter(
		func(artifact: ArtifactDefinition) -> bool: return _content.unlocks.is_locked(artifact.id, _profile))[0]
	assert_true(_profile.unlock(locked.id))
	assert_false(_content.unlocks.open(_content.artifacts, _profile).filter(
		func(artifact: ArtifactDefinition) -> bool: return artifact.id == locked.id).is_empty())


func test_la_boutique_ne_propose_que_le_debloque() -> void:
	for seed_value: int in 20:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var run := _content.new_run(rng)
		run.stones = 1000
		var shop := _content.new_shop(run, rng, {}, _profile)
		for i: int in 3:
			var offered: Array[Resource] = shop.offered()
			for item: Resource in offered:
				assert_false(_content.unlocks.is_locked(item.id, _profile), "%s verrouille propose" % item.id)
			shop.reroll()
		for pack: PackDefinition in shop.pack_offers:
			if pack.kind != PackDefinition.Kind.CARD:
				assert_true(shop.buy_pack(shop.pack_offers.find(pack)))
				for choice: Resource in shop.opening.choices:
					assert_false(_content.unlocks.is_locked(choice.id, _profile))
				shop.skip()
				break


func test_meme_profil_meme_graine_meme_boutique() -> void:
	var other := ProfileStats.new()
	other.unlock(&"artefact_boussole")
	for profile: ProfileStats in [_profile, other]:
		var shops: Array = []
		for i: int in 2:
			var rng := RandomNumberGenerator.new()
			rng.seed = 7
			var run := _content.new_run(rng)
			var shop := _content.new_shop(run, rng, {}, profile)
			shop.reroll()
			shops.append([SaveData.ids(shop.offers), SaveData.ids(shop.pill_offers), SaveData.ids(shop.pack_offers),
				shop.legacy_offer().id if shop.legacy_offer() != null else &""])
		assert_eq(shops[0], shops[1])


func test_sans_profil_toute_la_boutique_est_ouverte() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var shop := _content.new_shop(_content.new_run(rng), rng)
	assert_true(shop.offers.size() + shop.pill_offers.size() > 0)


func test_la_boutique_reprise_garde_le_filtre() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var run := _content.new_run(rng)
	run.stones = 1000
	var shop := _content.new_shop(run, rng, {}, _profile)
	var again := _content.new_shop(run, rng, shop.to_dict(), _profile)
	assert_eq(SaveData.ids(again.offers), SaveData.ids(shop.offers))
	again.reroll()
	for item: Resource in again.offers:
		assert_false(_content.unlocks.is_locked(item.id, _profile))


func test_le_deblocage_est_enregistre_une_seule_fois() -> void:
	_profile.runs_won = 1
	var first := _content.unlocks.evaluate(UnlockContext.new(_profile))
	assert_has(first["unlocked"], &"artefact_boussole")
	assert_true(_profile.has_unlocked(&"artefact_boussole"))
	var second := _content.unlocks.evaluate(UnlockContext.new(_profile))
	assert_true(second["unlocked"].is_empty())
	assert_true(second["achieved"].is_empty())


func test_un_deblocage_reste_acquis() -> void:
	_profile.runs_won = 1
	_content.unlocks.evaluate(UnlockContext.new(_profile))
	_profile.runs_won = 0
	assert_false(_content.unlocks.is_locked(&"artefact_boussole", _profile))


func test_succes_obtenu_une_seule_fois() -> void:
	_profile.runs_won = 1
	var first := _content.unlocks.evaluate(UnlockContext.new(_profile))
	var ids: Array = first["achieved"].map(func(achievement: AchievementDefinition) -> StringName: return achievement.id)
	assert_has(ids, &"succes_premiere_victoire")
	assert_true(_profile.has_achievement(&"succes_premiere_victoire"))
	assert_true(_content.unlocks.evaluate(UnlockContext.new(_profile))["achieved"].is_empty())


func test_succes_de_partie_evalue_sur_la_run() -> void:
	var run := _run()
	var ctx := UnlockContext.new(_profile, run)
	ctx.won = true
	_content.unlocks.evaluate(ctx)
	assert_true(_profile.has_achievement(&"succes_voie_du_vide"), "gagne sans acheter")
	assert_false(_profile.has_achievement(&"succes_arsenal_complet"))
	for i: int in 5:
		run.artifacts.append(_content.artifacts[i])
	_content.unlocks.evaluate(ctx)
	assert_true(_profile.has_achievement(&"succes_arsenal_complet"))


func test_compendium_montre_la_condition_d_un_verrouille() -> void:
	var compendium := Compendium.new(_content, _profile)
	var boussole := _content.artifact_by_id(&"artefact_boussole")
	assert_true(compendium.is_locked(boussole))
	assert_not_null(compendium.unlock_condition(boussole))
	var starter := _content.artifact_by_id(&"artefact_cloche")
	assert_false(compendium.is_locked(starter))
	assert_null(compendium.unlock_condition(starter))
	_profile.unlock(boussole.id)
	assert_false(compendium.is_locked(boussole))


func test_profil_sauvegarde_les_deblocages_et_succes() -> void:
	_profile.unlock(&"artefact_boussole")
	_profile.achieve(&"succes_premiere_victoire")
	var storage := SaveStorage.new(PATH)
	assert_true(_profile.save_to(storage))
	var loaded := ProfileStats.load_from(storage)
	assert_true(loaded.has_unlocked(&"artefact_boussole"))
	assert_true(loaded.has_achievement(&"succes_premiere_victoire"))
	assert_false(loaded.has_unlocked(&"artefact_grue"))
