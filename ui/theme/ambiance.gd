extends Node
## Autoload Ambiance : fond lavis et papier de tout le jeu, change selon l'ecran (goulot, boutique, menu).
## apply(id) fait un fondu a l'encre vers l'AmbianceTheme de cet id (ui/ambiances/), ou vers DEFAULT_ID s'il n'y en a pas.

const AMBIANCES_DIR := "res://ui/ambiances"
const DEFAULT_ID := &"nuit"

## Duree du fondu entre deux ambiances.
@export var fade_time: float = 1.6

## Coupe la meteo, la respiration et le fondu.
var reduce_motion: bool = false:
	set(value):
		reduce_motion = value
		if is_node_ready():
			_set_weather(current)

var current: AmbianceTheme
var _themes: Dictionary[StringName, AmbianceTheme] = {}
var _fade: Tween
var _time: float = 0.0

@onready var _lavis: ShaderMaterial = ($Fond/Lavis as ColorRect).material
@onready var _papier: ShaderMaterial = ($Dessus/Papier as ColorRect).material
@onready var _weather: Node2D = $Fond/Meteo


func _ready() -> void:
	# Copies : le fondu ne modifie pas les .tres partages.
	_lavis = _lavis.duplicate()
	($Fond/Lavis as ColorRect).material = _lavis
	_papier = _papier.duplicate()
	($Dessus/Papier as ColorRect).material = _papier
	for resource: Resource in ContentLoader.load_all(AMBIANCES_DIR):
		var ambiance := resource as AmbianceTheme
		if ambiance != null:
			_themes[ambiance.id] = ambiance


func theme_of(id: StringName) -> AmbianceTheme:
	return _themes.get(id, _themes.get(DEFAULT_ID))


func apply(id: StringName) -> void:
	var ambiance := theme_of(id)
	if ambiance == null:
		return
	# Le son n'est pas du mouvement : la musique garde son fondu meme avec « Reduire les animations ».
	# Avant le test de palette : apres le bilan d'une run, la meme ambiance doit reprendre sa musique.
	Sons.play_music(ambiance.music, fade_time)
	if ambiance == current:
		return
	current = ambiance
	if _fade != null:
		_fade.kill()
	var time: float = 0.0 if reduce_motion else fade_time
	# Palette posee tout de suite ; l'ancienne reste visible et recule par taches pendant le fondu.
	for parameter: StringName in [&"base_color", &"deep_color", &"ink_color"]:
		_lavis.set_shader_parameter(StringName("old_" + parameter), _lavis.get_shader_parameter(parameter))
		_lavis.set_shader_parameter(parameter, ambiance.get(parameter))
	_lavis.set_shader_parameter(&"blend", 0.0 if time > 0.0 else 1.0)
	var targets := {
		_lavis: {&"speed": ambiance.speed, &"scale": ambiance.scale, &"warp": ambiance.warp,
			&"strength": ambiance.strength, &"blend": 1.0},
		_papier: {&"vignette": ambiance.vignette, &"vignette_color": ambiance.vignette_color},
	}
	if time > 0.0:
		_fade = create_tween().set_parallel()
	for material: ShaderMaterial in targets:
		for parameter: StringName in targets[material]:
			if time > 0.0:
				_fade.tween_property(material, "shader_parameter/" + parameter, targets[material][parameter], time)
			else:
				material.set_shader_parameter(parameter, targets[material][parameter])
	_set_weather(ambiance)


func _set_weather(ambiance: AmbianceTheme) -> void:
	for child: Node in _weather.get_children():
		_weather.remove_child(child)
		child.queue_free()
	if ambiance != null and ambiance.weather != null and not reduce_motion:
		_weather.add_child(ambiance.weather.instantiate())


func _process(delta: float) -> void:
	if current == null or current.vignette_breath <= 0.0 or reduce_motion or (_fade != null and _fade.is_running()):
		return
	_time += delta
	_papier.set_shader_parameter(&"vignette", current.vignette + sin(_time * current.breath_speed) * current.vignette_breath)
