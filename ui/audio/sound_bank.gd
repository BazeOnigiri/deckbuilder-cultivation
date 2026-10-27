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

## Volume de depart et d'arrivee d'une nappe en fondu : inaudible sans etre -inf.
const SILENT_DB := -60.0

var _cues: Dictionary = {}
## Deux lecteurs de musique : celui qui monte et celui qui s'eteint pendant un fondu croise.
var _music: Array[AudioStreamPlayer] = []
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
	for i: int in 2:
		var player := AudioStreamPlayer.new()
		player.bus = MUSIC_BUS
		add_child(player)
		_music.append(player)


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


## Fondu croise vers la nappe id (vide : silence). La meme nappe deja lancee continue sans reprendre au debut.
func play_music(id: StringName, fade: float) -> void:
	if id == _music_id:
		return
	_music_id = id
	if _music_fade != null:
		_music_fade.kill()
	var outgoing := _music[0]
	var incoming := _music[1]
	_music.reverse()
	var cue: SoundCue = _cues.get(id)
	if cue == null and not id.is_empty():
		push_warning("Nappe inconnue : %s" % id)
	if cue != null:
		incoming.stream = cue.stream
		incoming.bus = cue.bus
		incoming.volume_db = SILENT_DB if fade > 0.0 else cue.volume_db
		incoming.play()
	if fade <= 0.0:
		outgoing.stop()
		return
	_music_fade = create_tween().set_parallel()
	if cue != null:
		_music_fade.tween_property(incoming, "volume_db", cue.volume_db, fade)
	_music_fade.tween_property(outgoing, "volume_db", SILENT_DB, fade)
	_music_fade.chain().tween_callback(outgoing.stop)


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
