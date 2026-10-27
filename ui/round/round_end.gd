class_name RoundEnd
extends Control
## Fin d'un goulot, par-dessus l'ecran de round. Victoire : le sceau 破 tombe, une onde de choc part, des cristaux
## de pierres tombent sur le compteur. Fin de run : rouleau du bilan, apres l'encre noire en cas d'echec.
## Affichage seulement : la run a deja note la victoire ou la defaite.

signal menu_requested

const WAVE_SHADER := preload("res://ui/round/onde.gdshader")
const INK_SHADER := preload("res://ui/round/encre_noire.gdshader")
## Sceau decoratif, identique dans toutes les langues.
const VICTORY_GLYPH := "破"
## Parametres globaux du lavis (project.godot), partages avec la sequence de score.
const PULSE_COLOR := &"pulse_color"
const PULSE_STRENGTH := &"pulse_strength"

var feel: RoundEndFeel = preload("res://ui/round/round_end_feel.tres")
var settings: GameSettings = GameSettings.new()


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE


## Sceau 破 et onde de choc. Rend la main quand le sceau s'est efface.
func victory() -> void:
	var seal := PanelContainer.new()
	seal.theme_type_variation = &"VictorySeal"
	seal.mouse_filter = MOUSE_FILTER_IGNORE
	var glyph := Label.new()
	glyph.theme_type_variation = &"VictoryGlyph"
	glyph.text = VICTORY_GLYPH
	seal.add_child(glyph)
	add_child(seal)
	seal.reset_size()
	seal.pivot_offset = seal.size / 2
	var rest := size / 2 - seal.size / 2
	var tween := seal.create_tween()
	var fall: float = feel.seal_time * 0.3
	if settings.reduce_motion:
		seal.position = rest
		tween.tween_interval(fall)
		tween.tween_callback(Sons.play.bind(&"victoire", 0))
	else:
		seal.position = rest - Vector2(0, feel.seal_drop)
		seal.scale = Vector2.ONE * 2.0
		seal.modulate.a = 0.0
		# parallel() par etape, pas set_parallel() : celui-ci rendrait aussi paralleles les etapes suivantes.
		tween.tween_property(seal, "position", rest, fall).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(seal, "scale", Vector2.ONE, fall).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(seal, "modulate:a", 1.0, fall)
		tween.tween_callback(_wave)
	tween.tween_interval(feel.seal_time * 0.4)
	tween.tween_property(seal, "modulate:a", 0.0, feel.seal_time * 0.3)
	await tween.finished
	# Libere apres l'attente : un noeud libere tue son tween, qui n'emettrait jamais finished.
	seal.queue_free()


## count pierres gagnees : des cristaux tombent sur `to` (coordonnees globales), puis bump est appele.
func stones(count: int, to: Vector2, bump: Callable) -> void:
	if count <= 0:
		return
	Sons.play(&"pierres")
	if settings.reduce_motion or not to.is_finite():
		return
	var crystals: int = mini(count, feel.crystal_max)
	for i: int in crystals:
		var crystal := StoneIcon.new()
		crystal.side = feel.crystal_size
		add_child(crystal)
		var landing := to - crystal.size / 2 + Vector2((i - crystals / 2.0) * feel.crystal_size * 0.6, 0)
		crystal.global_position = landing - Vector2(0, feel.crystal_fall)
		crystal.modulate.a = 0.0
		var tween := crystal.create_tween()
		tween.tween_interval(i * feel.crystal_stagger)
		tween.tween_property(crystal, "modulate:a", 1.0, 0.0)
		tween.tween_property(crystal, "global_position", landing, feel.crystal_time).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		# Le compteur saute avant la liberation : un noeud libere arrete son tween.
		if i == crystals - 1:
			tween.tween_callback(bump)
		tween.tween_callback(crystal.queue_free)


