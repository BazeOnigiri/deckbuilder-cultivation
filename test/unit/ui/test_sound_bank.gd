extends GutTest
## Lecteur de sons : sons par ID, gamme de note_carte, voix reprises au-dela du maximum, volumes vers les bus.

var _bank: SoundBank


func before_each() -> void:
	_bank = add_child_autofree(SoundBank.new())
	_bank.rng.seed = 7


func after_each() -> void:
	# Les bus sont globaux : on remet les volumes par defaut pour les autres tests.
	Sons.apply_volumes(GameSettings.new())


func test_son_connu_joue_sur_son_bus() -> void:
	var voice := _bank.play(&"ui_clic")
	assert_not_null(voice)
	assert_eq(voice.bus, &"Effets")
	assert_true(voice.stream is AudioStreamWAV)


func test_son_inconnu_ne_joue_rien() -> void:
	assert_null(_bank.play(&"son_qui_n_existe_pas"))


func test_note_de_carte_monte_dans_la_gamme() -> void:
	var cue: SoundCue = load("res://content/sons/note_carte.tres")
	assert_eq(cue.pitch_for(0), 1.0)
	assert_almost_eq(cue.pitch_for(3), pow(2.0, 7 / 12.0), 0.0001, "4e note de la gamme pentatonique : quinte")
	assert_almost_eq(cue.pitch_for(5), 2.0, 0.0001, "apres la gamme : l'octave")
	assert_almost_eq(_bank.play(&"note_carte", 5).pitch_scale, 2.0, 0.0001, "pas de variation au hasard sur une note")


func test_voix_reprises_au_dela_du_maximum() -> void:
	var voices := {}
	for i: int in SoundBank.VOICES + 3:
		voices[_bank.play(&"victoire")] = true
	assert_eq(voices.size(), SoundBank.VOICES)


func test_volume_nul_coupe_le_bus() -> void:
	var settings := GameSettings.new()
	settings.music_volume = 0.0
	settings.effects_volume = 0.5
	_bank.apply_volumes(settings)
	assert_true(AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Musique")))
	var effects := AudioServer.get_bus_index(&"Effets")
	assert_false(AudioServer.is_bus_mute(effects))
	assert_almost_eq(AudioServer.get_bus_volume_db(effects), linear_to_db(0.5), 0.01)


func _music_players() -> Array:
	return _bank.get_children().filter(func(node: Node) -> bool:
		return node is AudioStreamPlayer and node.bus == &"Musique" and node.playing)


func test_fondu_croise_entre_deux_nappes() -> void:
	_bank.play_music(&"nappe_nuit", 0.0)
	assert_eq(_music_players().size(), 1)
	var first: AudioStreamPlayer = _music_players()[0]
	_bank.play_music(&"nappe_nuit", 0.0)
	assert_eq(_music_players(), [first], "meme nappe : elle continue")
	_bank.play_music(&"nappe_boutique", 0.1)
	assert_eq(_music_players().size(), 2, "les deux nappes pendant le fondu")
	await wait_seconds(0.2)
	assert_eq(_music_players().size(), 1, "l'ancienne s'est tue")
	assert_ne(_music_players()[0], first)
	_bank.play_music(&"", 0.0)
	assert_eq(_music_players().size(), 0, "silence")

