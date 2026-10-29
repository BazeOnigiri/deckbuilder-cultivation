extends GutTest
## Presages dans le profil : vus a l'annonce (compendium), succes « passer 3 goulots dans une partie ».

var _content: GameContent
## Garde le tracker en vie pendant le test : ses connexions de signaux partent avec lui.
var _tracker: ProfileTracker


func before_all() -> void:
	_content = GameContent.load_default()


func _tracked(profile: ProfileStats) -> RunState:
	_tracker = ProfileTracker.new(profile, _content.profile_rules, _content.unlocks)
	var run := _content.new_run(RandomNumberGenerator.new(), RunSetup.custom("PROFIL", 1, false, ""))
	_tracker.track(run)
	return run


func test_presages_annonces_vus_dans_le_compendium() -> void:
	var profile := ProfileStats.new()
	var run := _tracked(profile)
	var compendium := Compendium.new(_content, profile)
	assert_eq(compendium.seen_count(Compendium.Kind.OMEN), 0)
	assert_eq(compendium.total(Compendium.Kind.OMEN), _content.omens.size())
	run.announce()
	var offered := run.omen_offers.filter(func(omen: OmenDefinition) -> bool: return omen != null)
	assert_false(offered.is_empty())
	for omen: OmenDefinition in offered:
		assert_true(compendium.is_seen(Compendium.Kind.OMEN, omen))
	assert_eq(Compendium.kind_of(offered[0]), Compendium.Kind.OMEN)


func test_succes_trois_goulots_passes() -> void:
	var run := _tracked(ProfileStats.new())
	var got: Array[StringName] = []
	_tracker.achieved.connect(func(achievement: AchievementDefinition) -> void: got.append(achievement.id))
	run.announce()
	var skipped := 0
	while skipped < 3:
		assert_false(got.has(&"succes_trois_presages"), "pas avant le troisieme")
		if run.can_skip():
			run.skip()
			skipped += 1
		else:
			# Tribulation : on la franchit pour passer au royaume suivant.
			run.fight()
			run.current_round.finished.emit(true)
			run.announce()
	assert_has(got, &"succes_trois_presages")
