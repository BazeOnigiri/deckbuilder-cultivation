extends GutTest


func test_version_courante_inchangee() -> void:
	var data := SaveMigrator.migrate({"version": 2, "x": 1}, 2, {})
	assert_eq(data["x"], 1)


func test_migrations_enchainees_dans_l_ordre() -> void:
	var migrations := {
		1: func(d: Dictionary) -> Dictionary:
			d["trace"] = "a"
			return d,
		2: func(d: Dictionary) -> Dictionary:
			d["trace"] += "b"
			return d,
	}
	var data := SaveMigrator.migrate({"version": 1}, 3, migrations)
	assert_eq(data["trace"], "ab")
	assert_eq(data["version"], 3)


func test_version_future_ignoree() -> void:
	assert_eq(SaveMigrator.migrate({"version": 9}, 1, {}), {})


func test_version_absente_traitee_comme_la_premiere() -> void:
	var migrations := {1: func(d: Dictionary) -> Dictionary:
		d["migre"] = true
		return d}
	assert_true(SaveMigrator.migrate({"x": 1}, 2, migrations)["migre"])

func test_version_illisible_refusee_sans_planter() -> void:
	for bad: Variant in [null, [1], {"a": 1}, "2"]:
		assert_eq(SaveMigrator.migrate({"version": bad, "x": 1}, 2, {}), {})
	assert_eq(SaveMigrator.migrate({"version": 2.0, "x": 1}, 2, {})["x"], 1)