## Fin de la run : victoire, un voile puis le rouleau du bilan ; echec, les fissures et l'encre noire d'abord.
## Le rouleau porte le titre, le bilan (summary) et le sceau du menu. Reste a l'ecran.
func run_over(won: bool, summary: Control) -> void:
	# Le rouleau couvre l'ecran : il prend les clics, son propre sceau mene au menu.
	mouse_filter = MOUSE_FILTER_STOP
	Sons.play_music(feel.victory_music if won else feel.defeat_music, feel.music_fade)
	if not won:
		Sons.play(&"defaite")
	var animated := not settings.reduce_motion and feel.defeat_time > 0.0
	var backdrop: ColorRect = null
	if not won:
		backdrop = ColorRect.new()
		var shader := ShaderMaterial.new()
		shader.shader = INK_SHADER
		backdrop.material = shader
	var veil := PanelContainer.new()
	veil.theme_type_variation = &"Veil"
	veil.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	veil.mouse_filter = MOUSE_FILTER_IGNORE
	if backdrop != null:
		backdrop.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		backdrop.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(backdrop)
	else:
		add_child(veil)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var scroll := ScrollPanel.new()
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", get_theme_constant(&"separation", &"ScrollPanel"))
	var title := SideColumn.make_label(&"ScrollTitle", "UI_RUN_WON" if won else "UI_RUN_LOST")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size.x = get_theme_constant(&"text_width", &"ScrollPanel")
	column.add_child(title)
	column.add_child(summary)
	var button := Button.new()
	button.theme_type_variation = &"SealButton"
	button.text = "UI_MENU"
	button.size_flags_horizontal = SIZE_SHRINK_CENTER
	button.pressed.connect(menu_requested.emit)
	column.add_child(button)
	scroll.add_child(column)
	center.add_child(scroll)
	add_child(center)
	if not animated:
		if backdrop != null:
			(backdrop.material as ShaderMaterial).set_shader_parameter(&"progress", 1.0)
		return
	if backdrop != null:
		center.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_method(func(value: float) -> void: (backdrop.material as ShaderMaterial).set_shader_parameter(&"progress", value),
			0.0, 1.0, feel.defeat_time)
		tween.tween_callback(scroll.unroll.bind(get_theme_constant(&"unroll_ms", &"ScrollPanel") / 1000.0))
		tween.tween_property(center, "modulate:a", 1.0, feel.defeat_time * 0.1)
		await tween.finished
	else:
		scroll.unroll(get_theme_constant(&"unroll_ms", &"ScrollPanel") / 1000.0)


func _wave() -> void:
	Sons.play(&"victoire")
	if feel.wave_time <= 0.0:
		return
	_ring(0.0)
	_ring(feel.wave_echo)
	_flash_sky()
	_pulse_background()


func _ring(delay: float) -> void:
	var ring := ColorRect.new()
	ring.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	ring.mouse_filter = MOUSE_FILTER_IGNORE
	var shader := ShaderMaterial.new()
	shader.shader = WAVE_SHADER
	shader.set_shader_parameter(&"width", feel.wave_width)
	shader.set_shader_parameter(&"ring_color", feel.victory_color)
	ring.material = shader
	add_child(ring)
	move_child(ring, 0)
	var tween := ring.create_tween()
	tween.tween_interval(delay)
	tween.tween_method(func(value: float) -> void: shader.set_shader_parameter(&"progress", value), 0.0, 1.0, feel.wave_time)
	tween.tween_callback(ring.queue_free)


func _flash_sky() -> void:
	var sky := ColorRect.new()
	sky.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	sky.mouse_filter = MOUSE_FILTER_IGNORE
	sky.color = Color(feel.victory_color, feel.victory_flash)
	add_child(sky)
	move_child(sky, 0)
	var tween := sky.create_tween()
	tween.tween_property(sky, "color:a", 0.0, feel.victory_flash_time)
	tween.tween_callback(sky.queue_free)


## Le lavis se teinte d'or puis revient : meme parametre que la teinte d'element de la sequence.
func _pulse_background() -> void:
	RenderingServer.global_shader_parameter_set(PULSE_COLOR, feel.victory_color)
	create_tween().tween_method(func(value: float) -> void:
		RenderingServer.global_shader_parameter_set(PULSE_STRENGTH, value), feel.victory_pulse, 0.0, feel.victory_pulse_time)
