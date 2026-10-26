class_name RoundEnd
extends Control
## Fin d'un goulot, par-dessus l'ecran de round. Victoire : le sceau 破 tombe, une onde de choc part, des cristaux
## de pierres tombent sur le compteur. Echec : des fissures de feu s'ouvrent, l'encre noire envahit l'ecran.
## Affichage seulement : la run a deja note la victoire ou la defaite.

signal menu_requested

const WAVE_SHADER := preload("res://ui/round/onde.gdshader")
const INK_SHADER := preload("res://ui/round/encre_noire.gdshader")
## Sceau decoratif, identique dans toutes les langues.
const VICTORY_GLYPH := "破"

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
	if settings.reduce_motion or count <= 0 or not to.is_finite():
		return
	var crystals: int = mini(count, feel.crystal_max)
	for i: int in crystals:
		var crystal := ColorRect.new()
		crystal.mouse_filter = MOUSE_FILTER_IGNORE
		crystal.color = feel.crystal_color
		crystal.size = Vector2.ONE * feel.crystal_size
		crystal.pivot_offset = crystal.size / 2
		# Carre tourne d'un quart : un losange, comme une pierre taillee.
		crystal.rotation = PI / 4
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


## Fissures puis encre, le texte d'echec et un bouton vers le menu. Reste a l'ecran.
func defeat(text: String) -> void:
	# L'encre recouvre l'ecran : elle prend les clics, son propre bouton mene au menu.
	mouse_filter = MOUSE_FILTER_STOP
	var ink := ColorRect.new()
	ink.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	ink.mouse_filter = MOUSE_FILTER_IGNORE
	var shader := ShaderMaterial.new()
	shader.shader = INK_SHADER
	ink.material = shader
	add_child(ink)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	var label := Label.new()
	label.theme_type_variation = &"HandAnnounce"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(label)
	var button := Button.new()
	button.text = "UI_MENU"
	button.size_flags_horizontal = SIZE_SHRINK_CENTER
	button.pressed.connect(menu_requested.emit)
	column.add_child(button)
	center.add_child(column)
	add_child(center)
	if settings.reduce_motion or feel.defeat_time <= 0.0:
		shader.set_shader_parameter(&"progress", 1.0)
		return
	center.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_method(func(value: float) -> void: shader.set_shader_parameter(&"progress", value), 0.0, 1.0, feel.defeat_time)
	tween.tween_property(center, "modulate:a", 1.0, feel.defeat_time * 0.2)
	await tween.finished


func _wave() -> void:
	if feel.wave_time <= 0.0:
		return
	var ring := ColorRect.new()
	ring.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	ring.mouse_filter = MOUSE_FILTER_IGNORE
	var shader := ShaderMaterial.new()
	shader.shader = WAVE_SHADER
	ring.material = shader
	add_child(ring)
	move_child(ring, 0)
	var tween := ring.create_tween()
	tween.tween_method(func(value: float) -> void: shader.set_shader_parameter(&"progress", value), 0.0, 1.0, feel.wave_time)
	tween.tween_callback(ring.queue_free)
