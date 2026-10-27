class_name SoundBank
extends Node
## Autoload « Sons » : joue les sons du jeu par ID (fiches SoundCue de content/sons/) et regle les volumes des bus.
## Le jeu ne connait que les ID : changer un son = regenerer sa fiche, sans toucher au code.

const DEFAULT_DIR := "res://content/sons"
## Sons simultanes au plus : au-dela, la voix la plus ancienne est reprise.
const VOICES := 12
## Bus reglables, dans l'ordre des volumes de GameSettings.
const MASTER_BUS := &"Master"
const MUSIC_BUS := &"Musique"
const EFFECTS_BUS := &"Effets"

## Variation de hauteur des sons. Injectable (tests, graine fixe).
var rng := RandomNumberGenerator.new()

var _cues: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0


func _ready() -> void:
	load_cues(DEFAULT_DIR)
	for i: int in VOICES:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		_voices.append(voice)


func load_cues(dir_path: String) -> void:
	_cues.clear()
	for res: Resource in ContentLoader.load_all(dir_path):
		var cue := res as SoundCue
		if cue == null or cue.stream == null:
			push_warning("Son ignore dans %s : %s" % [dir_path, res.resource_path])
			continue
		_cues[cue.id] = cue


func has_cue(id: StringName) -> bool:
	return _cues.has(id)


## step : numero de la note dans la gamme du son (0 = note de base). Rend la voix utilisee, null si l'ID est inconnu.
func play(id: StringName, step: int = 0) -> AudioStreamPlayer:
	var cue: SoundCue = _cues.get(id)
	if cue == null:
		push_warning("Son inconnu : %s" % id)
		return null
	var voice := _free_voice()
	voice.stream = cue.stream
	voice.bus = cue.bus
	voice.volume_db = cue.volume_db
	voice.pitch_scale = cue.pitch_for(step) * (1.0 + rng.randf_range(-cue.pitch_variance, cue.pitch_variance))
	voice.play()
	return voice


func _free_voice() -> AudioStreamPlayer:
	for voice: AudioStreamPlayer in _voices:
		if not voice.playing:
			return voice
	var stolen := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	return stolen


## Volumes 0 a 1 vers les bus : 0 coupe le bus (linear_to_db(0) vaudrait -inf).
func apply_volumes(settings: GameSettings) -> void:
	_set_bus(MASTER_BUS, settings.master_volume)
	_set_bus(MUSIC_BUS, settings.music_volume)
	_set_bus(EFFECTS_BUS, settings.effects_volume)


func _set_bus(bus_name: StringName, volume: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		push_warning("Bus audio absent : %s" % bus_name)
		return
	AudioServer.set_bus_mute(index, volume <= 0.0)
	if volume > 0.0:
		AudioServer.set_bus_volume_db(index, linear_to_db(volume))
