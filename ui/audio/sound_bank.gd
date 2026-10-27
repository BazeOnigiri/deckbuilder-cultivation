class_name SoundBank
extends Node
## Autoload « Sons » : joue les sons du jeu par ID (fiches SoundCue de content/sons/) et regle les volumes des bus.
## Le jeu ne connait que les ID : changer un son = regenerer sa fiche, sans toucher au code.

## Emis a chaque son demande et trouve (tests, futur journal de debug).
signal played(id: StringName, step: int)

const DEFAULT_DIR := "res://content/sons"
## Sons des boutons, branches automatiquement sur tout bouton qui entre dans l'arbre.
const CLICK := &"ui_clic"
const HOVER := &"ui_survol"
## Sons simultanes au plus : au-dela, la voix la plus ancienne est reprise.
const VOICES := 12
## Bus reglables, dans l'ordre des volumes de GameSettings.
const MASTER_BUS := &"Master"
const MUSIC_BUS := &"Musique"
const EFFECTS_BUS := &"Effets"

## Variation de hauteur des sons. Injectable (tests, graine fixe).
var rng := RandomNumberGenerator.new()

## Volume d'une variante de musique qu'on n'entend pas : inaudible sans etre -inf.
const SILENT_DB := -60.0

var _cues: Dictionary = {}
## Toutes les variantes de la musique (fiches du bus Musique, meme longueur) jouent ensemble, synchronisees :
## changer d'ambiance ne fait que monter l'une et baisser les autres, la musique ne reprend jamais au debut.
var _music := AudioStreamPlayer.new()
var _music_ids: Array[StringName] = []
var _music_id: StringName = &""
var _music_fade: Tween
var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0


func _ready() -> void:
	load_cues(DEFAULT_DIR)
	get_tree().node_added.connect(_on_node_added)
	for i: int in VOICES:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		_voices.append(voice)
	_music.bus = MUSIC_BUS
	add_child(_music)
	_build_music()


func _build_music() -> void:
	var sync := AudioStreamSynchronized.new()
	_music_ids.clear()
	for id: StringName in _cues:
		if (_cues[id] as SoundCue).bus == MUSIC_BUS:
			_music_ids.append(id)
	_music_ids.sort()
	sync.stream_count = _music_ids.size()
	for i: int in _music_ids.size():
		sync.set_sync_stream(i, (_cues[_music_ids[i]] as SoundCue).stream)
		sync.set_sync_stream_volume(i, SILENT_DB)
	_music.stream = sync


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
	played.emit(id, step)
	return voice


## Fondu vers la variante id (vide : silence), en gardant la position dans la musique.
func play_music(id: StringName, fade: float) -> void:
	if id == _music_id:
		return
	if not id.is_empty() and not _music_ids.has(id):
		push_warning("Musique inconnue : %s" % id)
		return
	_music_id = id
	if _music_fade != null:
		_music_fade.kill()
	if not id.is_empty() and not _music.playing:
		_music.play()
	var sync := _music.stream as AudioStreamSynchronized
	var from: Array[float] = []
	var to: Array[float] = []
	for i: int in _music_ids.size():
		from.append(db_to_linear(sync.get_sync_stream_volume(i)))
		to.append(db_to_linear((_cues[_music_ids[i]] as SoundCue).volume_db) if _music_ids[i] == id else 0.0)
	# Fondu a puissance constante (on interpole l'energie, pas les dB) : pas de creux au milieu du fondu.
	var blend := func(t: float) -> void:
		for i: int in _music_ids.size():
			var gain := sqrt(lerpf(from[i] * from[i], to[i] * to[i], t))
			sync.set_sync_stream_volume(i, maxf(linear_to_db(gain), SILENT_DB) if gain > 0.0 else SILENT_DB)
	if fade > 0.0:
		_music_fade = create_tween()
		_music_fade.tween_method(blend, 0.0, 1.0, fade)
	else:
		blend.call(1.0)
	if id.is_empty():
		if fade > 0.0:
			_music_fade.tween_callback(_music.stop)
		else:
			_music.stop()


## Volume actuel d'une variante de musique, SILENT_DB si muette ou inconnue (tests).
func music_volume_db(id: StringName) -> float:
	var index := _music_ids.find(id)
	return (_music.stream as AudioStreamSynchronized).get_sync_stream_volume(index) if index >= 0 else SILENT_DB


func is_music_playing() -> bool:
	return _music.playing


## Nappe en cours, vide si aucune.
func music_id() -> StringName:
	return _music_id


## Clic et survol de chaque bouton, sans que les ecrans aient a s'en occuper. Les cartes sont des boutons aussi.
func _on_node_added(node: Node) -> void:
	var button := node as BaseButton
	# Un bouton qui change de parent rentre dans l'arbre une seconde fois : ne pas brancher deux fois.
	if button == null or button.pressed.is_connected(_on_button_pressed):
		return
	button.pressed.connect(_on_button_pressed)
	button.mouse_entered.connect(_on_button_hovered.bind(button))


func _on_button_pressed() -> void:
	play(CLICK)


func _on_button_hovered(button: BaseButton) -> void:
	if not button.disabled:
		play(HOVER)


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
