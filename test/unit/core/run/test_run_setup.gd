extends GutTest
## Options d'une partie : graine en texte, partie du jour, defis, aller-retour par la sauvegarde.

var _content: GameContent


func before_all() -> void:
	_content = GameContent.load_default()


func test_graine_texte_stable_sans_casse_ni_espaces() -> void:
	assert_eq(RunSetup.seed_of("wuxing"), RunSetup.seed_of("  WUXING "))
	assert_eq(RunSetup.seed_of("WUXING"), "WUXING".hash(), "meme valeur d'un lancement a l'autre")
	assert_ne(RunSetup.seed_of("WUXING"), RunSetup.seed_of("WUXINH"))


func test_graine_tiree_lisible_et_reproductible() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var code := RunSetup.random_code(rng)
	assert_eq(code.length(), RunSetup.CODE_LENGTH)
	for i: int in code.length():
		assert_true(RunSetup.CODE_ALPHABET.contains(code[i]))
	rng.seed = 3
	assert_eq(RunSetup.random_code(rng), code)


func test_partie_du_jour_stable_par_date_utc() -> void:
	assert_eq(RunSetup.daily_code(0), "1970-01-01")
	var morning := int(Time.get_unix_time_from_datetime_string("2026-10-29T00:00:01"))
	var evening := int(Time.get_unix_time_from_datetime_string("2026-10-29T23:59:59"))
	assert_eq(RunSetup.daily_code(morning), "2026-10-29")
	assert_eq(RunSetup.for_daily(morning).seed_text, RunSetup.for_daily(evening).seed_text)
	assert_ne(RunSetup.daily_code(evening + 2), "2026-10-29", "le lendemain, une autre partie")
	assert_true(RunSetup.for_daily(morning).daily)


func test_graine_saisie_sinon_tiree() -> void:
	assert_eq(RunSetup.custom(" abc ", 3, true, "ZZZ").seed_text, "ABC")
	var setup := RunSetup.custom("   ", 0, false, "ZZZ")
	assert_eq(setup.seed_text, "ZZZ")
	assert_eq(setup.difficulty, 1)
	assert_false(setup.random_tribulations)


func test_defi_impose_sa_graine_et_sa_difficulte() -> void:
	var challenge := ChallengeDefinition.new()
	challenge.seed_text = "destin"
	challenge.difficulty = 4
	challenge.random_tribulations = false
	var setup := RunSetup.for_challenge(challenge, "ZZZ")
	assert_eq(setup.seed_text, "DESTIN")
	assert_eq(setup.difficulty, 4)
	assert_false(setup.random_tribulations)
	challenge.seed_text = ""
	assert_eq(RunSetup.for_challenge(challenge, "ZZZ").seed_text, "ZZZ")


func test_aller_retour_par_json() -> void:
	var setup := RunSetup.for_challenge(_content.challenges[0], "ABCD")
	setup.daily = true
	var data: Dictionary = JSON.parse_string(JSON.stringify(setup.to_dict()))
	var restored := RunSetup.from_dict(data, _content)
	assert_eq(restored.seed_text, "ABCD")
	assert_true(restored.daily)
	assert_eq(restored.difficulty, setup.difficulty)
	assert_eq(restored.challenge, setup.challenge)
	assert_eq(restored.random_tribulations, setup.random_tribulations)


func test_valeurs_absentes_ou_abimees() -> void:
	var restored := RunSetup.from_dict({"seed": 12, "daily": "oui", "difficulty": -3, "challenge": "inconnu"}, _content)
	assert_eq(restored.seed_text, "")
	assert_false(restored.daily)
	assert_eq(restored.difficulty, 1)
	assert_null(restored.challenge)
	assert_eq(RunSetup.from_dict(null, _content).difficulty, 1)
