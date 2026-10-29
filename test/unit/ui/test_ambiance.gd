extends GutTest
## Fond lavis et papier : charges pour tout le jeu, ne captent pas la souris, texte lisible par-dessus.

const Contrast := preload("res://test/helpers/contrast.gd")
const SCENE := preload("res://ui/theme/ambiance.tscn")
const THEME_PATH := "res://ui/theme/lavis_de_nuit.tres"
const LAVIS_COLORS := ["base_color", "deep_color", "ink_color"]
const AMBIANCES_DIR := "res://ui/ambiances"
## Ambiances qui ne correspondent a aucun goulot.
const SPECIAL_IDS: Array[StringName] = [&"menu", &"nuit", &"boutique"]


func test_ambiance_chargee_pour_tout_le_jeu() -> void:
	assert_eq(ProjectSettings.get_setting("autoload/Ambiance", ""), "*res://ui/theme/ambiance.tscn")


func test_fond_derriere_et_papier_devant() -> void:
	var ambiance: Node = add_child_autofree(SCENE.instantiate())
	assert_lt((ambiance.get_node("Fond") as CanvasLayer).layer, 0)
	assert_gt((ambiance.get_node("Dessus") as CanvasLayer).layer, 0)
	for path: String in ["Fond/Lavis", "Dessus/Papier"]:
		var rect := ambiance.get_node(path) as ColorRect
		assert_true(rect.material is ShaderMaterial, "%s sans shader" % path)
		assert_eq(rect.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s capte la souris" % path)


func test_texte_lisible_sur_le_lavis() -> void:
	var theme: Theme = load(THEME_PATH)
	var texte: Color = theme.get_color("font_color", "Label")
	var material: ShaderMaterial = load("res://ui/theme/lavis.tres")
	for uniform: String in LAVIS_COLORS:
		var fond: Color = material.get_shader_parameter(uniform)
		assert_gt(Contrast.ratio(texte, fond), 4.5, "texte sur %s" % uniform)


func test_texte_lisible_quand_le_fond_prend_la_couleur_d_un_element() -> void:
	var theme: Theme = load(THEME_PATH)
	var texte: Color = theme.get_color("font_color", "Label")
	var material: ShaderMaterial = load("res://ui/theme/lavis.tres")
	var ink: Color = material.get_shader_parameter("ink_color")
	var strength: float = (load("res://ui/round/score_feel.tres") as ScoreFeel).pulse_strength
	for element: Element.Type in Element.Type.values():
		# Pire cas du shader : la zone d'encre la plus dense, au plus fort de la teinte.
		var fond := ink.lerp(ElementStyles.of(element).color, strength)
		assert_gt(Contrast.ratio(texte, fond), 4.5, "texte sur le lavis teinte %s" % Element.to_id(element))


func _ambiances() -> Array[AmbianceTheme]:
	var result: Array[AmbianceTheme] = []
	for resource: Resource in ContentLoader.load_all(AMBIANCES_DIR):
		result.append(resource as AmbianceTheme)
	return result


func _bottleneck_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for resource: Resource in ContentLoader.load_all("res://content/bottlenecks"):
		ids.append((resource as BottleneckDefinition).id)
	return ids


## Ajouter une tribulation = son goulot + une ambiance de meme id : un oubli est detecte ici.
func test_chaque_tribulation_a_son_ambiance() -> void:
	var ids: Array[StringName] = []
	for ambiance: AmbianceTheme in _ambiances():
		ids.append(ambiance.id)
	for resource: Resource in ContentLoader.load_all("res://content/bottlenecks"):
		var bottleneck := resource as BottleneckDefinition
		if bottleneck.constraint != null:
			assert_has(ids, bottleneck.id, "tribulation sans ambiance : %s" % bottleneck.id)


func test_chaque_ambiance_correspond_a_un_goulot_ou_un_id_special() -> void:
	var known := _bottleneck_ids()
	known.append_array(SPECIAL_IDS)
	for ambiance: AmbianceTheme in _ambiances():
		assert_has(known, ambiance.id, "ambiance orpheline : %s" % ambiance.resource_path)


func test_texte_lisible_sur_chaque_ambiance() -> void:
	var theme: Theme = load(THEME_PATH)
	var texte: Color = theme.get_color("font_color", "Label")
	var strength: float = (load("res://ui/round/score_feel.tres") as ScoreFeel).pulse_strength
	for ambiance: AmbianceTheme in _ambiances():
		for fond: Color in [ambiance.base_color, ambiance.deep_color, ambiance.ink_color]:
			assert_gt(Contrast.ratio(texte, fond), 4.5, "texte sur %s" % ambiance.id)
		for element: Element.Type in Element.Type.values():
			var teinte := ambiance.ink_color.lerp(ElementStyles.of(element).color, strength)
			assert_gt(Contrast.ratio(texte, teinte), 4.5, "%s teinte %s" % [ambiance.id, Element.to_id(element)])


func test_apply_change_le_fond_et_la_meteo() -> void:
	var ambiance: Node = add_child_autofree(SCENE.instantiate())
	ambiance.fade_time = 0.0
	ambiance.apply(&"tribulation_flammes")
	var lavis: ShaderMaterial = (ambiance.get_node("Fond/Lavis") as ColorRect).material
	assert_eq(lavis.get_shader_parameter("base_color"), ambiance.current.base_color)
	assert_eq(ambiance.current.id, &"tribulation_flammes")
	assert_eq(ambiance.get_node("Fond/Meteo").get_child_count(), 1, "escarbilles")
	assert_ne(load("res://ui/theme/lavis.tres").get_shader_parameter("base_color"), ambiance.current.base_color,
		"le .tres partage n'est pas modifie")


func test_id_inconnu_donne_la_nuit() -> void:
	var ambiance: Node = add_child_autofree(SCENE.instantiate())
	ambiance.apply(&"goulot_petit")
	assert_eq(ambiance.current.id, &"nuit")


func test_reduire_les_animations_coupe_la_meteo() -> void:
	var ambiance: Node = add_child_autofree(SCENE.instantiate())
	ambiance.apply(&"tribulation_vent_noir")
	ambiance.reduce_motion = true
	await wait_process_frames(1)
	assert_eq(ambiance.get_node("Fond/Meteo").get_child_count(), 0)
	ambiance.reduce_motion = false
	assert_eq(ambiance.get_node("Fond/Meteo").get_child_count(), 1, "meteo revenue")


func test_fondu_a_l_encre_garde_l_ancienne_palette() -> void:
	var ambiance: Node = add_child_autofree(SCENE.instantiate())
	ambiance.fade_time = 0.0
	ambiance.apply(&"nuit")
	var lavis: ShaderMaterial = (ambiance.get_node("Fond/Lavis") as ColorRect).material
	var night: Color = lavis.get_shader_parameter("base_color")
	ambiance.fade_time = 1.0
	ambiance.apply(&"tribulation_demon")
	assert_eq(lavis.get_shader_parameter("old_base_color"), night, "l'ancienne encre reste sous la nouvelle")
	assert_eq(lavis.get_shader_parameter("blend"), 0.0, "le fondu commence")


## Chaque tribulation doit se reconnaitre au premier coup d'oeil : palette differente de la nuit.
func test_tribulations_differentes_de_la_nuit() -> void:
	var night: AmbianceTheme = load(AMBIANCES_DIR.path_join("nuit.tres"))
	for ambiance: AmbianceTheme in _ambiances():
		if ambiance.id in SPECIAL_IDS:
			continue
		assert_ne(ambiance.base_color, night.base_color, ambiance.id)
		assert_ne(ambiance.vignette_color, night.vignette_color, "bord teinte : %s" % ambiance.id)
		assert_not_null(ambiance.weather, "meteo : %s" % ambiance.id)


## Bug : sans derive, l'encre restait toujours du meme cote de l'ecran (la deformation seule la deplace a peine).
func test_le_lavis_derive_a_travers_l_ecran() -> void:
	var lavis: ShaderMaterial = load("res://ui/theme/lavis.tres")
	var drift: Vector2 = lavis.get_shader_parameter(&"drift")
	assert_gt(absf(drift.x), 0.0, "derive horizontale : l'encre passe a gauche comme a droite")


## Comme les boss de Balatro : chaque tribulation, le menu, la boutique et les rounds ont leur arrangement.
func test_chaque_ambiance_a_sa_propre_musique() -> void:
	var owners := {}
	for ambiance: AmbianceTheme in _ambiances():
		assert_false(owners.has(ambiance.music), "%s reprend la musique de %s" % [ambiance.id, owners.get(ambiance.music)])
		owners[ambiance.music] = ambiance.id


## Bug evite : apres le bilan d'une run, revenir a la meme ambiance doit relancer sa musique.
func test_meme_ambiance_reprend_sa_musique() -> void:
	var ambiance: Node = add_child_autofree(SCENE.instantiate())
	ambiance.apply(&"boutique")
	Sons.play_music(&"musique_victoire", 0.0)
	ambiance.apply(&"boutique")
	assert_eq(Sons.music_id(), &"musique_boutique")
	Sons.play_music(&"", 0.0)


func test_chaque_ambiance_a_une_musique_existante() -> void:
	for resource: Resource in ContentLoader.load_all(AMBIANCES_DIR):
		var ambiance := resource as AmbianceTheme
		assert_true(Sons.has_cue(ambiance.music), "nappe de %s : %s" % [ambiance.id, ambiance.music])


func test_apply_lance_la_nappe_de_l_ambiance() -> void:
	var ambiance: Node = add_child_autofree(SCENE.instantiate())
	ambiance.apply(&"boutique")
	assert_eq(Sons.music_id(), &"musique_boutique")
	Sons.play_music(&"", 0.0)



## Les particules de meteo suivent la taille reelle du viewport, pas seulement 1152x648.
func test_meteo_etalee_sur_la_taille_du_viewport() -> void:
	var ambiance: Node = add_child_autofree(SCENE.instantiate())
	var particles := CPUParticles2D.new()
	particles.position = Vector2(576, 700)
	particles.emission_rect_extents = Vector2(700, 20)
	ambiance.get_node("Fond/Meteo").add_child(particles)
	var base := Vector2(ProjectSettings.get_setting("display/window/size/viewport_width", 1152),
		ProjectSettings.get_setting("display/window/size/viewport_height", 648))
	ambiance.fit_weather(base * 2.0)
	assert_eq(particles.position, Vector2(1152, 1400))
	assert_eq(particles.emission_rect_extents, Vector2(1400, 40))
	ambiance.fit_weather(base)
	assert_eq(particles.position, Vector2(576, 700), "retour a la taille d'origine, sans cumul")
