extends GutTest
## Fiches de sons (content/sons) : ID unique egal au nom du fichier, flux charge, bus existant.


func test_fiches_valides() -> void:
	var ids := {}
	for res: Resource in ContentLoader.load_all(SoundBank.DEFAULT_DIR):
		var cue := res as SoundCue
		assert_not_null(cue, res.resource_path)
		if cue == null:
			continue
		assert_eq(String(cue.id), res.resource_path.get_file().get_basename(), "ID = nom du fichier")
		assert_false(ids.has(cue.id), "ID en double : %s" % cue.id)
		ids[cue.id] = true
		assert_not_null(cue.stream, String(cue.id))
		assert_gt(AudioServer.get_bus_index(cue.bus), -1, "bus %s de %s" % [cue.bus, cue.id])
	assert_gt(ids.size(), 0)
