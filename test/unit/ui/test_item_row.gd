extends GutTest
## Rangee haute : emplacements d'artefacts et de pilules, bond d'un artefact pendant la sequence.


func _row() -> ItemRow:
	var row := ItemRow.new()
	return add_child_autofree(row)


func _artifact(glyph: String) -> ArtifactDefinition:
	var artifact := ArtifactDefinition.new()
	artifact.glyph = glyph
	return artifact


func _filled(slots: Node) -> int:
	var count: int = 0
	for slot: ItemSlot in slots.get_children():
		if not slot.glyph.is_empty():
			count += 1
	return count


func test_emplacements_libres_jusqu_au_maximum() -> void:
	var row := _row()
	var artifacts: Array[ArtifactDefinition] = [_artifact("a"), _artifact("b")]
	row.show_artifacts(artifacts, 5)
	assert_eq(row._artifact_slots.get_child_count(), 5)
	assert_eq(_filled(row._artifact_slots), 2)
	assert_eq(row._artifact_caption.text, tr("UI_ITEMS_ARTIFACTS") % [2, 5])


func test_pilule_inutilisable_desactivee() -> void:
	var row := _row()
	var pills: Array[PillDefinition] = [PillDefinition.new(), PillDefinition.new()]
	pills[0].glyph = "a"
	pills[1].glyph = "b"
	var usable: Array[bool] = [true, false]
	row.show_pills(pills, 2, usable)
	assert_false((row._pill_slots.get_child(0) as ItemSlot).disabled)
	assert_true((row._pill_slots.get_child(1) as ItemSlot).disabled)


func test_clic_sur_une_pilule_donne_son_index() -> void:
	var row := _row()
	var pills: Array[PillDefinition] = [PillDefinition.new(), PillDefinition.new()]
	var usable: Array[bool] = [true, true]
	row.show_pills(pills, 2, usable)
	watch_signals(row)
	(row._pill_slots.get_child(1) as ItemSlot).pressed.emit()
	assert_signal_emitted_with_parameters(row, "pill_pressed", [1])


func test_artefact_affiche_luit_et_renvoie_son_centre() -> void:
	var row := _row()
	var shown := _artifact("a")
	var artifacts: Array[ArtifactDefinition] = [shown]
	row.show_artifacts(artifacts, 3)
	await wait_physics_frames(1)
	var at := row.artifact_hit(shown)
	assert_true(at.is_finite())
	var slot := row._artifact_slots.get_child(0) as ItemSlot
	assert_eq(at, slot.get_global_rect().get_center(), "l'orbe part du centre de l'emplacement")
	assert_gt(slot.glow_amount, 0.0, "aura posee")
	assert_eq(row.artifact_hit(_artifact("b")), Vector2.INF, "artefact absent : pas d'emplacement")


## Premier appui : sceau « Vendre (n) » ; second appui : demande de vente.
func test_deux_appuis_pour_vendre() -> void:
	var row := _row()
	var artifacts: Array[ArtifactDefinition] = [_artifact("a"), _artifact("b")]
	row.show_artifacts(artifacts, 3, [2, 3])
	watch_signals(row)
	row.press_artifact(1)
	assert_not_null(row._seal)
	assert_eq(row._seal.text, tr("UI_SELL") % 3)
	assert_signal_not_emitted(row, "artifact_sell_requested")
	row.press_artifact(1)
	assert_signal_emitted_with_parameters(row, "artifact_sell_requested", [1])
	assert_null(row._seal)


func test_sans_prix_pas_de_vente() -> void:
	var row := _row()
	var artifacts: Array[ArtifactDefinition] = [_artifact("a")]
	row.show_artifacts(artifacts, 3)
	watch_signals(row)
	row.press_artifact(0)
	row.press_artifact(0)
	assert_signal_not_emitted(row, "artifact_sell_requested")


func test_deux_appuis_pour_vendre_une_pilule() -> void:
	var row := _row()
	var pills: Array[PillDefinition] = [PillDefinition.new(), PillDefinition.new()]
	var usable: Array[bool] = [true, true]
	row.show_pills(pills, 2, usable, [1, 4])
	watch_signals(row)
	row.press_pill_sale(1)
	assert_eq(row._seal.text, tr("UI_SELL") % 4)
	assert_signal_not_emitted(row, "pill_sell_requested")
	row.press_pill_sale(1)
	assert_signal_emitted_with_parameters(row, "pill_sell_requested", [1])
	assert_null(row._seal)
