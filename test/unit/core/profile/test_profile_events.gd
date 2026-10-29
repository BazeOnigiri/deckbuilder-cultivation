extends GutTest
## Rencontres et profil : une rencontre ouverte est vue (compendium), le succes compte les rencontres differentes.

var _content: GameContent
## Garde le tracker en vie pendant le test : sinon ses connexions de signaux partent avec lui.
var _tracker: ProfileTracker


func before_all() -> void:
	_content = GameContent.load_default()


func test_rencontre_vue_et_succes_a_cinq() -> void:
	var profile := ProfileStats.new()
	_tracker = ProfileTracker.new(profile, _content.profile_rules, _content.unlocks)
	var run := _content.new_run(RandomNumberGenerator.new(), RunSetup.custom("PROFIL", 1, false, ""))
	_tracker.track(run)
	var compendium := Compendium.new(_content, profile)
	var achieved: Array[StringName] = []
	_tracker.achieved.connect(func(achievement: AchievementDefinition) -> void: achieved.append(achievement.id))
	for i: int in 5:
		run.status = RunState.Status.BETWEEN_ROUNDS
		run.start_event(_content.events[i])
		assert_true(compendium.is_seen(Compendium.Kind.EVENT, _content.events[i]))
		if i < 4:
			assert_does_not_have(achieved, &"succes_cinq_rencontres")
	assert_eq(compendium.seen_count(Compendium.Kind.EVENT), 5)
	assert_has(achieved, &"succes_cinq_rencontres")


func test_kind_of_et_entrees() -> void:
	assert_eq(Compendium.kind_of(_content.events[0]), Compendium.Kind.EVENT)
	assert_eq(Compendium.new(_content, ProfileStats.new()).total(Compendium.Kind.EVENT), _content.events.size())
